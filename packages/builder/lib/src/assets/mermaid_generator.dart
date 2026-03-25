import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'asset_generator.dart';

typedef _MermaidRenderConfig = ({
  String theme,
  Map<String, Object?> themeVariables,
  String themeCSS,
  String look,
  String securityLevel,
  int handDrawnSeed,
  String extraCSS,
  int width,
  int height,
  num deviceScaleFactor,
  Duration timeout,
  Map<String, Object?> diagramConfigs,
});

/// Asset generator for Mermaid diagrams.
///
/// Converts Mermaid diagram syntax into PNG images using a headless browser.
/// This generator focuses purely on asset generation and does not manipulate slide content.
class MermaidGenerator implements AssetGenerator {
  static final _logger = Logger('MermaidGenerator');

  Browser? _browser;
  Future<Browser>? _browserInitFuture;
  bool _disposed = false;
  final Map<String, Object?> _launchOptions;

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
      import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs';

      // Safe, decoded inputs from Dart
      const graph          = atob('__GRAPH_B64__');
      const theme          = __THEME_JSON__;          // usually 'base'
      const look           = __LOOK_JSON__;           // 'classic' | 'handDrawn'
      const securityLevel  = __SECURITY_LEVEL_JSON__; // 'strict' (default), 'loose', etc.
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
      try {
        await mermaid.run({ querySelector: 'pre.mermaid' });
        window.mermaidReady = !!document.querySelector('pre.mermaid svg');
      } catch (e) {
        window.mermaidError = e?.message || String(e);
      }
    </script>
  </body>
</html>
''';

  @override
  final Map<String, Object?> configuration;

  /// Creates a Mermaid generator with hardcoded dark theme as default.
  ///
  /// The dark theme is optimized for dark slide backgrounds. For certain
  /// diagram types (timeline in dark mode), the generator automatically falls
  /// back to Mermaid's default theme to ensure structural elements (axis, grid
  /// lines) remain visible. See _shouldUseFallbackTheme() for fallback logic.
  MermaidGenerator({
    Map<String, Object?>? launchOptions,
    Map<String, Object?>? configuration,
  }) : _launchOptions = launchOptions ?? {},
       configuration = Map.unmodifiable(
         _mergeConfiguration(
           _defaultConfiguration,
           configuration ?? const <String, Object?>{},
         ),
       );

  /// Default CSS theme styling - colors come from theme variables.
  static const _defaultThemeCSS = '''
  text {
    font-family: Inter, ui-sans-serif, system-ui, sans-serif !important;
  }
''';
  static const _defaultViewportWidth = 1280;
  static const _defaultViewportHeight = 780;
  static const _defaultDeviceScaleFactor = 2;
  static const _defaultTimeout = 10;
  static const _diagramConfigKeys = [
    'flowchart',
    'sequence',
    'class',
    'state',
    'gantt',
    'pie',
    'timeline',
    'journey',
    'quadrant',
    'sankey',
    'radar',
    'kanban',
    'mindmap',
    'architecture',
    'block',
    'packet',
    'treemap',
    'c4',
    'xyChart',
    'gitGraph',
    'er',
  ];

  /// Hardcoded dark theme variables (pre-computed for optimal dark slide rendering)
  /// Based on: background=#0b0f14, primary=#0ea5e9, text=#e2e8f0, darkMode=true
  static const _darkThemeVariables = <String, dynamic>{
    // Core global variables
    'darkMode': true,
    'background': '#0b0f14',
    'fontFamily': 'Inter, ui-sans-serif, system-ui, sans-serif',
    'fontSize': '18px',
    'primaryColor': '#0ea5e9',
    'primaryTextColor': '#000000',
    'primaryBorderColor': '#0b84ba',
    'secondaryColor': '#2fb5f6',
    'secondaryTextColor': '#000000',
    'secondaryBorderColor': '#279bd1',
    'tertiaryColor': '#525c66',
    'tertiaryTextColor': '#e2e8f0',
    'tertiaryBorderColor': '#5f6b77',
    'noteBkgColor': '#b3e0fa',
    'noteTextColor': '#1a1a1a',
    'noteBorderColor': '#0c93ce',
    'errorBkgColor': '#525c66',
    'errorTextColor': '#e2e8f0',
    'mainBkg': '#0d1218',
    'lineColor': '#919ba5',
    'gridColor': '#919ba5',
    'border1': '#919ba5',
    'border2': '#919ba5',
    'textColor': '#f5f5f5',
    'titleColor': '#f5f5f5',
    'nodeTextColor': '#e2e8f0',
    'edgeLabelColor': '#f5f5f5',
    'nodeBorder': '#0b84ba',
    'clusterBkg': '#0d1218',
    'clusterBorder': '#1e2832',
    'defaultLinkColor': '#919ba5',
    'edgeLabelBackground': 'transparent',
    'actorBkg': '#0d1218',
    'actorBorder': '#212b36',
    'actorTextColor': '#e2e8f0',
    'actorLineColor': '#212b36',
    'signalColor': '#f5f5f5',
    'signalTextColor': '#ffffff',
    'labelBoxBkgColor': '#0d1218',
    'labelBoxBorderColor': '#1e2832',
    'labelTextColor': '#e2e8f0',
    'loopTextColor': '#f5f5f5',
    'activationBkgColor': '#0ea5e9',
    'activationBorderColor': '#0b84ba',
    'sequenceNumberColor': '#f5f5f5',
    'labelColor': '#e2e8f0',
    'altBackground': '#151c23',
    'classText': '#f5f5f5',
    'pieTitleTextSize': '24px',
    'pieTitleTextColor': '#f5f5f5',
    'pieLegendTextSize': '16px',
    'pieLegendTextColor': '#f5f5f5',
    'pieSectionTextSize': '18px',
    'pieSectionTextColor': '#000000',
    'pieStrokeColor': '#0b0f14',
    'pieStrokeWidth': '2px',
    'pieOuterStrokeColor': '#0b0f14',
    'pieOuterStrokeWidth': '2px',
    'pieOpacity': '0.7',
    'pie1': '#0ea5e9',
    'pie2': '#20b0ed',
    'pie3': '#32bbf1',
    'pie4': '#44c6f5',
    'pie5': '#56d1f9',
    'pie6': '#68dcfd',
    'pie7': '#4ec2f2',
    'pie8': '#65cdf4',
    'pie9': '#b5d5df',
    'pie10': '#cce2e8',
    'pie11': '#8fd4e6',
    'pie12': '#818f99',
    'git0': '#0ea5e9',
    'gitInv0': '#000000',
    'gitBranchLabel0': '#f5f5f5',
    'git1': '#20b0ed',
    'gitInv1': '#000000',
    'gitBranchLabel1': '#f5f5f5',
    'git2': '#32bbf1',
    'gitInv2': '#000000',
    'gitBranchLabel2': '#f5f5f5',
    'git3': '#44c6f5',
    'gitInv3': '#000000',
    'gitBranchLabel3': '#f5f5f5',
    'git4': '#56d1f9',
    'gitInv4': '#000000',
    'gitBranchLabel4': '#f5f5f5',
    'git5': '#68dcfd',
    'gitInv5': '#000000',
    'gitBranchLabel5': '#f5f5f5',
    'git6': '#4ec2f2',
    'gitInv6': '#000000',
    'gitBranchLabel6': '#f5f5f5',
    'git7': '#65cdf4',
    'gitInv7': '#000000',
    'gitBranchLabel7': '#f5f5f5',
    'commitLabelColor': '#f5f5f5',
    'commitLabelBackground': '#0d1218',
    'commitLabelFontSize': '14px',
    'tagLabelColor': '#f5f5f5',
    'tagLabelBackground': '#0ea5e9',
    'tagLabelBorder': '#0b84ba',
    'tagLabelFontSize': '14px',
  };

  /// Default dark theme configuration with hardcoded theme variables
  static final _defaultConfiguration = <String, dynamic>{
    // Global look & theme
    'theme': 'base', // 'base' is the only theme you can customize
    'look': 'classic', // or 'handDrawn'
    'securityLevel': 'strict', // 'loose' only if you need clickable links/HTML
    'handDrawnSeed': 17,

    // Hardcoded dark theme variables (optimized for dark slide backgrounds)
    'themeVariables': _darkThemeVariables,

    // CSS only for non-variable gaps (tick text, relationship labels, etc.)
    'themeCSS': _defaultThemeCSS,

    // Flowchart-specific config (v11)
    'flowchart': {'htmlLabels': true},

    // Sequence diagram knobs
    'sequence': {'mirrorActors': false},

    // Class diagram (v11 supports htmlLabels here too)
    'class': {'htmlLabels': true},

    // Rendering mechanics for the browser page
    'viewportWidth': _defaultViewportWidth,
    'viewportHeight': _defaultViewportHeight,
    'deviceScaleFactor': _defaultDeviceScaleFactor,
    'timeout': _defaultTimeout,
    'extraCSS': '', // Optional extra CSS
  };

  static Map<String, Object?> _mergeConfiguration(
    Map<String, Object?> defaults,
    Map<String, Object?> overrides,
  ) {
    final merged = Map<String, Object?>.from(defaults);

    for (final entry in overrides.entries) {
      final current = merged[entry.key];
      final override = entry.value;

      if (current is Map && override is Map) {
        merged[entry.key] = _mergeConfiguration(
          Map<String, Object?>.from(current),
          Map<String, Object?>.from(override),
        );
      } else {
        merged[entry.key] = override;
      }
    }

    return merged;
  }

  @override
  String get type => 'mermaid';

  @override
  bool canProcess(String contentType) => contentType == 'mermaid';

  @override
  GeneratedAsset createAssetReference(String content) {
    return GeneratedAsset.mermaid(content);
  }

  /// Returns an existing browser instance or creates a new one.
  ///
  /// Uses a shared future to prevent concurrent browser launches - if multiple
  /// calls arrive while the browser is being initialized, they all await the
  /// same initialization future.
  ///
  /// Handles browser disconnection gracefully by detecting stale instances
  /// and relaunching when needed.
  Future<Browser> _getBrowser() async {
    // Prevent usage after disposal
    if (_disposed) {
      throw StateError(
        'MermaidGenerator has been disposed. '
        'Cannot generate diagrams after dispose() has been called.',
      );
    }

    // Return existing browser if still connected
    if (_browser != null && _browser!.isConnected) {
      return _browser!;
    }

    // Browser disconnected externally - clean up stale references
    if (_browser != null && !_browser!.isConnected) {
      _logger.warning(
        'Browser disconnected unexpectedly. Relaunching for next diagram.',
      );
      _browser = null;
      _browserInitFuture = null;
    }

    // If initialization is in progress, await it
    if (_browserInitFuture != null) {
      return _browserInitFuture!;
    }

    // Start initialization and store the future for concurrent callers
    _browserInitFuture = _launchBrowser();
    try {
      _browser = await _browserInitFuture!;
      return _browser!;
    } catch (e) {
      // Clear the future on failure so retry is possible
      _browserInitFuture = null;
      rethrow;
    } finally {
      // Clear the init future after completion - the result is now in _browser
      // This prevents stale futures from being returned if _browser is later
      // cleared due to disconnection
      _browserInitFuture = null;
    }
  }

  /// Launches a new headless browser for Mermaid rendering.
  Future<Browser> _launchBrowser() async {
    try {
      _logger.info('Launching headless browser for Mermaid rendering');
      final browser = await puppeteer.launch(
        headless: _launchOptions['headless'] as bool? ?? true,
        args: _launchOptions['args'] as List<String>?,
        executablePath: _launchOptions['executablePath'] as String?,
      );
      _logger.info('Browser launched successfully');
      return browser;
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

  /// Executes an action with a new browser page, closing it afterwards.
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
      final timeoutSeconds =
          configuration['timeout'] as int? ?? _defaultTimeout;
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

  /// Returns whether the diagram type should use fallback theme instead of custom theme.
  ///
  /// Some diagram types (timeline, gantt) have rendering issues with custom
  /// dark themes where structural elements (axis, grid lines) become invisible.
  /// For these diagrams, this falls back to Mermaid's default theme which has
  /// better visibility for structural elements.
  ///
  /// Only applies to dark mode - light mode custom theme works fine for timeline.
  bool _shouldUseFallbackTheme(String graphDefinition) {
    final trimmed = graphDefinition.trim().toLowerCase();

    // Check if we're in dark mode
    final themeVars = configuration['themeVariables'] as Map<String, Object?>?;
    final isDarkMode = themeVars?['darkMode'] as bool? ?? true;

    // Timeline diagrams have axis visibility issues with custom DARK themes only
    if (trimmed.startsWith('timeline') && isDarkMode) {
      _logger.warning(
        'Timeline diagram detected in dark mode. Using Mermaid default theme '
        'instead of custom dark theme due to visibility issues with axis and grid lines. '
        'Your custom theme will be ignored for this diagram. '
        'To use your custom theme, set darkMode: false in your configuration.',
      );
      return true;
    }

    return false;
  }

  /// Generates a PNG image from the given Mermaid diagram definition.
  Future<List<int>> _generateMermaidImage(String graphDefinition) {
    _logger.fine('Starting Mermaid image generation');
    final config = _resolveRenderConfig(graphDefinition);

    _logger.fine(
      'Using theme: ${config.theme}, viewport: ${config.width}x${config.height}, '
      'timeout: ${config.timeout.inSeconds}s',
    );

    final htmlContent = _buildHtmlContent(config, graphDefinition);

    return _withPage((page) async {
      _logger.fine(
        'Setting viewport to ${config.width}x${config.height} with scale factor '
        '${config.deviceScaleFactor}',
      );

      // Set viewport before loading content
      await page.setViewport(
        DeviceViewport(
          width: config.width,
          height: config.height,
          deviceScaleFactor: config.deviceScaleFactor,
        ),
      );

      _logger.fine('Loading HTML content into page');
      await page.setContent(htmlContent, timeout: config.timeout);

      _logger.fine(
        'Waiting for Mermaid to render (timeout: ${config.timeout.inSeconds}s)',
      );

      // Wait for mermaid to finish rendering
      try {
        await page.waitForFunction(
          'window.mermaidReady === true || window.mermaidError != null',
          timeout: config.timeout,
        );

        final mermaidError = await page.evaluate<String?>(
          'window.mermaidError',
        );
        if (mermaidError != null) {
          throw Exception('Mermaid syntax error: $mermaidError');
        }
      } on TimeoutException {
        _logger.severe(
          'Mermaid rendering timed out after ${config.timeout.inSeconds}s',
        );
        throw Exception(
          'Mermaid diagram failed to render within ${config.timeout.inSeconds} seconds. '
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

      _logger.info(
        'Successfully generated Mermaid image (${screenshot.length} bytes)',
      );
      return screenshot;
    });
  }

  _MermaidRenderConfig _resolveRenderConfig(String graphDefinition) {
    // Detect diagram type and use fallback theme for problematic diagrams
    final useFallbackTheme = _shouldUseFallbackTheme(graphDefinition);

    final theme = useFallbackTheme
        ? 'default' // Use Mermaid's default theme for timeline/gantt
        : (configuration['theme'] as String? ?? 'base');

    final themeVariables = useFallbackTheme
        ? <String, Object?>{}
        : Map<String, Object?>.from(
            configuration['themeVariables'] as Map? ??
                const <String, Object?>{},
          );

    final themeCSS = useFallbackTheme
        ? '' // No custom CSS for fallback
        : (configuration['themeCSS'] as String? ?? '');

    final diagramConfigs = <String, Object?>{};
    for (final key in _diagramConfigKeys) {
      if (configuration.containsKey(key)) {
        diagramConfigs[key] = configuration[key];
      }
    }

    return (
      theme: theme,
      themeVariables: themeVariables,
      themeCSS: themeCSS,
      look: configuration['look'] as String? ?? 'classic',
      securityLevel: configuration['securityLevel'] as String? ?? 'strict',
      handDrawnSeed: configuration['handDrawnSeed'] as int? ?? 0,
      extraCSS: configuration['extraCSS'] as String? ?? '',
      width: configuration['viewportWidth'] as int? ?? _defaultViewportWidth,
      height: configuration['viewportHeight'] as int? ?? _defaultViewportHeight,
      deviceScaleFactor:
          configuration['deviceScaleFactor'] as num? ??
          _defaultDeviceScaleFactor,
      timeout: Duration(
        seconds: configuration['timeout'] as int? ?? _defaultTimeout,
      ),
      diagramConfigs: diagramConfigs,
    );
  }

  String _buildHtmlContent(
    _MermaidRenderConfig config,
    String graphDefinition,
  ) {
    // Base64 encode for safe injection
    final graphB64 = base64Encode(utf8.encode(graphDefinition));
    final themeCSSB64 = base64Encode(utf8.encode(config.themeCSS));
    final extraCSSB64 = base64Encode(utf8.encode(config.extraCSS));

    return _mermaidHtmlTemplate
        .replaceAll('__GRAPH_B64__', graphB64)
        .replaceAll('__THEME_JSON__', jsonEncode(config.theme))
        .replaceAll('__LOOK_JSON__', jsonEncode(config.look))
        .replaceAll('__SECURITY_LEVEL_JSON__', jsonEncode(config.securityLevel))
        .replaceAll('__THEME_VARIABLES__', jsonEncode(config.themeVariables))
        .replaceAll('__THEME_CSS_B64__', themeCSSB64)
        .replaceAll('__HAND_DRAWN_SEED__', config.handDrawnSeed.toString())
        .replaceAll('__EXTRA_CSS_B64__', extraCSSB64)
        .replaceAll('__DIAGRAM_CONFIGS__', jsonEncode(config.diagramConfigs));
  }

  /// Exposes the resolved HTML payload for unit tests.
  String buildHtmlContentForTesting(String graphDefinition) {
    return _buildHtmlContent(
      _resolveRenderConfig(graphDefinition),
      graphDefinition,
    );
  }

  /// The timeout for waiting on browser initialization during dispose.
  static const _disposeTimeout = Duration(seconds: 30);

  @override
  Future<void> dispose() async {
    // Mark as disposed first to prevent new browser launches
    _disposed = true;

    // Wait for any in-flight initialization to complete before disposing,
    // but with a timeout to prevent indefinite hangs if browser launch is stuck
    if (_browserInitFuture != null) {
      try {
        await _browserInitFuture!.timeout(_disposeTimeout);
      } on TimeoutException {
        _logger.warning(
          'Browser initialization timed out during dispose after '
          '${_disposeTimeout.inSeconds}s. Proceeding with cleanup.',
        );
      } catch (_) {
        // Ignore other initialization errors during dispose
      }
    }
    _browserInitFuture = null;

    if (_browser != null) {
      try {
        await _browser!.close();
      } catch (e) {
        _logger.warning('Error closing browser during dispose: $e');
      }
      _browser = null;
    }
  }
}
