import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'asset_generator.dart';
import 'mermaid_theme.dart';

/// Asset generator for Mermaid diagrams.
///
/// Converts Mermaid diagram syntax into PNG images using a headless browser.
/// This generator focuses purely on asset generation and does not manipulate slide content.
class MermaidGenerator implements AssetGenerator {
  static final _logger = Logger('MermaidGenerator');

  Browser? _browser;
  final Map<String, dynamic> _launchOptions;

  /// HTML template for rendering Mermaid diagrams.
  static final _mermaidHtmlTemplate = '''
<html>
  <head>
    <meta charset="utf-8">
    <!-- Optional extra CSS (e.g., @font-face) is injected below via __EXTRA_CSS_B64__ -->
    <style id="extra-css"></style>
  </head>
  <body>
    <pre class="mermaid"></pre>

    <script type="module">
      import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

      // Safe, decoded inputs from Dart
      const graph          = atob('__GRAPH_B64__');
      const theme          = '__THEME__';          // usually 'base'
      const look           = '__LOOK__';           // 'classic' | 'handDrawn'
      const securityLevel  = '__SECURITY_LEVEL__'; // 'strict' (default), 'loose', etc.
      const themeVariables = __THEME_VARIABLES__;  // JSON from Dart
      const themeCSS       = atob('__THEME_CSS_B64__');
      const handDrawnSeed  = __HAND_DRAWN_SEED__;  // number
      const extraCSS       = atob('__EXTRA_CSS_B64__'); // optional, can be ''
      const diagramConfigs = __DIAGRAM_CONFIGS__;  // All diagram-specific configs

      // Inject extra CSS before initialize (fonts/styles)
      if (extraCSS) document.getElementById('extra-css').textContent = extraCSS;

      mermaid.initialize({
        startOnLoad: false,
        theme,
        themeVariables,
        themeCSS,
        look,
        securityLevel,
        deterministicIds: true,
        handDrawnSeed,
        suppressErrorRendering: true, // keep the DOM clean on syntax errors
        // Spread all diagram-specific configs (flowchart, sequence, class, gantt, etc.)
        ...diagramConfigs
      });

      // Put the graph text into the <pre> safely
      const pre = document.querySelector('pre.mermaid');
      pre.textContent = graph;

      // Wait for fonts to load so text measurement is correct (if supported)
      if (document.fonts?.ready) { await document.fonts.ready; }

      // Render and confirm we have an SVG
      await mermaid.run({ querySelector: 'pre.mermaid' });
      window.mermaidReady = !!document.querySelector('pre.mermaid svg');
    </script>
  </body>
</html>
''';

  @override
  final Map<String, dynamic> configuration;

  MermaidGenerator({
    Map<String, dynamic>? launchOptions,
    MermaidTheme? theme,
    Map<String, dynamic>? configuration,
  }) : _launchOptions = launchOptions ?? {},
        configuration = _buildConfiguration(theme, configuration);

  /// Build configuration from theme or use provided/default configuration.
  static Map<String, dynamic> _buildConfiguration(
    MermaidTheme? theme,
    Map<String, dynamic>? configuration,
  ) {
    if (theme != null) {
      return {
        // Global look & theme
        'theme': 'base',
        'look': 'classic',
        'securityLevel': 'strict',
        'handDrawnSeed': 17,

        // Theme
        'themeVariables': theme.toThemeVariables(),
        'themeCSS': _defaultThemeCSS,

        // Diagram-specific configs
        'flowchart': {'htmlLabels': true},
        'sequence': {'mirrorActors': false},
        'class': {'htmlLabels': true},
        'state': {},
        'gantt': {},
        'pie': {},
        'timeline': {},
        'journey': {},

        // Rendering settings
        'viewportWidth': 1280,
        'viewportHeight': 780,
        'deviceScaleFactor': 2,
        'timeout': 10,
        'extraCSS': '',

        // Allow overrides from configuration param
        ...?configuration,
      };
    }

    // Use provided configuration or defaults
    return configuration ?? _defaultConfiguration;
  }

  /// Default CSS theme styling for all diagrams.
  ///
  /// Provides structural styling only - colors are handled by theme variables.
  /// v11.12.0 theme variables now cover all text colors, so we only need
  /// layout/structural CSS here.
  static const _defaultThemeCSS = '''
  .label { font-weight: 600; }
  .edgeLabel rect { rx: 6; ry: 6; }
  .node rect, .node circle, .node ellipse, .node polygon {
    stroke-width: 2px;
  }
  text {
    font-family: Inter, ui-sans-serif, system-ui, sans-serif !important;
  }
''';

  /// Default dark theme configuration (using MermaidTheme.dark preset)
  static final _defaultConfiguration = {
    // Global look & theme
    'theme': 'base',               // 'base' is the only theme you can customize
    'look': 'classic',             // or 'handDrawn'
    'securityLevel': 'strict',     // 'loose' only if you need clickable links/HTML
    'handDrawnSeed': 17,

    // Your theme variables come from MermaidTheme.dark
    'themeVariables': MermaidTheme.dark.toThemeVariables(),

    // CSS only for non-variable gaps (tick text, relationship labels, etc.)
    'themeCSS': _defaultThemeCSS,

    // Flowchart-specific config (v11)
    'flowchart': {
      'htmlLabels': true,
    },

    // Sequence diagram knobs
    'sequence': {
      'mirrorActors': false,
    },

    // Class diagram (v11 supports htmlLabels here too)
    'class': {
      'htmlLabels': true,
    },

    // State diagrams
    'state': {},

    // Gantt
    'gantt': {},

    // Optional: pie/timeline/journey
    'pie': {},
    'timeline': {},
    'journey': {},

    // Rendering mechanics for the browser page
    'viewportWidth': 1280,
    'viewportHeight': 780,
    'deviceScaleFactor': 2,
    'timeout': 10,
    'extraCSS': '', // Optional extra CSS
  };

  @override
  String get type => 'mermaid';

  @override
  bool canProcess(String contentType) => contentType == 'mermaid';

  @override
  GeneratedAsset createAssetReference(String content) {
    return GeneratedAsset.mermaid(content);
  }

  /// Get or create a browser instance
  Future<Browser> _getBrowser() async {
    if (_browser == null) {
      try {
        _logger.info('Launching headless browser for Mermaid rendering');
        _browser = await puppeteer.launch(
          headless: _launchOptions['headless'] ?? true,
          args: _launchOptions['args'] as List<String>?,
          executablePath: _launchOptions['executablePath'] as String?,
        );
        _logger.info('Browser launched successfully');
      } catch (e, stackTrace) {
        _logger.severe(
          'Failed to launch browser for Mermaid rendering. '
          'Ensure Chrome/Chromium is installed and accessible.',
          e,
          stackTrace,
        );
        Error.throwWithStackTrace(
          Exception(
            'Failed to launch browser for Mermaid diagram generation. '
            'Please ensure Chrome or Chromium is installed and accessible. '
            'Error: $e',
          ),
          stackTrace,
        );
      }
    }
    return _browser!;
  }

  /// Execute an action with a new page
  Future<T> _withPage<T>(Future<T> Function(Page page) action) async {
    final browser = await _getBrowser();
    final page = await browser.newPage();
    try {
      return await action(page);
    } finally {
      await page.close();
    }
  }

  @override
  Future<List<int>> generateAsset(String content, String assetPath) async {
    try {
      return await _generateMermaidImage(content);
    } on TimeoutException catch (e, stackTrace) {
      final timeoutSeconds = configuration['timeout'] as int? ?? 10;
      Error.throwWithStackTrace(
        Exception(
          'Mermaid generation timed out after $timeoutSeconds seconds. '
          'Try simplifying your diagram or increasing the timeout.',
        ),
        stackTrace,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        Exception(
          'Failed to generate Mermaid diagram: $e. '
          'Check your Mermaid syntax and ensure a browser is available.',
        ),
        stackTrace,
      );
    }
  }

  /// Generates PNG image from Mermaid diagram definition.
  Future<List<int>> _generateMermaidImage(String graphDefinition) {
    _logger.fine('Starting Mermaid image generation');

    final theme = configuration['theme'] as String? ?? 'base';
    final themeVariables = configuration['themeVariables'] ?? {};
    final themeCSS = configuration['themeCSS'] as String? ?? '';
    final look = configuration['look'] as String? ?? 'classic';
    final securityLevel = configuration['securityLevel'] as String? ?? 'strict';
    final handDrawnSeed = configuration['handDrawnSeed'] as int? ?? 0;
    final extraCSS = configuration['extraCSS'] as String? ?? '';
    final width = configuration['viewportWidth'] as int? ?? 1280;
    final height = configuration['viewportHeight'] as int? ?? 780;
    final deviceScaleFactor = configuration['deviceScaleFactor'] as num? ?? 2;
    final timeout = Duration(seconds: configuration['timeout'] as int? ?? 10);

    // Extract ALL diagram-specific configs for passing to mermaid.initialize
    final diagramConfigs = <String, dynamic>{};
    final diagramConfigKeys = [
      'flowchart', 'sequence', 'class', 'state', 'gantt',
      'pie', 'timeline', 'journey', 'quadrant', 'sankey',
      'radar', 'kanban', 'mindmap', 'architecture', 'block',
      'packet', 'treemap', 'c4', 'xyChart', 'gitGraph', 'er'
    ];

    for (final key in diagramConfigKeys) {
      if (configuration.containsKey(key)) {
        diagramConfigs[key] = configuration[key];
      }
    }

    _logger.fine('Using theme: $theme, viewport: ${width}x$height, timeout: ${timeout.inSeconds}s');

    // Base64 encode for safe injection
    final graphB64 = base64Encode(utf8.encode(graphDefinition));
    final themeCSSB64 = base64Encode(utf8.encode(themeCSS));
    final extraCSSB64 = base64Encode(utf8.encode(extraCSS));

    final htmlContent = _mermaidHtmlTemplate
        .replaceAll('__GRAPH_B64__', graphB64)
        .replaceAll('__THEME__', theme)
        .replaceAll('__LOOK__', look)
        .replaceAll('__SECURITY_LEVEL__', securityLevel)
        .replaceAll('__THEME_VARIABLES__', jsonEncode(themeVariables))
        .replaceAll('__THEME_CSS_B64__', themeCSSB64)
        .replaceAll('__HAND_DRAWN_SEED__', handDrawnSeed.toString())
        .replaceAll('__EXTRA_CSS_B64__', extraCSSB64)
        .replaceAll('__DIAGRAM_CONFIGS__', jsonEncode(diagramConfigs));

    return _withPage((page) async {
      _logger.fine('Setting viewport to ${width}x$height with scale factor $deviceScaleFactor');

      // Set viewport before loading content
      await page.setViewport(DeviceViewport(
        width: width,
        height: height,
        deviceScaleFactor: deviceScaleFactor,
      ));

      _logger.fine('Loading HTML content into page');
      await page.setContent(htmlContent);

      _logger.fine('Waiting for Mermaid to render (timeout: ${timeout.inSeconds}s)');

      // Wait for mermaid to finish rendering
      try {
        await page.waitForFunction('window.mermaidReady === true', timeout: timeout);
      } on TimeoutException {
        _logger.severe('Mermaid rendering timed out after ${timeout.inSeconds}s');
        throw Exception(
          'Mermaid diagram failed to render within ${timeout.inSeconds} seconds. '
          'This may indicate invalid Mermaid syntax or a browser rendering issue. '
          'Check your diagram syntax or increase the timeout.',
        );
      }

      _logger.fine('Selecting SVG element for screenshot');

      // Screenshot the SVG element directly
      final element = await page.$OrNull('pre.mermaid > svg');
      if (element == null) {
        _logger.severe('SVG element not found after successful render');
        throw Exception(
          'Mermaid diagram failed to render: SVG element not found in DOM. '
          'Check your Mermaid syntax.',
        );
      }

      _logger.fine('Taking screenshot of SVG element');
      final screenshot = await element.screenshot(
        format: ScreenshotFormat.png,
        omitBackground: true,
      );

      _logger.info('Successfully generated Mermaid image (${screenshot.length} bytes)');
      return screenshot;
    });
  }

  @override
  Future<void> dispose() async {
    if (_browser != null) {
      await _browser!.close();
      _browser = null;
    }
  }
}
