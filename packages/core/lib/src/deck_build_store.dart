import 'dart:convert';
import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'markdown_json.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Build-side store used by CLI and builder commands.
///
/// Runtime loaders live in the `superdeck` package; this type stays in core
/// as the build-side storage primitive over the same workspace layout, while
/// domain data contracts live in model files.
class DeckBuildStore {
  DeckBuildStore({required this.configuration});

  final DeckConfiguration configuration;
  final List<GeneratedAsset> _generatedAssets = [];
  final Logger _logger = Logger('DeckBuildStore');

  Future<void> initialize() async {
    await configuration.assetsDir.ensureExists();
    await configuration.deckJson.ensureExists(content: '{}');
    await configuration.buildStatusJson.ensureExists(
      content: prettyJson(
        DeckBuildStatus(
          phase: DeckBuildPhase.unknown,
          timestamp: DateTime.now(),
        ).toMap(),
      ),
    );
    await configuration.slidesFile.ensureExists(content: '');
  }

  Future<String> readDeckMarkdown() async {
    return configuration.slidesFile.readAsString();
  }

  void clearGeneratedAssets() {
    _generatedAssets.clear();
  }

  String getGeneratedAssetPath(GeneratedAsset asset) {
    _generatedAssets.add(asset);
    return p.join(configuration.assetsDir.path, asset.fileName);
  }

  Future<void> saveReferences(Deck reference) async {
    final deckJson = prettyJson(reference.toMap());
    await configuration.deckJson.writeAsString(deckJson);

    await _saveFullDeckReference(reference);
    final uniqueAssets = <String, GeneratedAsset>{};
    for (final asset in _generatedAssets) {
      uniqueAssets[asset.fileName] = asset;
    }

    final assetPaths = uniqueAssets.values
        .map((asset) => p.join(configuration.assetsDir.path, asset.fileName))
        .toList();

    final previousAssetsRef = await _readExistingAssetsReference();
    final filesUnchanged =
        previousAssetsRef != null &&
        _haveSamePaths(assetPaths, previousAssetsRef.files);

    final assetsRef = GeneratedAssetsReference(
      lastModified: filesUnchanged
          ? previousAssetsRef.lastModified
          : DateTime.now(),
      files: assetPaths,
    );

    if (!filesUnchanged) {
      final assetsJson = prettyJson(assetsRef.toMap());
      await configuration.assetsRefJson.writeAsString(assetsJson);
    }

    await _cleanupGeneratedAssets(assetsRef);
  }

  Future<void> saveBuildStatus({
    required DeckBuildPhase phase,
    int? slideCount,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (phase == DeckBuildPhase.failure && error != null) {
      _logger.severe('Build failed: $error', error, stackTrace);
    }

    final status = DeckBuildStatus(
      phase: phase,
      timestamp: DateTime.now(),
      slideCount: slideCount,
      error: phase == DeckBuildPhase.failure && error != null
          ? DeckBuildError(message: error.toString())
          : null,
    );

    await configuration.buildStatusJson.ensureWrite(prettyJson(status.toMap()));
  }

  Future<void> _saveFullDeckReference(Deck reference) async {
    final converter = MarkdownAstConverter(
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    final slidesWithMarkdownJson = reference.slides.map((slide) {
      final slideMap = slide.toMap();

      // Process each section's blocks to replace content with markdown AST
      final sections = slideMap['sections'] as List<dynamic>;
      final processedSections = sections.map((section) {
        final sectionMap = Map<String, Object?>.from(section as Map);
        final blocks = sectionMap['blocks'] as List<dynamic>? ?? const [];

        final processedBlocks = blocks.map((block) {
          final blockMap = Map<String, Object?>.from(block as Map);

          // If the block has content, replace it with parsed markdown AST
          if (blockMap.containsKey('content') &&
              blockMap['content'] is String) {
            final contentString = blockMap['content'] as String;
            final markdownAst = converter.toMap(
              contentString,
              includeMetadata: true,
            );
            // Replace the string content with the parsed AST object
            blockMap['content'] = markdownAst;
          }

          return blockMap;
        }).toList();

        sectionMap['blocks'] = processedBlocks;
        return sectionMap;
      }).toList();

      slideMap['sections'] = processedSections;
      return slideMap;
    }).toList();

    final fullDeckMap = reference.toMap();
    fullDeckMap['slides'] = slidesWithMarkdownJson;

    final fullDeckJson = prettyJson(fullDeckMap);
    await configuration.deckFullJson.writeAsString(fullDeckJson);
  }

  /// Removes generated assets that are no longer referenced.
  Future<void> _cleanupGeneratedAssets(
    GeneratedAssetsReference assetsReference,
  ) async {
    final existingFiles = await configuration.assetsDir
        .list(recursive: true)
        .where((e) => e is File)
        .map((e) => e as File)
        .toList();

    final referencedFiles = assetsReference.files.toSet();

    final filesToDelete = existingFiles.where(
      (file) => !referencedFiles.contains(file.path),
    );

    await Future.wait(
      filesToDelete.map((file) async {
        try {
          if (await file.exists()) {
            await file.delete();
            _logger.info('Deleted unreferenced asset: ${file.path}');
          }
        } catch (e) {
          _logger.warning('Failed to delete asset file ${file.path}: $e');
        }
      }),
    );
  }

  Future<GeneratedAssetsReference?> _readExistingAssetsReference() async {
    final file = configuration.assetsRefJson;
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return null;
      }

      final data = jsonDecode(content) as Map<String, dynamic>;
      return GeneratedAssetsReference.fromMap(data);
    } catch (e) {
      _logger.warning(
        'Failed to parse existing generated assets reference: $e',
      );
      return null;
    }
  }

  bool _haveSamePaths(List<String> current, List<String> previous) {
    if (current.length != previous.length) {
      return false;
    }

    for (var i = 0; i < current.length; i++) {
      if (current[i] != previous[i]) {
        return false;
      }
    }

    return true;
  }
}
