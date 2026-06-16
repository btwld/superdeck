import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:puppeteer/puppeteer.dart';

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

/// Renders Mermaid diagrams to PNG using a headless browser.
///
/// The browser is launched lazily on the first render and reused for later
/// renders. Call [dispose] when the generator is no longer needed.
class MermaidGenerator {
  static final _logger = Logger('MermaidGenerator');

  Browser? _browser;
  Future<Browser>? _browserInitFuture;
  bool _disposed = false;
  final Map<String, Object?> _launchOptions;

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

  /// The resolved Mermaid rendering configuration.
  ///
  /// Values passed to the constructor are deeply merged with SuperDeck's
  /// defaults and then exposed as an unmodifiable map.
  final Map<String, Object?> configuration;

  /// Creates a Mermaid generator backed by a headless browser.
  ///
  /// [launchOptions] are forwarded to `puppeteer.launch`, including options
  /// such as `headless`, `args`, and `executablePath`.
  ///
  /// [configuration] customizes Mermaid rendering. Supported keys include
  /// `theme`, `look`, `securityLevel`, `themeVariables`, `themeCSS`,
  /// `extraCSS`, `viewportWidth`, `viewportHeight`, `deviceScaleFactor`,
  /// `timeout`, and diagram-specific configuration keys such as `flowchart` or
  /// `sequence`.
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

  static const _defaultThemeCSS = '''
  html,
  body,
  pre.mermaid {
    margin: 0;
    padding: 0;
    background: transparent !important;
  }

  pre.mermaid > svg {
    background: transparent !important;
  }

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

  static const _defaultThemeVariables = <String, dynamic>{
    'darkMode': true,
    'background': 'transparent',
    'fontFamily': 'Inter, ui-sans-serif, system-ui, sans-serif',
    'fontSize': '18px',
    'edgeLabelBackground': 'transparent',
  };

  static final _defaultConfiguration = <String, dynamic>{
    'theme': 'default',
    'look': 'classic',
    'securityLevel': 'strict',
    'handDrawnSeed': 17,
    'themeVariables': _defaultThemeVariables,
    'themeCSS': _defaultThemeCSS,
    'flowchart': {'htmlLabels': true},
    'sequence': {'mirrorActors': false},
    'class': {'htmlLabels': true},
    'viewportWidth': _defaultViewportWidth,
    'viewportHeight': _defaultViewportHeight,
    'deviceScaleFactor': _defaultDeviceScaleFactor,
    'timeout': _defaultTimeout,
    'extraCSS': '',
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

  Future<Browser> _getBrowser() async {
    if (_disposed) {
      throw StateError(
        'MermaidGenerator has been disposed. '
        'Cannot generate diagrams after dispose() has been called.',
      );
    }

    if (_browser != null && _browser!.isConnected) {
      return _browser!;
    }

    if (_browser != null && !_browser!.isConnected) {
      _logger.warning(
        'Browser disconnected unexpectedly. Relaunching for next diagram.',
      );
      _browser = null;
      _browserInitFuture = null;
    }

    if (_browserInitFuture != null) {
      return _browserInitFuture!;
    }

    _browserInitFuture = _launchBrowser();
    try {
      _browser = await _browserInitFuture!;
      return _browser!;
    } catch (e) {
      _browserInitFuture = null;
      rethrow;
    } finally {
      _browserInitFuture = null;
    }
  }

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

  Future<T> _withPage<T>(Future<T> Function(Page page) action) async {
    final browser = await _getBrowser();
    final page = await browser.newPage();
    try {
      return await action(page);
    } finally {
      await page.close();
    }
  }

  /// Renders Mermaid [syntax] and returns PNG bytes.
  ///
  /// Throws an [Exception] when the browser cannot launch, Mermaid rejects the
  /// syntax, rendering times out, or no SVG output is produced.
  Future<Uint8List> render(String syntax) async {
    try {
      return await _generateMermaidImage(syntax);
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

  bool _shouldUseFallbackTheme(String graphDefinition) {
    final trimmed = graphDefinition.trim().toLowerCase();

    final themeVars = configuration['themeVariables'] as Map<String, Object?>?;
    final isDarkMode = themeVars?['darkMode'] as bool? ?? true;

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

  Future<Uint8List> _generateMermaidImage(String graphDefinition) {
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
      return Uint8List.fromList(screenshot);
    });
  }

  _MermaidRenderConfig _resolveRenderConfig(String graphDefinition) {
    final useFallbackTheme = _shouldUseFallbackTheme(graphDefinition);

    final theme = useFallbackTheme
        ? 'default'
        : (configuration['theme'] as String? ?? 'base');

    final themeVariables = useFallbackTheme
        ? <String, Object?>{}
        : Map<String, Object?>.from(
            configuration['themeVariables'] as Map? ??
                const <String, Object?>{},
          );

    final themeCSS = useFallbackTheme
        ? ''
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
  @visibleForTesting
  String buildHtmlContentForTesting(String graphDefinition) {
    return _buildHtmlContent(
      _resolveRenderConfig(graphDefinition),
      graphDefinition,
    );
  }

  static const _disposeTimeout = Duration(seconds: 30);

  /// Closes the browser owned by this generator.
  ///
  /// After disposal, later calls to [render] throw a [StateError].
  Future<void> dispose() async {
    _disposed = true;

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
