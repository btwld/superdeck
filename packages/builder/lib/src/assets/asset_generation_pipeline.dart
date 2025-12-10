import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

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
  final DeckService _store;
  final Logger _logger = Logger('AssetGenerationPipeline');

  AssetGenerationPipeline({
    required List<AssetGenerator> generators,
    required DeckService store,
  }) : _generators = generators,
       _store = store;

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
        try {
          final processingResult = await _processCodeBlock(block, slideIndex);

          // If null, the block was skipped (no generator found)
          if (processingResult == null) {
            return null;
          }

          final (asset, replacementSyntax) = processingResult;
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
      _logger.info(
        'Skipped ${codeBlock.language} block for slide $slideIndex: No generator found',
      );
      return null;
    }

    _logger.info(
      'Processing ${codeBlock.language} block at indices ${codeBlock.startIndex}-${codeBlock.endIndex} for slide $slideIndex',
    );

    // Let the generator create its own asset reference
    final generatedAsset = generator.createAssetReference(codeBlock.content);

    final assetPath = _store.getGeneratedAssetPath(generatedAsset);
    final assetFile = File(assetPath);

    // Check if asset already exists
    if (await assetFile.exists()) {
      _logger.info(
        '${generator.type} asset already exists for slide $slideIndex',
      );
    } else {
      _logger.info('Generating ${generator.type} asset for slide $slideIndex');

      // Generate the asset
      final assetData = await generator.generateAsset(
        codeBlock.content,
        assetPath,
      );

      // Write to disk
      await assetFile.writeAsBytes(assetData);
    }

    // Create replacement syntax with relative path from project directory
    final projectDir = _store.configuration.superdeckDir.parent.path;
    final relativePath = path.relative(assetFile.path, from: projectDir);
    final replacementSyntax = '![${generator.type}_asset]($relativePath)';

    return (generatedAsset, replacementSyntax);
  }

  /// Disposes of all generators.
  Future<void> dispose() async {
    for (final generator in _generators) {
      await generator.dispose();
    }
  }
}
