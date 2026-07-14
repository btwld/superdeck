import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:playground/core/result.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/editor/domain/files/deck_file.dart';
import 'package:playground/features/editor/domain/files/deck_file_repository.dart';
import 'package:playground/features/editor/domain/files/deck_image_manifest.dart';

/// In-memory [DeckFileRepository] with controllable reads, writes, and watch
/// events for synchronization and bootstrap tests.
class FakeDeckFileRepository implements DeckFileRepository {
  final Map<String, String> files = {};
  final Map<String, List<int>> assets = {};
  final Map<String, DeckImageManifest> imageManifests = {};
  final Map<String, StreamController<DeckFileEvent>> _watchers = {};
  final Map<DeckFileReference, DeckFileReference> accessResults = {};
  final List<DeckFileReference> accessStarts = [];
  final List<DeckFileReference> accessStops = [];
  final Map<String, Completer<void>> readGates = {};
  final Map<String, Completer<void>> readStarted = {};
  final Map<String, Completer<void>> writeGates = {};
  final Map<String, Completer<void>> writeStarted = {};
  final Set<String> failReads = {};

  DeckFileReference? rememberedDeck;
  DeckFileReference? pickResult;
  Object? pickError;
  Object? accessError;
  Completer<void>? initialLoadGate;
  Completer<void>? initialLoadStarted;
  String decksDirectory = '/decks';
  bool failWrites = false;
  bool failRememberWrites = false;
  int pickCount = 0;
  int watchCount = 0;
  int writeCount = 0;

  @override
  void dispose() {}

  @override
  Future<Result<DeckFileSnapshot>> loadInitialDeck({
    required String starterMarkdown,
  }) async {
    initialLoadStarted?.complete();
    await initialLoadGate?.future;

    final remembered = rememberedDeck;
    if (remembered != null) {
      final restored = await _loadCandidate(remembered);
      if (restored case Ok()) return restored;
    }

    final path = p.join(decksDirectory, 'untitled.md');
    if (files.containsKey(path)) {
      try {
        return Result.ok(
          DeckFileSnapshot(
            reference: DeckFileReference(path: path),
            markdown: await _read(path),
          ),
        );
      } catch (error) {
        return Result.error(DeckFileReadException(path, error));
      }
    }

    if (failWrites) {
      return Result.error(
        DeckFileWriteException(path, Exception('write failed')),
      );
    }
    files[path] = starterMarkdown;
    writeCount++;
    final snapshot = DeckFileSnapshot(
      reference: DeckFileReference(path: path),
      markdown: starterMarkdown,
    );
    _remember(snapshot.reference);
    return Result.ok(snapshot);
  }

  @override
  Future<Result<DeckFileSnapshot?>> pickDeck() async {
    pickCount++;
    final error = pickError;
    if (error != null) {
      return Result.error(DeckFileAccessException('<selected deck>', error));
    }
    final picked = pickResult;
    if (picked == null) return const Result.ok(null);

    final loaded = await _loadCandidate(picked);
    return switch (loaded) {
      Ok(:final value) => Result.ok(value),
      Failure(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<DeckFileSnapshot>> createDeck({
    required String name,
    required String markdown,
  }) async {
    final bareName = p.basename(name.trim());
    if (bareName.isEmpty) {
      return Result.error(
        DeckFileWriteException(
          name,
          ArgumentError('Deck name must not be empty'),
        ),
      );
    }
    final fileName = p.extension(bareName).toLowerCase() == '.md'
        ? bareName
        : '$bareName.md';
    final path = p.join(decksDirectory, fileName);
    if (files.containsKey(path)) {
      return Result.error(DeckNameCollisionException(fileName));
    }
    if (failWrites) {
      return Result.error(
        DeckFileWriteException(path, Exception('write failed')),
      );
    }
    files[path] = markdown;
    writeCount++;
    final snapshot = DeckFileSnapshot(
      reference: DeckFileReference(path: path),
      markdown: markdown,
    );
    _remember(snapshot.reference);
    return Result.ok(snapshot);
  }

  @override
  Future<Result<DeckFileSnapshot>> createGeneratedDeck({
    required String name,
    required String markdown,
    required List<GeneratedImageAsset> images,
  }) async {
    final base = _topicSlug(name);
    var suffix = 1;
    late String path;
    while (true) {
      final stem = suffix == 1 ? base : '$base-$suffix';
      path = p.join(decksDirectory, '$stem.md');
      if (!files.containsKey(path) &&
          !imageManifests.containsKey(deckAssetsDirectoryPath(path))) {
        break;
      }
      suffix++;
    }
    if (failWrites) {
      return Result.error(
        DeckFileWriteException(path, Exception('write failed')),
      );
    }

    files[path] = markdown;
    final assetsPath = deckAssetsDirectoryPath(path);
    imageManifests[assetsPath] = DeckImageManifest.fromAssets(images);
    for (final image in images) {
      final bytes = image.bytes;
      if (bytes != null) {
        assets[p.join(assetsPath, image.assetKey)] = bytes;
      }
    }
    writeCount++;
    final snapshot = DeckFileSnapshot(
      reference: DeckFileReference(path: path),
      markdown: markdown,
    );
    _remember(snapshot.reference);
    return Result.ok(snapshot);
  }

  @override
  Future<Result<DeckImageManifest?>> loadImageManifest(
    DeckFileReference reference,
  ) async {
    return Result.ok(imageManifests[deckAssetsDirectoryPath(reference.path)]);
  }

  @override
  Future<Result<void>> updateGeneratedImage(
    DeckFileReference reference,
    GeneratedImageAsset image,
  ) async {
    if (failWrites) {
      return Result.error(
        DeckFileWriteException(reference.path, Exception('write failed')),
      );
    }
    final assetsPath = deckAssetsDirectoryPath(reference.path);
    final manifest = imageManifests[assetsPath];
    if (manifest == null) {
      return Result.error(
        DeckFileWriteException(reference.path, Exception('missing manifest')),
      );
    }
    try {
      imageManifests[assetsPath] = manifest.replace(
        DeckImageManifestEntry.fromAsset(image),
      );
      final bytes = image.bytes;
      if (bytes != null) {
        assets[p.join(assetsPath, image.assetKey)] = bytes;
      }
      writeCount++;
      return const Result.ok(null);
    } catch (error) {
      return Result.error(DeckFileWriteException(reference.path, error));
    }
  }

  @override
  Future<Result<void>> writeDeck(
    DeckFileReference reference,
    String markdown,
  ) async {
    writeStarted.remove(reference.path)?.complete();
    await writeGates[reference.path]?.future;
    if (failWrites || !files.containsKey(reference.path)) {
      return Result.error(
        DeckFileWriteException(reference.path, Exception('write failed')),
      );
    }
    writeCount++;
    files[reference.path] = markdown;
    return const Result.ok(null);
  }

  @override
  Stream<DeckFileEvent> watchDeck(DeckFileReference reference) {
    watchCount++;
    return _watchers
        .putIfAbsent(
          reference.path,
          () => StreamController<DeckFileEvent>.broadcast(),
        )
        .stream;
  }

  @override
  Future<Result<void>> releaseDeck(DeckFileReference reference) async {
    accessStops.add(reference);
    return const Result.ok(null);
  }

  /// Simulates an external rewrite and emits the content read by the watcher.
  Future<void> externalWrite(String path, String markdown) async {
    files[path] = markdown;
    final watcher = _watchers[path];
    if (watcher != null) {
      try {
        watcher.add(DeckFileChanged(await _read(path)));
      } catch (_) {
        watcher.add(const DeckFileUnavailable());
      }
    }
    await _settle();
  }

  /// Simulates deletion or a move of the active file.
  Future<void> externalDelete(String path) async {
    files.remove(path);
    _watchers[path]?.add(const DeckFileUnavailable());
    await _settle();
  }

  Future<Result<DeckFileSnapshot>> _loadCandidate(
    DeckFileReference candidate,
  ) async {
    accessStarts.add(candidate);
    final accessFailure = accessError;
    if (accessFailure != null) {
      await releaseDeck(candidate);
      return Result.error(
        DeckFileAccessException(candidate.path, accessFailure),
      );
    }

    final reference = accessResults[candidate] ?? candidate;
    try {
      final snapshot = DeckFileSnapshot(
        reference: reference,
        markdown: await _read(reference.path),
      );
      _remember(reference);
      return Result.ok(snapshot);
    } catch (error) {
      await releaseDeck(reference);
      return Result.error(DeckFileReadException(reference.path, error));
    }
  }

  Future<String> _read(String path) async {
    readStarted.remove(path)?.complete();
    await readGates[path]?.future;
    if (failReads.contains(path)) throw Exception('read failed');
    final markdown = files[path];
    if (markdown == null) throw Exception('missing');
    return markdown;
  }

  void _remember(DeckFileReference reference) {
    if (!failRememberWrites) rememberedDeck = reference;
  }

  String _topicSlug(String name) {
    final value = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    return value.isEmpty ? 'untitled' : value;
  }

  Future<void> _settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));
}
