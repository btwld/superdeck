import 'dart:async';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';
import 'package:superdeck_builder/src/parsers/fenced_code_parser.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../core/task.dart';
import '../core/task_context.dart';
import '../services/browser_service.dart';

class MermaidConverterTask extends Task {
  final BrowserService _browserService;

  /// Extract large HTML templates to constants for better readability.
  static final _mermaidHtmlTemplate = '''
<html>
  <body>
    <pre class="mermaid">__GRAPH_DEFINITION__</pre>
    <script type="module">
      import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
      mermaid.initialize({
        startOnLoad: true,
        theme: '__THEME__',
        themeVariables: __THEME_VARIABLES__,
        flowchart: {
          htmlLabels: true,
        }
      });
      mermaid.run({ querySelector: 'pre.mermaid' });
    </script>
  </body>
</html>
''';

  MermaidConverterTask({
    required BrowserService browserService,
    Map<String, dynamic> configuration = const {
      'theme': 'base',
      'themeVariables': {
        'background': '#000000',
        'primaryColor': '#000000',
        'secondaryColor': '#000000',
        'tertiaryColor': '#000000',
        'primaryTextColor': '#FFFF00',
        'secondaryTextColor': '#FFFF00',
        'tertiaryTextColor': '#FFFF00',
        'defaultFontColor': '#FFFF00',
        'primaryBorderColor': '#FFFF00',
        'secondaryBorderColor': '#FFFF00',
        'tertiaryBorderColor': '#FFFF00',
        'lineColor': '#FFFF00'
      },
      'viewportWidth': 1280,
      'viewportHeight': 780,
      'deviceScaleFactor': 2,
      'timeout': 5
    },
  })  : _browserService = browserService,
        super('mermaid', configuration: configuration, canRunInParallel: false);

  Future<String> _generateMermaidGraph(String graphDefinition) {
    logger.fine('Generating mermaid graph:');
    logger.fine(graphDefinition);

    final theme = configuration['theme'] as String? ?? 'base';
    final themeVariables = configuration['themeVariables'] ?? {};

    final themeVariablesJson = _convertThemeVariablesToJson(themeVariables);

    final htmlContent = _mermaidHtmlTemplate
        .replaceAll('__GRAPH_DEFINITION__', graphDefinition)
        .replaceAll('__THEME__', theme)
        .replaceAll('__THEME_VARIABLES__', themeVariablesJson);

    final timeout = Duration(seconds: configuration['timeout'] as int? ?? 5);

    return _browserService.withPage((page) async {
      await page.setContent(htmlContent);
      await page.waitForSelector(
        'pre.mermaid > svg',
        timeout: timeout,
      );

      final element = await page.$('pre.mermaid > svg');
      return await element.evaluate('el => el.outerHTML');
    });
  }

  String _convertThemeVariablesToJson(Map<String, dynamic> themeVariables) {
    final buffer = StringBuffer();
    buffer.write('{');

    var first = true;
    for (var entry in themeVariables.entries) {
      if (!first) buffer.write(',');
      first = false;

      buffer.write('"${entry.key}": ');
      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is num || entry.value is bool) {
        buffer.write('${entry.value}');
      } else {
        buffer.write('null');
      }
    }

    buffer.write('}');
    return buffer.toString();
  }

  Future<List<int>> _convertSvgToImage(String svgContent) {
    final width = configuration['viewportWidth'] as int? ?? 1280;
    final height = configuration['viewportHeight'] as int? ?? 780;
    final deviceScaleFactor = configuration['deviceScaleFactor'] as num? ?? 2;

    return _browserService.withPage((page) async {
      await page.setViewport(DeviceViewport(
        width: width,
        height: height,
        deviceScaleFactor: deviceScaleFactor,
      ));

      await page.setContent('''
      <html>
        <body>
          <div class="svg-container">$svgContent</div>
        </body>
      </html>
    ''');

      final element = await page.$('.svg-container > svg');

      return await element.screenshot(
        format: ScreenshotFormat.png,
        omitBackground: true,
      );
    });
  }

  Future<List<int>> _generateMermaidGraphImage(String graphDefinition) async {
    try {
      final svgContent = await _generateMermaidGraph(graphDefinition);
      return await _convertSvgToImage(svgContent);
    } catch (e, stackTrace) {
      logger.severe('Failed to generate Mermaid graph image: $e');
      Error.throwWithStackTrace(
        Exception(
          'Mermaid generation timed out or failed. Original error: $e',
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<void> run(TaskContext context) async {
    final stopwatch = Stopwatch()..start();

    final fencedCodeParser = const FencedCodeParser();
    final codeBlocks = fencedCodeParser.parse(context.slide.content);
    final mermaidBlocks = codeBlocks.where((e) => e.language == 'mermaid');

    if (mermaidBlocks.isEmpty) {
      return;
    }

    for (final mermaidBlock in mermaidBlocks) {
      final mermaidAsset = GeneratedAsset.mermaid(mermaidBlock.content);
      final assetPath = context.dataStore.getGeneratedAssetPath(mermaidAsset);
      final assetFile = File(assetPath);

      if (await assetFile.exists()) {
        logger.info(
          'Mermaid asset already exists for slide index: ${context.slideIndex}',
        );
      } else {
        logger.info(
          'Generating mermaid graph image for slide index: ${context.slideIndex}',
        );
        final imageData =
            await _generateMermaidGraphImage(mermaidBlock.content);
        await assetFile.writeAsBytes(imageData);
      }

      final mermaidImageSyntax = '![mermaid_graph](${assetFile.path})';
      final updatedMarkdown = context.slide.content.replaceRange(
        mermaidBlock.startIndex,
        mermaidBlock.endIndex,
        mermaidImageSyntax,
      );

      context.slide.content = updatedMarkdown;
    }

    stopwatch.stop();
    logger.info(
      'Completed MermaidConverterTask for slide index: ${context.slideIndex} in ${stopwatch.elapsedMicroseconds} microseconds',
    );
  }
}
