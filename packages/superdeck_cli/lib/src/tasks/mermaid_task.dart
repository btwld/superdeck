import 'dart:async';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../generator_pipeline.dart';
import '../helpers/logger.dart';

class MermaidConverterTask extends Task {
  Browser? _browser;

  /// Extract large HTML templates to constants for better readability.
  static final _mermaidHtmlTemplate = '''
<html>
  <body>
    <pre class="mermaid">__GRAPH_DEFINITION__</pre>
    <script type="module">
      import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
      mermaid.initialize({
        startOnLoad: true,
        // Using 'base' gives you a clean slate
        theme: 'base',
        themeVariables: {
          // Background settings
          background: '#000000',
          primaryColor: '#000000',
          secondaryColor: '#000000',
          tertiaryColor: '#000000',

          // Text colors
          primaryTextColor: '#FFFF00',
          secondaryTextColor: '#FFFF00',
          tertiaryTextColor: '#FFFF00',
          defaultFontColor: '#FFFF00',

          // Border and line colors
          primaryBorderColor: '#FFFF00',
          secondaryBorderColor: '#FFFF00',
          tertiaryBorderColor: '#FFFF00',
          lineColor: '#FFFF00'
        },
        flowchart: {
          // Enable HTML labels (if needed) so you can style them via CSS as well
          htmlLabels: true,
        }
      });
      mermaid.run({ querySelector: 'pre.mermaid' });
    </script>
  </body>
</html>
''';
  MermaidConverterTask() : super('mermaid');
  Future<Browser> _getBrowser() async {
    _browser ??= await puppeteer.launch();

    return _browser!;
  }

  /// A helper function that automates page creation, content setup, and cleanup.
  Future<T> _withPage<T>(
    Browser browser,
    Future<T> Function(Page page) action,
  ) async {
    final page = await browser.newPage();
    try {
      return await action(page);
    } finally {
      await page.close();
    }
  }

  Future<String> _generateMermaidGraph(
    Browser browser,
    String graphDefinition,
  ) {
    logger.detail('Generating mermaid graph:');
    logger.detail(graphDefinition);

    final htmlContent = _mermaidHtmlTemplate.replaceAll(
      '__GRAPH_DEFINITION__',
      graphDefinition,
    );

    return _withPage(browser, (page) async {
      await page.setContent(htmlContent);
      await page.waitForSelector(
        'pre.mermaid > svg',
        timeout: const Duration(seconds: 5),
      );

      final element = await page.$('pre.mermaid > svg');

      return await element.evaluate('el => el.outerHTML');
    });
  }

  Future<List<int>> _convertSvgToImage(Browser browser, String svgContent) {
    return _withPage(browser, (page) async {
      await page.setViewport(DeviceViewport(
        width: 1280,
        height: 780,
        deviceScaleFactor: 2,
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

  Future<List<int>> _generateMermaidGraphImage(
    Browser browser,
    String graphDefinition,
  ) async {
    try {
      final svgContent = await _generateMermaidGraph(browser, graphDefinition);

      return await _convertSvgToImage(browser, svgContent);
    } catch (e, stackTrace) {
      logger.err('Failed to generate Mermaid graph image: $e');
      Error.throwWithStackTrace(
        Exception(
          'Mermaid generation timed out or failed. Original error: $e',
        ),
        stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _browser?.close();
    _browser = null;
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
        final browser = await _getBrowser();

        logger.info(
          'Generating mermaid graph image for slide index: ${context.slideIndex}',
        );
        final imageData =
            await _generateMermaidGraphImage(browser, mermaidBlock.content);

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
