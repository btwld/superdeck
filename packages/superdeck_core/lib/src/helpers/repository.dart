import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

import 'pretty_json.dart';

abstract interface class PresentationRepository {
  final DeckConfiguration configuration;

  PresentationRepository(this.configuration);

  Future<void> initialize();

  Future<DeckReference> loadDeckReference();

  Stream<DeckReference> loadDeckReferenceStream();

  String getAssetPath(Asset asset) {
    return p.join(configuration.assetsDir.path, asset.fileName);
  }

  Future<String> readAssetByPath(String path);
}

class LocalPresentationRepository extends PresentationRepository {
  LocalPresentationRepository(super.configuration);

  Future<String> fileReader(String path) async {
    return File(path).readAsString();
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<String> readAssetByPath(String path) async {
    return fileReader(path);
  }

  @override
  Future<DeckReference> loadDeckReference() async {
    try {
      // if (!await configuration.deckJson.exists()) {
      //   throw Exception('Deck reference file not found');
      // }
      final content = await fileReader(configuration.deckJson.path);
      return DeckReferenceMapper.fromJson(content);
    } on Exception catch (e) {
      return DeckReference(
        slides: [
          ErrorSlide(
            title: 'Superdeck reference error',
            message: configuration.deckJson.path,
            error: e,
          ),
        ],
        config: configuration,
      );
    }
  }

  @override
  Stream<DeckReference> loadDeckReferenceStream() {
    return Stream.fromFuture(loadDeckReference());
  }
}

class FileSystemPresentationRepository extends LocalPresentationRepository {
  FileSystemPresentationRepository(super.configuration);

  final List<Asset> _generatedAssets = [];

  @override
  Future<void> initialize() async {
    if (!await configuration.assetsDir.exists()) {
      await configuration.assetsDir.create(recursive: true);
    }

    if (!await configuration.deckJson.exists()) {
      await configuration.deckJson.writeAsString('{}');
    }

    if (!await configuration.slidesFile.exists()) {
      await configuration.slidesFile.writeAsString('');
    }

    await super.initialize();
  }

  @override
  String getAssetPath(Asset asset) {
    _generatedAssets.add(asset);
    return super.getAssetPath(asset);
  }

  Future<void> saveReferences(
    DeckReference reference,
  ) async {
    // Save deck reference
    final deckJson = prettyJson(reference.toMap());
    await configuration.deckJson.writeAsString(deckJson);

    // Generate the asset references for each slide thumbnail
    final thumbnails =
        reference.slides.map((slide) => Asset.thumbnail(slide.key));

    // Combine thumbnail and generated assets
    final allAssets = [
      ...thumbnails,
      ..._generatedAssets,
    ];

    // Map asset references to their corresponding file paths
    final assetFiles = allAssets.map(
        (asset) => File(p.join(configuration.assetsDir.path, asset.fileName)));

    final assetPaths = assetFiles.map((file) => file.path).toList();

    // Create asset references
    final assetReferences = allAssets
        .map((asset) => AssetReference(
              lastModified: DateTime.now(),
              assetId: asset.id,
              type: asset.type,
              path: p.join(configuration.assetsDir.path, asset.fileName),
            ))
        .toList();

    final assetsManifest = AssetManifest(
      lastModified: DateTime.now(),
      assets: assetReferences,
    );

    // Save the assets manifest
    final assetsJson = prettyJson(assetsManifest.toMap());
    await configuration.assetsRefJson.writeAsString(assetsJson);

    await _cleanupAssets(assetPaths);
  }

  Future<String> readDeckMarkdown() async {
    return await configuration.slidesFile.readAsString();
  }

  Future<void> _cleanupAssets(
    List<String> referencedFilePaths,
  ) async {
    final existingFiles = await configuration.assetsDir
        .list(recursive: true)
        .where((e) => e is File)
        .map((e) => e as File)
        .toList();

    final referencedFiles = referencedFilePaths.toSet();

    await Future.forEach(existingFiles, (File file) async {
      if (!referencedFiles.contains(file.path)) {
        await file.delete();
      }
    });
  }

  @override
  Stream<DeckReference> loadDeckReferenceStream() async* {
    // Emit the current reference immediately.
    yield await loadDeckReference();

    // For each file modification event, emit a new deck reference.
    await for (final _
        in configuration.deckJson.watch(events: FileSystemEvent.modify)) {
      yield await loadDeckReference();
    }
  }
}
