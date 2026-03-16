import 'dart:convert';
import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

import '../markdown/markdown_json.dart';
import '../utils/extensions.dart';
import '../utils/logging_utils.dart';
import '../utils/pretty_json.dart';
import 'asset_model.dart';
import 'deck_build_status.dart';
import 'deck_workspace.dart';
import 'slide_model.dart';

/// Build-side store used by CLI and builder commands.
///
/// Runtime loaders live in the `superdeck` package; this type stays in core
/// as the build-side storage primitive over the same workspace layout, while
/// domain data contracts live in model files.
class DeckBuildStore {
  DeckBuildStore({required this.workspace});

  final DeckWorkspace workspace;
  final List<GeneratedAsset> _generatedAssets = [];
  final Logger _logger = Logger('DeckBuildStore');

  Future<void> initialize() async {
    await workspace.assetsDir.ensureExists();
    await workspace.deckJson.ensureExists(content: '[]');
    await workspace.buildStatusJson.ensureExists(
      content: prettyJson(
        DeckBuildStatus(
          phase: DeckBuildPhase.unknown,
          timestamp: DateTime.now(),
        ).toMap(),
      ),
    );
    await workspace.slidesFile.ensureExists(content: '');
  }

  Future<String> readDeckMarkdown() async {
    return workspace.slidesFile.readAsString();
  }

  void clearGeneratedAssets() {
    _generatedAssets.clear();
  }

  String getGeneratedAssetPath(GeneratedAsset asset) {
    _generatedAssets.add(asset);
    return p.join(workspace.assetsDir.path, asset.fileName);
  }

  Future<void> saveReferences(List<Slide> slides) async {
    final deckJson = prettyJson(
      slides.map((slide) => slide.toMap()).toList(growable: false),
    );
    await workspace.deckJson.writeAsString(deckJson);

    await _saveFullDeckReference(slides);
    final uniqueAssets = <String, GeneratedAsset>{};
    for (final asset in _generatedAssets) {
      uniqueAssets[asset.fileName] = asset;
    }

    final assetPaths = uniqueAssets.values
        .map((asset) => p.join(workspace.assetsDir.path, asset.fileName))
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
      await workspace.assetsRefJson.writeAsString(assetsJson);
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

    await workspace.buildStatusJson.ensureWrite(prettyJson(status.toMap()));
  }

  Future<void> _saveFullDeckReference(List<Slide> slides) async {
    final converter = MarkdownAstConverter(
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    final slidesWithMarkdownJson = slides.map((slide) {
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

    final fullDeckJson = prettyJson(slidesWithMarkdownJson);
    await workspace.deckFullJson.writeAsString(fullDeckJson);
  }

  /// Removes generated assets that are no longer referenced.
  Future<void> _cleanupGeneratedAssets(
    GeneratedAssetsReference assetsReference,
  ) async {
    final existingFiles = await workspace.assetsDir
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
    final file = workspace.assetsRefJson;
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
