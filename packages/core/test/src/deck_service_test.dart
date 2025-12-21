import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import 'helpers/testing_utils.dart';

void main() {
  group('DeckService with LocalDeckReader', () {
    late MockDeckConfiguration mockConfig;
    late DeckService deckService;

    setUp(() {
      mockConfig = createMockConfig();
      final config = DeckConfiguration(projectDir: mockConfig.projectDir);
      deckService = DeckService(configuration: config);
    });

    test(
      'initialize creates necessary files and directories for LocalDeckReader',
      () async {
        await deckService.initialize();

        expect(mockConfig.deckJson.existsSync(), isTrue);
        expect(mockConfig.slidesFile.existsSync(), isTrue);
        expect(mockConfig.assetsDir.existsSync(), isTrue);
      },
    );

    test('getGeneratedAssetPath returns the correct path', () {
      final asset = GeneratedAsset(
        name: 'test',
        extension: AssetExtension.png,
        type: 'image',
      );

      final path = deckService.getGeneratedAssetPath(asset);

      expect(path, equals(p.join(mockConfig.assetsDir.path, 'image_test.png')));
    });

    test('loadDeck loads deck from file', () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString(
        '{"slides":[],"configuration":{}}',
      );

      final reference = await deckService.loadDeck();

      expect(reference, isA<Deck>());
      expect(reference.slides, isEmpty);
    });

    test('loadDeck returns error slide when file is invalid', () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString('invalid json');

      final reference = await deckService.loadDeck();

      expect(reference, isA<Deck>());
      expect(reference.slides, hasLength(1));
      expect(reference.slides.first.key, equals('error'));
    });

    test('loadDeckStream emits deck', () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString(
        '{"slides":[],"configuration":{}}',
      );

      final stream = deckService.loadDeckStream();

      // Take only the first emission and cancel to prevent file watcher errors
      await expectLater(stream.take(1), emits(isA<Deck>()));
    });
  });

  group('DeckService with LocalDeckReader (FileSystem features)', () {
    late MockDeckConfiguration mockConfig;
    late DeckConfiguration config;
    late DeckService deckService;

    setUp(() async {
      mockConfig = createMockConfig();
      config = DeckConfiguration(projectDir: mockConfig.projectDir);
      deckService = DeckService(configuration: config);

      // Initialize the deckService for each test
      await deckService.initialize();
    });

    test(
      'initialize creates necessary files and directories for LocalDeckReader',
      () async {
        await deckService.initialize();

        expect(mockConfig.deckJson.existsSync(), isTrue);
        expect(mockConfig.slidesFile.existsSync(), isTrue);
        expect(mockConfig.assetsDir.existsSync(), isTrue);
      },
    );

    test('getGeneratedAssetPath adds asset to internal list', () async {
      // Create the asset directory first
      await mockConfig.assetsDir.create(recursive: true);

      final asset = GeneratedAsset(
        name: 'test',
        extension: AssetExtension.png,
        type: 'image',
      );

      final path = deckService.getGeneratedAssetPath(asset);
      expect(path, equals(p.join(mockConfig.assetsDir.path, 'image_test.png')));

      // Save references to ensure the asset is processed
      await deckService.saveReferences(Deck(slides: [], configuration: config));

      // Now verify the assets_ref.json file exists
      expect(mockConfig.assetsRefJson.existsSync(), isTrue);

      // Read the content to check if it contains our asset filename
      final content = await mockConfig.assetsRefJson.readAsString();
      expect(content, contains('image_test.png'));
    });

    test('saveReferences saves deck reference and assets reference', () async {
      await deckService.saveReferences(Deck(slides: [], configuration: config));

      expect(mockConfig.deckJson.existsSync(), isTrue);
      expect(mockConfig.assetsRefJson.existsSync(), isTrue);

      final deckJson = await mockConfig.deckJson.readAsString();
      final assetsRefJson = await mockConfig.assetsRefJson.readAsString();

      expect(deckJson, contains('slides'));
      expect(assetsRefJson, contains('last_modified'));
      expect(assetsRefJson, contains('files'));
    });

    test(
      'saveReferences retains last_modified when asset files are unchanged',
      () async {
        final deck = Deck(
          slides: [const Slide(key: 'intro')],
          configuration: config,
        );

        await deckService.saveReferences(deck);
        final initialJson =
            jsonDecode(await mockConfig.assetsRefJson.readAsString())
                as Map<String, dynamic>;
        final initialLastModified =
            initialJson['last_modified'] as String;

        // Delay to ensure DateTime.now would differ if rewriting happens.
        await Future<void>.delayed(const Duration(milliseconds: 5));

        await deckService.saveReferences(deck);
        final subsequentJson =
            jsonDecode(await mockConfig.assetsRefJson.readAsString())
                as Map<String, dynamic>;

        expect(
          subsequentJson['last_modified'],
          equals(initialLastModified),
        );
      },
    );

    test('readDeckMarkdown reads the content of the slides file', () async {
      await mockConfig.slidesFile.writeAsString('# Test slides');

      final content = await deckService.readDeckMarkdown();

      expect(content, equals('# Test slides'));
    });

    test(
      'loadDeckStream emits a reference when file changes',
      () async {
        final streamController = StreamController<Deck>();
        final future = deckService.loadDeckStream().take(2).toList();

        // Wait a bit to ensure the stream is listening
        await Future.delayed(Duration(milliseconds: 100));

        // Modify the deck.json file to trigger a new emission
        await mockConfig.deckJson.writeAsString(
          '{"slides":[],"configuration":{}}',
        );

        final results = await future.timeout(
          Duration(seconds: 2),
          onTimeout: () => [],
        );

        // Should receive at least 1 event (the initial state)
        expect(results, isNotEmpty);

        streamController.close();
      },
      skip:
          'This test is flaky due to file watching behavior and might need platform-specific adjustments',
    );
  });
}
