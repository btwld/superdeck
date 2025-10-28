import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:superdeck_core/markdown_json.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Repository for managing deck data from the local file system.
///
/// Provides functionality for loading, watching, and saving decks,
/// as well as managing generated assets.
class DeckRepository {
  DeckRepository({required this.configuration});

  final DeckConfiguration configuration;
  final List<GeneratedAsset> _generatedAssets = [];
  final Logger _logger = Logger('DeckRepository');

  /// Initializes the repository by creating necessary directories and files.
  Future<void> initialize() async {
    await configuration.assetsDir.ensureExists();
    await configuration.deckJson.ensureExists(content: '{}');
    await configuration.buildStatusJson.ensureExists(
      content: prettyJson({'status': 'unknown'}),
    );
    await configuration.slidesFile.ensureExists(content: '');
  }

  /// Loads the current deck reference.
  Future<Deck> loadDeck() async {
    try {
      final file = configuration.deckJson;
      if (!await file.exists()) {
        throw Exception('Deck file not found at ${file.path}');
      }
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return Deck.fromMap(data);
    } on Exception catch (e) {
      return _createErrorDeck(
        'Superdeck reference error',
        configuration.deckJson.path,
        e,
      );
    }
  }

  /// Provides a stream of deck updates.
  ///
  /// Watches the deck JSON file and emits updates when it changes.
  /// Note: This only watches the JSON output. The caller is responsible for
  /// running the DeckBuilder to generate the JSON from markdown.
  Stream<Deck> loadDeckStream() async* {
    _logger.info('Loading deck stream...');

    // Emit the current deck immediately with timeout for initial load
    try {
      yield await loadDeck().timeout(const Duration(seconds: 10));
    } catch (e) {
      _logger.severe('Initial deck loading failed: $e');
      yield _createErrorDeck(
        'Deck Loading Timeout',
        'Failed to load deck within 10 seconds',
        e,
      );
    }

    // Watch the deck JSON for changes
    _logger.info('Watching for deck changes...');

    try {
      // If the file doesn't exist yet, wait for it to be created
      if (!await configuration.deckJson.exists()) {
        _logger.info('Deck file does not exist, waiting for creation...');
        await for (final event in configuration.deckJson.parent.watch(
          events: FileSystemEvent.create,
        )) {
          if (event.path == configuration.deckJson.path) {
            _logger.info('Deck file created, loading...');
            yield await loadDeck();
            break;
          }
        }
      }

      // Now watch for modifications to the existing file
      await for (final _ in configuration.deckJson.watch(
        events: FileSystemEvent.modify,
      )) {
        _logger.info('Deck updated, reloading...');
        yield await loadDeck();
      }
    } catch (e) {
      _logger.severe('Error in file watching: $e');
      rethrow;
    }
  }

  /// Clears the generated assets list.
  ///
  /// Should be called at the start of each build to prevent accumulation
  /// of assets from previous builds.
  void clearGeneratedAssets() {
    _generatedAssets.clear();
  }

  /// Gets the file path for a generated asset.
  String getGeneratedAssetPath(GeneratedAsset asset) {
    _generatedAssets.add(asset);
    return p.join(configuration.assetsDir.path, asset.fileName);
  }

  /// Reads an asset file by its path.
  Future<String> readAssetByPath(String path) async {
    return File(path).readAsString();
  }

  /// Saves the deck reference and manages generated assets.
  Future<void> saveReferences(Deck reference) async {
    // Save deck reference
    final deckJson = prettyJson(reference.toMap());
    await configuration.deckJson.writeAsString(deckJson);

    // Save full deck reference with markdown AST JSON
    await _saveFullDeckReference(reference);

    // Generate the asset references for each slide thumbnail
    final thumbnails = reference.slides.map(
      (slide) => GeneratedAsset.thumbnail(slide.key),
    );

    // Combine thumbnail and generated assets, then deduplicate by fileName
    final allAssets = [...thumbnails, ..._generatedAssets];
    final uniqueAssets = <String, GeneratedAsset>{};
    for (final asset in allAssets) {
      uniqueAssets[asset.fileName] = asset;
    }

    // Map asset references to their corresponding file paths
    final assetFiles = uniqueAssets.values
        .map(
          (asset) => File(p.join(configuration.assetsDir.path, asset.fileName)),
        )
        .toList();

    final previousAssetsRef = await _readExistingAssetsReference();
    final filesUnchanged =
        previousAssetsRef != null &&
        _haveSamePaths(assetFiles, previousAssetsRef.files);

    final assetsRef = GeneratedAssetsReference(
      lastModified: filesUnchanged
          ? previousAssetsRef.lastModified
          : DateTime.now(),
      files: assetFiles,
    );

    if (!filesUnchanged) {
      final assetsJson = prettyJson(assetsRef.toMap());
      await configuration.assetsRefJson.writeAsString(assetsJson);
    }

    await _cleanupGeneratedAssets(assetsRef);
  }

  /// Persists the result of the most recent build without replacing existing decks.
  ///
  /// The [status] parameter should be one of: 'building', 'success', 'failure', 'unknown'.
  Future<void> saveBuildStatus({
    required String status,
    int? slideCount,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final statusData = <String, Object?>{
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      if (slideCount != null) 'slideCount': slideCount,
    };

    if (status == 'failure' && error != null) {
      statusData['error'] = {
        'type': error.runtimeType.toString(),
        'message': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };
    }

    await configuration.buildStatusJson.ensureWrite(prettyJson(statusData));
  }

  /// Reads the markdown content of the slides file.
  Future<String> readDeckMarkdown() async {
    return await configuration.slidesFile.readAsString();
  }

  /// Creates an error deck with the specified details.
  Deck _createErrorDeck(String title, String message, Object error) {
    return Deck(
      slides: [
        Slide.error(
          title: title,
          message: message,
          error: error is Exception ? error : Exception(error.toString()),
        ),
      ],
      configuration: configuration,
    );
  }

  /// Saves the full deck reference with markdown AST JSON for each slide content.
  ///
  /// Replaces the `content` field (string) with the parsed markdown AST (object)
  /// for all ColumnBlocks that contain markdown content.
  Future<void> _saveFullDeckReference(Deck reference) async {
    final converter = MarkdownAstConverter(
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    final slidesWithMarkdownJson = reference.slides.map((slide) {
      final slideMap = slide.toMap();

      // Process each section's blocks to replace content with markdown AST
      final sections = slideMap['sections'] as List<dynamic>;
      final processedSections = sections.map((section) {
        final sectionMap = Map<String, dynamic>.from(section as Map);
        final blocks = sectionMap['blocks'] as List<dynamic>;

        final processedBlocks = blocks.map((block) {
          final blockMap = Map<String, dynamic>.from(block as Map);

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

    final fullDeckMap = {
      'slides': slidesWithMarkdownJson,
      'configuration': reference.configuration.toMap(),
    };

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

    final referencedFiles = assetsReference.files
        .map((file) => file.path)
        .toSet();

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

  bool _haveSamePaths(List<File> current, List<File> previous) {
    if (current.length != previous.length) {
      return false;
    }

    for (var i = 0; i < current.length; i++) {
      if (current[i].path != previous[i].path) {
        return false;
      }
    }

    return true;
  }
}
