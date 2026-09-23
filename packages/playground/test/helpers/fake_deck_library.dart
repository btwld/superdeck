import 'package:playground/core/data/data_sources/deck_file.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/core/result.dart';
import 'package:playground/features/library/domain/deck_library.dart';
import 'package:playground/features/library/domain/saved_deck.dart';

/// In-memory [DeckLibrary] for tests that need saved decks without a disk.
class FakeDeckLibrary implements DeckLibrary {
  final Map<String, String> markdown = {};
  final Map<String, Map<String, List<int>>> assets = {};
  final Map<String, SavedDeckTheme?> themes = {};
  final List<SavedDeckRef> saved = [];

  @override
  bool canSave = true;

  Exception? saveError;
  Exception? openError;
  Exception? listError;
  int saveCount = 0;
  int openCount = 0;

  /// Held by tests that need [save], [open], or [list] to finish in an
  /// order the controller does not choose.
  Future<void> Function()? beforeSave;
  Future<void> Function()? beforeOpen;
  Future<void> Function()? beforeList;

  @override
  Future<Result<DeckSaveOutcome>> save({
    required String name,
    required String markdown,
    List<GeneratedImageAsset> images = const [],
    SavedDeckTheme? theme,
  }) async {
    saveCount++;
    final saveHook = beforeSave;
    if (saveHook != null) await saveHook();
    final error = saveError;
    if (error != null) return Result.error(error);

    final stem = saved.any((ref) => ref.name == name)
        ? '$name ${saved.where((ref) => ref.name.startsWith(name)).length + 1}'
        : name;
    final path = '/decks/$stem.md';
    final ref = SavedDeckRef(
      reference: DeckFileReference(path: path),
      name: stem,
      savedAt: DateTime.now(),
    );
    this.markdown[path] = markdown;
    themes[path] = theme;
    final written = <String>[];
    final missing = <String>[];
    for (final image in images) {
      final bytes = image.bytes;
      if (bytes == null || bytes.isEmpty) {
        missing.add(image.assetKey);
        continue;
      }
      (assets[path] ??= {})[image.assetKey] = bytes;
      written.add(image.assetKey);
    }
    saved.insert(0, ref);

    return Result.ok(
      DeckSaveOutcome(
        ref: ref,
        savedAssetKeys: written,
        missingAssetKeys: missing,
      ),
    );
  }

  @override
  Future<Result<List<SavedDeckRef>>> list() async {
    final listHook = beforeList;
    if (listHook != null) await listHook();
    final error = listError;

    return error != null ? Result.error(error) : Result.ok(List.of(saved));
  }

  @override
  Future<Result<SavedDeck>> open(SavedDeckRef ref) async {
    openCount++;
    final openHook = beforeOpen;
    if (openHook != null) await openHook();
    final error = openError;
    if (error != null) return Result.error(error);
    final content = markdown[ref.reference.path];
    if (content == null) {
      return Result.error(
        DeckFileReadException(ref.reference.path, StateError('missing')),
      );
    }

    return Result.ok(
      SavedDeck(
        ref: ref,
        markdown: content,
        manifest: SavedDeckManifest(
          formatVersion: SavedDeckManifest.currentFormatVersion,
          name: ref.name,
          savedAt: ref.savedAt,
          markdownFileName: '${ref.name}.md',
          assetsDirectoryName: '${ref.name}.assets',
          assetKeys: assets[ref.reference.path]?.keys.toList() ?? const [],
          theme: themes[ref.reference.path],
        ),
      ),
    );
  }

  @override
  Future<Result<Uri?>> resolveAsset(SavedDeckRef ref, String assetKey) async {
    final bytes = assets[ref.reference.path]?[assetKey];

    return Result.ok(
      bytes == null ? null : Uri.file('${ref.reference.path}.assets/$assetKey'),
    );
  }

  @override
  void dispose() {}
}
