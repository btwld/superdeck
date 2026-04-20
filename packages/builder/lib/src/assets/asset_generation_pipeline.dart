import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/fenced_code_parser.dart';
import '../utils/markdown_utils.dart';

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
/// The [AssetGenerationPipeline] finds asset blocks in slide content (fenced
/// code blocks, remote images), processes them through appropriate
/// [AssetGenerator]s, and replaces the content with asset references.
class AssetGenerationPipeline {
  final List<AssetGenerator> _generators;
  final DeckBuildStore _store;
  final AssetCacheStore _cache;
  final Logger _logger = Logger('AssetGenerationPipeline');

  AssetGenerationPipeline({
    required List<AssetGenerator> generators,
    required DeckBuildStore store,
    AssetCacheStore? cacheStore,
  }) : _generators = generators,
       _store = store,
       _cache =
           cacheStore ?? IoAssetCacheStore(cacheDir: store.workspace.assetsDir);

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

    // Process fenced code blocks through registered generators.
    final updatedContent = await processFencedCodeBlocks(
      content,
      filter: (block) => _findGenerator(block.language) != null,
      transform: (block) async {
        try {
          final processingResult = await _processCodeBlock(block, slideIndex);

          // If null, the block was skipped (no generator found)
          if (processingResult == null) {
            return null;
          }

          final (asset, replacementSyntax) = processingResult;
          generatedAssets.add(asset);

          return replacementSyntax;
        } catch (error) {
          _logger.severe(
            'Failed to process ${block.language} block for slide $slideIndex: $error',
          );
          throw Exception('Failed to process ${block.language} block: $error');
        }
      },
    );

    if (generatedAssets.isNotEmpty) {
      _logger.info(
        'Slide $slideIndex: generated ${generatedAssets.length} assets',
      );
    }

    return AssetGenerationResult(
      updatedContent: updatedContent,
      generatedAssets: generatedAssets,
    );
  }

  /// Finds the appropriate generator for the given content type using pattern matching.
  AssetGenerator? _findGenerator(String contentType) {
    for (final generator in _generators) {
      // Use generator's canProcess method which might use pattern matching internally
      if (generator.canProcess(contentType)) {
        return generator;
      }
    }
    return null;
  }

  /// Processes a single code block through the appropriate generator.
  ///
  /// Returns a record of (GeneratedAsset, replacementSyntax) if successful,
  /// or null if the block was skipped (no generator found).
  /// Throws an exception if processing fails.
  Future<(GeneratedAsset, String)?> _processCodeBlock(
    ParsedFencedCode codeBlock,
    int slideIndex,
  ) async {
    final generator = _findGenerator(codeBlock.language);
    if (generator == null) {
      return null;
    }

    // Let the generator create its own asset reference
    final generatedAsset = generator.createAssetReference(codeBlock.content);

    final assetPath = _store.getGeneratedAssetPath(generatedAsset);
    final cachedUri = await _cache.resolve(generatedAsset.fileName);
    if (cachedUri != null) {
      _validateCachedAssetPath(
        cacheUri: cachedUri,
        expectedPath: assetPath,
        assetKey: generatedAsset.fileName,
      );
    } else {
      final assetData = await generator.generateAsset(
        codeBlock.content,
        assetPath,
      );
      final writtenUri = await _cache.write(generatedAsset.fileName, assetData);
      if (writtenUri == null) {
        throw StateError(
          'Failed to write ${generator.type} asset to cache for key '
          '"${generatedAsset.fileName}".',
        );
      }
      _validateCachedAssetPath(
        cacheUri: writtenUri,
        expectedPath: assetPath,
        assetKey: generatedAsset.fileName,
      );
    }

    // Create replacement syntax with relative path from project directory
    final projectDir = _store.workspace.projectDirectory.path;
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
        'Configure cacheStore to use workspace.assetsDir.',
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
