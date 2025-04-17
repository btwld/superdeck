import 'dart:async';
import 'dart:typed_data';

import 'package:puppeteer/puppeteer.dart';
import 'package:superdeck_builder/src/core/task.dart';
import 'package:superdeck_builder/src/core/task_context.dart';
import 'package:superdeck_builder/src/parsers/fenced_code_parser.dart';
import 'package:superdeck_builder/src/services/browser_service.dart';
import 'package:superdeck_core/superdeck_core.dart';

class MermaidConverterTask extends Task implements CleanupCapableTask {
  final BrowserService _browserService;
  final AssetRepository _assetRepository;

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
      'timeout': 5,
      'cacheInvalidationMinutes': 60,
    },
  })  : _browserService = browserService,
        _assetRepository = assetRepository,
        _cacheInvalidationTime = Duration(
          minutes: (configuration['cacheInvalidationMinutes'] as int?) ?? 60,
        ),
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
  Future<void> run(TaskContext context) async {
    final stopwatch = Stopwatch()..start();

    final fencedCodeParser = const FencedCodeParser();
    final codeBlocks = fencedCodeParser.parse(context.slide.content);
    final mermaidBlocks = codeBlocks.where((e) => e.language == 'mermaid');

    if (mermaidBlocks.isEmpty) {
      return;
    }

    int processedCount = 0;
    int cachedCount = 0;

    for (final mermaidBlock in mermaidBlocks) {
      try {
        // Create asset using Asset model
        final mermaidAsset = Asset(
          id: generateValueHash(mermaidBlock.content),
          extension: AssetExtension.png,
          type: AssetType.mermaid,
        );

        // Track this asset to prevent cleanup
        final assetId = '${mermaidAsset.type.name}_${mermaidAsset.id}';
        _processedAssetIds.add(assetId);

        // Check if we need to regenerate the asset
        final shouldRegenerate = await _shouldRegenerateAsset(mermaidAsset);

        if (shouldRegenerate) {
          logger.info(
            'Generating mermaid graph image for slide index: ${context.slideIndex}',
          );
          // Generate and save the image
          final imageData =
              await _generateMermaidGraphImage(mermaidBlock.content);
          await _assetRepository.saveAsset(
              mermaidAsset, Uint8List.fromList(imageData));

          // Record asset generation time
          _assetGenerationTimes[assetId] = DateTime.now();
          processedCount++;
        } else {
          logger.info(
            'Using cached mermaid asset for slide index: ${context.slideIndex}',
          );
          cachedCount++;
        }

        // Get the asset source path
        final assetSource = await _assetRepository.getAssetSource(mermaidAsset);

        // Replace mermaid code with image link
        final mermaidImageSyntax = '![mermaid_graph](${assetSource.path})';
        final updatedMarkdown = context.slide.content.replaceRange(
          mermaidBlock.startIndex,
          mermaidBlock.endIndex,
          mermaidImageSyntax,
        );

        context.slide.content = updatedMarkdown;
      } catch (e, stackTrace) {
        // Log error but continue processing other mermaid blocks
        logger.severe(
          'Error processing mermaid block in slide ${context.slideIndex}: $e',
          stackTrace,
        );
        // Continue with next mermaid block rather than failing the entire task
      }
    }

    stopwatch.stop();
    logger.info(
      'Completed MermaidConverterTask for slide ${context.slideIndex}: '
      'Generated $processedCount new, used $cachedCount cached, '
      'in ${stopwatch.elapsedMilliseconds}ms',
    );
  }

  /// Call this method after all slides have been processed
  /// to cleanup unused assets
  Future<void> cleanupUnusedAssets() async {
    if (_processedAssetIds.isEmpty) {
      logger.info('No mermaid assets to clean up');
      return;
    }

    final beforeCount = _processedAssetIds.length;
    logger.info(
        'Cleaning up mermaid assets, tracking $beforeCount active assets');

    try {
      await _assetRepository.cleanupUnusedAssets(_processedAssetIds);
      logger.info('Successfully cleaned up unused mermaid assets');
    } catch (e, stackTrace) {
      logger.severe('Error cleaning up mermaid assets: $e', stackTrace);
    }
  }

  /// Reset all tracked assets - useful when reprocessing the entire deck
  void resetAssetTracking() {
    _processedAssetIds.clear();
    _assetGenerationTimes.clear();
    logger.info('Reset mermaid asset tracking');
  }
}
