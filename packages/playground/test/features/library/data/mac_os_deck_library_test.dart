@TestOn('mac-os')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:playground/core/data/data_sources/security_scoped_file_access.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/core/result.dart';
import 'package:playground/features/library/data/mac_os_deck_library.dart';
import 'package:playground/features/library/domain/deck_library.dart';
import 'package:playground/features/library/domain/saved_deck.dart';

import '../../../helpers/fake_security_scoped_file_access.dart';

/// A 1x1 PNG. Deterministic image bytes, no provider call.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);
final _otherPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
);

const _theme = SavedDeckTheme(
  id: 'technical-paper',
  version: 1,
  density: 'balanced',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late FakeSecurityScopedFileAccess access;
  late MacOsDeckLibrary library;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('deck_library_test');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    access = FakeSecurityScopedFileAccess()
      ..pickedDirectory = SecurityScopedDirectoryReference(
        path: temp.path,
        bookmark: 'directory-bookmark',
      );
    library = MacOsDeckLibrary(fileAccess: access);
  });

  tearDown(() async {
    library.dispose();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  String decks(String name) => p.join(temp.path, 'SuperDeck', name);

  Future<DeckSaveOutcome> saveOk({
    String name = 'My talk',
    String markdown = '# Slide\n',
    List<GeneratedImageAsset> images = const [],
    SavedDeckTheme? theme,
  }) async {
    final result = await library.save(
      name: name,
      markdown: markdown,
      images: images,
      theme: theme,
    );
    switch (result) {
      case Failure(:final error):
        fail('$error');
      case Ok(:final value):
        return value;
    }
  }

  group('save', () {
    test('writes the deck, its artwork and its manifest', () async {
      final outcome = await saveOk(
        markdown: '# Slide\n\n![Hero](hero.png)\n',
        images: [
          GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _png),
        ],
        theme: _theme,
      );

      expect(outcome.isComplete, isTrue);
      expect(outcome.savedAssetKeys, ['hero.png']);
      expect(outcome.ref.name, 'My talk');
      expect(outcome.ref.reference.path, decks('My talk.md'));
      expect(
        await File(decks('My talk.md')).readAsString(),
        '# Slide\n\n![Hero](hero.png)\n',
      );
      expect(
        await File(p.join(decks('My talk.assets'), 'hero.png')).readAsBytes(),
        _png,
      );

      final manifest =
          jsonDecode(await File(decks('My talk.deck.json')).readAsString())
              as Map<String, Object?>;
      expect(manifest['formatVersion'], SavedDeckManifest.currentFormatVersion);
      expect(manifest['name'], 'My talk');
      expect(manifest['markdownFileName'], 'My talk.md');
      expect(manifest['assetsDirectoryName'], 'My talk.assets');
      expect(manifest['assetKeys'], ['hero.png']);
      expect(manifest['theme'], {
        'id': 'technical-paper',
        'version': 1,
        'density': 'balanced',
      });
      expect(DateTime.tryParse('${manifest['savedAt']}'), isNotNull);
    });

    test('a second save keeps the first deck', () async {
      await saveOk(
        markdown: '# First\n',
        images: [
          GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _png),
        ],
      );

      final second = await saveOk(
        markdown: '# Second\n',
        images: [
          GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _otherPng),
        ],
      );

      expect(second.ref.reference.path, decks('My talk 2.md'));
      expect(await File(decks('My talk.md')).readAsString(), '# First\n');
      expect(await File(decks('My talk 2.md')).readAsString(), '# Second\n');
      // Each deck keeps its own artwork under the same key.
      expect(
        await File(p.join(decks('My talk.assets'), 'hero.png')).readAsBytes(),
        _png,
      );
      expect(
        await File(p.join(decks('My talk 2.assets'), 'hero.png')).readAsBytes(),
        _otherPng,
      );
    });

    test('names artwork that had no bytes instead of dropping it', () async {
      final outcome = await saveOk(
        images: const [
          GeneratedImageAsset.failure(assetKey: 'hero.png', error: 'timeout'),
        ],
      );

      expect(outcome.isComplete, isFalse);
      expect(outcome.missingAssetKeys, ['hero.png']);
      expect(outcome.savedAssetKeys, isEmpty);
      expect(await File(decks('My talk.md')).exists(), isTrue);
      expect(await Directory(decks('My talk.assets')).exists(), isFalse);
    });

    test('keeps a name a filesystem can hold', () async {
      final outcome = await saveOk(name: '  ../Café talk: v2/final  ');

      expect(
        p.basename(outcome.ref.reference.path),
        'Café talk v2 final.md',
      );
      expect(await File(outcome.ref.reference.path).exists(), isTrue);
    });

    test('an unnamed deck still gets a file', () async {
      final outcome = await saveOk(name: '   ');

      expect(p.basename(outcome.ref.reference.path), 'Untitled deck.md');
    });

    test('a failed save leaves nothing behind', () async {
      final result = await library.save(
        name: 'Broken',
        markdown: '# Slide\n',
        images: [
          GeneratedImageAsset.success(
            assetKey: '../escape.png',
            bytes: _png,
          ),
        ],
      );

      expect(result, isA<Failure<DeckSaveOutcome>>());
      expect(await File(decks('Broken.md')).exists(), isFalse);
      expect(await File(decks('Broken.deck.json')).exists(), isFalse);
      expect(await Directory(decks('Broken.assets')).exists(), isFalse);
      expect(await File(p.join(temp.path, 'SuperDeck', 'escape.png')).exists(),
          isFalse);
    });

    test('reports a cancelled folder choice instead of guessing', () async {
      access.pickedDirectory = null;
      final fresh = MacOsDeckLibrary(fileAccess: access);
      addTearDown(fresh.dispose);

      final result = await fresh.save(name: 'Talk', markdown: '# Slide\n');

      expect(result, isA<Failure<DeckSaveOutcome>>());
    });
  });

  group('list and open', () {
    test('lists saved decks newest first', () async {
      await saveOk(name: 'Older', markdown: '# Older\n');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await saveOk(name: 'Newer', markdown: '# Newer\n');

      final listed = await library.list();

      expect(listed, isA<Ok<List<SavedDeckRef>>>());
      final refs = (listed as Ok<List<SavedDeckRef>>).value;
      expect(refs.map((ref) => ref.name), ['Newer', 'Older']);
    });

    test('opens a saved deck with its theme', () async {
      final saved = await saveOk(
        markdown: '# Slide\n',
        images: [
          GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _png),
        ],
        theme: _theme,
      );

      final opened = await library.open(saved.ref);

      expect(opened, isA<Ok<SavedDeck>>());
      final deck = (opened as Ok<SavedDeck>).value;
      expect(deck.markdown, '# Slide\n');
      expect(deck.theme, _theme);
      expect(deck.manifest?.assetKeys, ['hero.png']);
    });

    test('a deck whose manifest is unreadable still opens', () async {
      final saved = await saveOk(markdown: '# Slide\n', theme: _theme);
      await File(decks('My talk.deck.json')).writeAsString('{not json');

      final opened = await library.open(saved.ref);
      final listed = await library.list();

      expect((opened as Ok<SavedDeck>).value.markdown, '# Slide\n');
      expect(opened.value.theme, isNull);
      expect(
        (listed as Ok<List<SavedDeckRef>>).value.single.name,
        'My talk',
        reason: 'the filename names a deck whose manifest is gone',
      );
    });

    test('a manifest from a newer format is not guessed at', () async {
      final saved = await saveOk(markdown: '# Slide\n', theme: _theme);
      await File(decks('My talk.deck.json')).writeAsString(
        jsonEncode({
          'formatVersion': SavedDeckManifest.currentFormatVersion + 1,
          'name': 'My talk',
          'savedAt': DateTime.now().toUtc().toIso8601String(),
          'markdownFileName': 'My talk.md',
          'assetsDirectoryName': 'My talk.assets',
          'assetKeys': <String>[],
        }),
      );

      final opened = await library.open(saved.ref);

      expect((opened as Ok<SavedDeck>).value.theme, isNull);
    });

    test('a deck that is gone reports a read failure', () async {
      final saved = await saveOk();
      await File(saved.ref.reference.path).delete();

      expect(await library.open(saved.ref), isA<Failure<SavedDeck>>());
    });

    test('resolves artwork beside the deck and refuses to escape', () async {
      final saved = await saveOk(
        images: [
          GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _png),
        ],
      );

      final resolved = await library.resolveAsset(saved.ref, 'hero.png');
      final missing = await library.resolveAsset(saved.ref, 'absent.png');
      final escape = await library.resolveAsset(saved.ref, '../escape.png');

      expect(
        (resolved as Ok<Uri?>).value,
        File(p.join(decks('My talk.assets'), 'hero.png')).uri,
      );
      expect((missing as Ok<Uri?>).value, isNull);
      expect(escape, isA<Failure<Uri?>>());
    });
  });
}
