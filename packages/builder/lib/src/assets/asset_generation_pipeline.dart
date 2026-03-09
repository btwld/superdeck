import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_core/asset_cache_store_io.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/fenced_code_parser.dart';
import '../markdown_utils.dart';
import 'asset_generator.dart';

/// Result of asset generation pipeline processing on slide content.
class AssetGenerationResult {
  /// The updated slide content with asset references replaced.
  final String updatedContent;

  /// List of generated assets that were created during processing.
  final List<GeneratedAsset> generatedAssets;

  const AssetGenerationResult({
    required this.updatedContent,
    required this.generatedAssets,
  });
}

/// Coordinates build-time asset generation across multiple asset generators.
///
/// The [AssetGenerationPipeline] finds asset blocks in slide content (e.g., mermaid diagrams,
/// remote images), processes them through appropriate [AssetGenerator]s, and
/// replaces the content with asset references.
class AssetGenerationPipeline {
  final List<AssetGenerator> _generators;
  final DeckService _deckService;
  final AssetCacheStore _cache;
  final _logger = Logger('AssetGenerationPipeline');

  AssetGenerationPipeline({
    required List<AssetGenerator> generators,
    required DeckService deckService,
    AssetCacheStore? cacheStore,
  }) : _generators = generators,
       _deckService = deckService,
       _cache =
           cacheStore ??
           IoAssetCacheStore(cacheDir: deckService.configuration.assetsDir);

  /// Processes all assets in the given slide content.
  ///
  /// Finds asset blocks (fenced code blocks, remote images, etc.),
  /// generates assets through appropriate generators, and returns
  /// updated content with asset references.
  Future<AssetGenerationResult> processSlideContent(
    String content,
    int slideIndex,
  ) async {
    final generatedAssets = <GeneratedAsset>[];

    // Process fenced code blocks (mermaid, etc.) using the utility
    final updatedContent = await processFencedCodeBlocks(
      content,
      filter: (block) => _findGenerator(block.language) != null,
      transform: (block) async {
        final generator = _findGenerator(block.language);
        if (generator == null) {
          return null;
        }

        try {
          final (asset, replacementSyntax) = await _processCodeBlock(
            block,
            slideIndex,
            generator,
          );
          generatedAssets.add(asset);

          _logger.info(
            'Replaced ${block.language} block with asset reference for slide $slideIndex',
          );

          return replacementSyntax;
        } catch (error) {
          _logger.severe(
            'Failed to process ${block.language} block for slide $slideIndex: $error',
          );
          throw Exception('Failed to process ${block.language} block: $error');
        }
      },
    );

    return AssetGenerationResult(
      updatedContent: updatedContent,
      generatedAssets: generatedAssets,
    );
  }

  /// Finds the first generator that can process [contentType].
  AssetGenerator? _findGenerator(String contentType) {
    for (final generator in _generators) {
      if (generator.canProcess(contentType)) {
        return generator;
      }
    }
    return null;
  }

  /// Processes a single code block through the appropriate generator.
  ///
  /// Returns a record of (GeneratedAsset, replacementSyntax) if successful.
  /// Throws an exception if processing fails.
  Future<(GeneratedAsset, String)> _processCodeBlock(
    ParsedFencedCode codeBlock,
    int slideIndex,
    AssetGenerator generator,
  ) async {
    _logger.info(
      'Processing ${codeBlock.language} block at indices ${codeBlock.startIndex}-${codeBlock.endIndex} for slide $slideIndex',
    );

    // Let the generator create its own asset reference
    final generatedAsset = generator.createAssetReference(codeBlock.content);

    final assetPath = _deckService.getGeneratedAssetPath(generatedAsset);
    var resolvedUri = await _cache.resolve(generatedAsset.fileName);
    if (resolvedUri != null) {
      _logger.info(
        '${generator.type} asset already exists for slide $slideIndex',
      );
    } else {
      _logger.info('Generating ${generator.type} asset for slide $slideIndex');

      final assetData = await generator.generateAsset(
        codeBlock.content,
        assetPath,
      );
      resolvedUri = await _cache.write(generatedAsset.fileName, assetData);
      if (resolvedUri == null) {
        throw StateError(
          'Failed to write ${generator.type} asset to cache for key '
          '"${generatedAsset.fileName}".',
        );
      }
    }

    _validateCachedAssetPath(
      cacheUri: resolvedUri,
      expectedPath: assetPath,
      assetKey: generatedAsset.fileName,
    );

    // Create replacement syntax with relative path from project directory
    final projectDir = _deckService.configuration.superdeckDir.parent.path;
    final relativePath = path.relative(assetPath, from: projectDir);
    final replacementSyntax = '![${generator.type}_asset]($relativePath)';

    return (generatedAsset, replacementSyntax);
  }

  void _validateCachedAssetPath({
    required Uri cacheUri,
    required String expectedPath,
    required String assetKey,
  }) {
    final resolvedPath = path.normalize(
      cacheUri.scheme == 'file' ? cacheUri.toFilePath() : cacheUri.path,
    );
    final normalizedExpectedPath = path.normalize(expectedPath);
    if (resolvedPath != normalizedExpectedPath) {
      throw StateError(
        'Asset cache path mismatch for "$assetKey". Expected '
        '"$normalizedExpectedPath" but resolved "$resolvedPath". '
        'Configure cacheStore to use configuration.assetsDir.',
      );
    }
  }

  /// Disposes of all generators.
  Future<void> dispose() async {
    for (final generator in _generators) {
      await generator.dispose();
    }
  }
}
