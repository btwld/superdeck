import 'dart:async';
import 'dart:typed_data';

import 'package:puppeteer/puppeteer.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/fenced_code_parser.dart';
import '../pipeline/builder_context.dart';
import '../services/browser_service.dart';
import 'task.dart';

class MermaidConverterTask extends Task implements CleanupCapableTask {
  final BrowserService _browserService;
  final AssetRepository _assetRepository;
  final Map<String, dynamic> configuration;

  // Set to track generated assets for cleanup
  final Set<String> _processedAssetIds = {};

  // Map to track asset generation timestamps for potential cache invalidation
  final Map<String, DateTime> _assetGenerationTimes = {};

  // Cache invalidation time (default: 1 hour)
  final Duration _cacheInvalidationTime;

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
    required AssetRepository assetRepository,
    this.configuration = const {
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
      'timeout': 5,
      'cacheInvalidationMinutes': 60,
    },
  })  : _browserService = browserService,
        _assetRepository = assetRepository,
        _cacheInvalidationTime = Duration(
          minutes: (configuration['cacheInvalidationMinutes'] as int?) ?? 60,
        ),
        super('mermaid');

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

  /// Check if an asset needs to be regenerated based on cache invalidation rules
  Future<bool> _shouldRegenerateAsset(Asset asset) async {
    final assetId = '${asset.type.name}_${asset.id}';
    final assetExists = await _assetRepository.assetExists(asset);

    if (!assetExists) {
      return true; // Regenerate if doesn't exist
    }

    // Check cache invalidation time if enabled
    if (_cacheInvalidationTime > Duration.zero) {
      final lastGenerated = _assetGenerationTimes[assetId];
      if (lastGenerated != null) {
        final age = DateTime.now().difference(lastGenerated);
        if (age > _cacheInvalidationTime) {
          logger.info('Asset $assetId cache expired (age: ${age.inMinutes}m)');
          return true;
        }
      }
    }

    return false;
  }

  @override
  Future<void> run(BuilderContext context) async {
    final stopwatch = Stopwatch()..start();

    final fencedCodeParser = const FencedCodeParser();
    final codeBlocks = fencedCodeParser.parse(context.slide.content);
    final mermaidBlocks =
        codeBlocks.where((block) => block.language == 'mermaid');

    if (mermaidBlocks.isEmpty) {
      return;
    }

    // Get browser ready
    await _browserService.getBrowser();

    var blockIndex = 0;
    for (final block in mermaidBlocks) {
      final uniqueId = _generateUniqueId(context.slideIndex, blockIndex++);

      try {
        final graphDefinition = block.content.trim();
        if (graphDefinition.isEmpty) {
          logger.warning('Empty Mermaid graph definition, skipping');
          continue;
        }

        final asset = Asset.mermaid(uniqueId);

        // Skip regeneration if asset exists and cache is valid
        if (!await _shouldRegenerateAsset(asset)) {
          logger.info('Using cached Mermaid asset: $uniqueId');
          // Replace the mermaid code block with an image reference
          _replaceMermaidCodeWithImage(context, block, asset.id);
          _processedAssetIds.add('${asset.type.name}_${asset.id}');
          continue;
        }

        // Generate the image
        final imageData = await _generateMermaidGraphImage(graphDefinition);

        // Save to asset repository
        await _assetRepository.saveAsset(
          asset,
          Uint8List.fromList(imageData),
        );

        // Track for cleanup and cache invalidation
        _processedAssetIds.add('${asset.type.name}_${asset.id}');
        _assetGenerationTimes['${asset.type.name}_${asset.id}'] =
            DateTime.now();

        // Replace the mermaid code block with an image reference
        _replaceMermaidCodeWithImage(context, block, asset.id);

        logger.info(
          'Generated Mermaid asset: $uniqueId (${imageData.length} bytes)',
        );
      } catch (e) {
        logger.severe('Failed to process Mermaid block: $e');
      }
    }

    logger.info(
      'Processed ${mermaidBlocks.length} Mermaid blocks in ${stopwatch.elapsedMilliseconds}ms',
    );
  }

  String _generateUniqueId(int slideIndex, int blockIndex) {
    return 'mermaid_slide${slideIndex}_block${blockIndex}';
  }

  void _replaceMermaidCodeWithImage(
    BuilderContext context,
    ParsedFencedCode block,
    String assetId,
  ) {
    final imageMarkdown = '@image{asset: $assetId}';

    final content = context.slide.content;
    final updatedContent = content.replaceRange(
      block.startIndex,
      block.endIndex,
      imageMarkdown,
    );

    context.slide.content = updatedContent;
  }

  @override
  Future<void> dispose() async {
    await _browserService.dispose();
  }

  @override
  Future<void> cleanup() async {
    logger.info('Cleaning up unused Mermaid assets');

    // Since we don't have listAssets and deleteAsset, we'll use cleanupUnusedAssets
    await _assetRepository.cleanupUnusedAssets(_processedAssetIds);

    logger.info('Mermaid cleanup complete');
  }
}
