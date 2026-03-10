import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:superdeck_core/src/markdown_json.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Runtime service for loading deck data and watching build status updates.
class DeckService {
  DeckService({required this.configuration});

  final DeckConfiguration configuration;
  final Logger _logger = Logger('DeckService');

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

  /// Emits only fresh build status updates observed after watching starts.
  Stream<DeckBuildStatus> watchBuildStatus() {
    final statusFile = configuration.buildStatusJson;
    final parentDir = statusFile.parent;
    final projectDir = Directory(configuration.projectDir ?? '.');

    late final StreamController<DeckBuildStatus> controller;
    StreamSubscription<FileSystemEvent>? activeWatch;
    Completer<void>? activeWait;
    var cancelled = false;
    String? lastTimestamp;

    Future<void> emitIfFresh() async {
      try {
        if (!await statusFile.exists()) {
          return;
        }

        final content = await statusFile.readAsString();
        final decoded = jsonDecode(content);
        final parsed = DeckBuildStatus.fromObject(decoded);

        if (parsed == null) {
          return;
        }

        final timestampKey = parsed.timestamp.toIso8601String();
        if (timestampKey == lastTimestamp) {
          return;
        }

        lastTimestamp = timestampKey;
        if (!controller.isClosed) {
          controller.add(parsed);
        }
      } on Exception catch (error) {
        _logger.fine('Ignoring transient build status parse failure: $error');
      }
    }

    Future<void> waitForDirectoryCreation() async {
      if (cancelled || await parentDir.exists()) {
        return;
      }

      final wait = Completer<void>();
      activeWait = wait;
      activeWatch = projectDir
          .watch(events: FileSystemEvent.create, recursive: true)
          .listen(
            (_) async {
              if (cancelled || wait.isCompleted) {
                return;
              }

              if (await parentDir.exists() && !wait.isCompleted) {
                wait.complete();
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!wait.isCompleted) {
                wait.complete();
              }

              if (error is! FileSystemException && !controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            },
            onDone: () {
              if (!wait.isCompleted) {
                wait.complete();
              }
            },
          );

      if (await parentDir.exists() && !wait.isCompleted) {
        wait.complete();
      }

      await wait.future;
      activeWait = null;
      await activeWatch?.cancel();
      activeWatch = null;
    }

    Future<void> waitForStatusChanges() async {
      final wait = Completer<void>();
      final statusPath = p.normalize(statusFile.path);
      activeWait = wait;
      activeWatch = parentDir
          .watch(events: FileSystemEvent.create | FileSystemEvent.modify)
          .listen(
            (event) async {
              if (cancelled || p.normalize(event.path) != statusPath) {
                return;
              }

              await emitIfFresh();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!wait.isCompleted) {
                wait.complete();
              }

              if (error is! FileSystemException && !controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            },
            onDone: () {
              if (!wait.isCompleted) {
                wait.complete();
              }
            },
          );

      await wait.future;
      activeWait = null;
      await activeWatch?.cancel();
      activeWatch = null;
    }

    Future<void> watchLoop() async {
      if (await parentDir.exists() && await statusFile.exists()) {
        try {
          final existingContent = await statusFile.readAsString();
          final existingDecoded = jsonDecode(existingContent);
          final existingStatus = DeckBuildStatus.fromObject(existingDecoded);
          lastTimestamp = existingStatus?.timestamp.toIso8601String();
        } on Exception {
          // Ignore invalid startup content and continue watching fresh writes.
        }
      }

      while (!cancelled && !controller.isClosed) {
        if (!await parentDir.exists()) {
          await waitForDirectoryCreation();
          continue;
        }

        await emitIfFresh();
        if (cancelled || controller.isClosed) {
          return;
        }

        await waitForStatusChanges();
      }
    }

    controller = StreamController<DeckBuildStatus>(
      onListen: () {
        unawaited(watchLoop());
      },
      onCancel: () async {
        cancelled = true;
        if (!(activeWait?.isCompleted ?? true)) {
          activeWait!.complete();
        }

        await activeWatch?.cancel();
        activeWatch = null;
      },
    );

    return controller.stream;
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
}

/// Build-side store used by CLI and builder commands.
///
/// This type intentionally stays colocated with [DeckService] because both are
/// file-system storage primitives over the same deck workspace layout, while
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

    final thumbnails = reference.slides.map(
      (slide) => GeneratedAsset.thumbnail(slide.key),
    );

    final allAssets = [...thumbnails, ..._generatedAssets];
    final uniqueAssets = <String, GeneratedAsset>{};
    for (final asset in allAssets) {
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
    final status = DeckBuildStatus(
      phase: phase,
      timestamp: DateTime.now(),
      slideCount: slideCount,
      error: phase == DeckBuildPhase.failure && error != null
          ? DeckBuildError(
              type: error.runtimeType.toString(),
              message: error.toString(),
              stackTrace: stackTrace?.toString(),
            )
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
