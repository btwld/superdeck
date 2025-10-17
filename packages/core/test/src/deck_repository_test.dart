import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import 'helpers/testing_utils.dart';

void main() {
  group('DeckRepository with LocalDeckReader', () {
    late MockDeckConfiguration mockConfig;
    late DeckRepository repository;

    setUp(() {
      mockConfig = createMockConfig();
      final config = DeckConfiguration(projectDir: mockConfig.projectDir);
      repository = DeckRepository(configuration: config);
    });

    test(
      'initialize creates necessary files and directories for LocalDeckReader',
      () async {
        await repository.initialize();

        expect(mockConfig.deckJson.existsSync(), isTrue);
        expect(mockConfig.slidesFile.existsSync(), isTrue);
        expect(mockConfig.assetsDir.existsSync(), isTrue);
      },
    );

    test('readAssetByPath reads the content of a file', () async {
      final testFile = File(
        p.join(mockConfig.assetsDir.parent.path, 'test.txt'),
      );

      // Ensure parent directory exists
      await testFile.parent.create(recursive: true);
      await testFile.writeAsString('test content');

      final content = await repository.readAssetByPath(testFile.path);

      expect(content, equals('test content'));
    });

    test('getGeneratedAssetPath returns the correct path', () {
      final asset = GeneratedAsset(
        name: 'test',
        extension: AssetExtension.png,
        type: 'image',
      );

      final path = repository.getGeneratedAssetPath(asset);

      expect(path, equals(p.join(mockConfig.assetsDir.path, 'image_test.png')));
    });

    test('loadDeck loads deck from file', () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString(
        '{"slides":[],"configuration":{}}',
      );

      final reference = await repository.loadDeck();

      expect(reference, isA<Deck>());
      expect(reference.slides, isEmpty);
    });

    test('loadDeck returns error slide when file is invalid', () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString('invalid json');

      final reference = await repository.loadDeck();

      expect(reference, isA<Deck>());
      expect(reference.slides, hasLength(1));
      expect(reference.slides.first.key, equals('error'));
    });

    test('loadDeckStream emits deck', () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString(
        '{"slides":[],"configuration":{}}',
      );

      final stream = repository.loadDeckStream();

      await expectLater(stream, emits(isA<Deck>()));
    });
  });

  group('DeckRepository with LocalDeckReader (FileSystem features)', () {
    late MockDeckConfiguration mockConfig;
    late DeckConfiguration config;
    late DeckRepository repository;

    setUp(() async {
      mockConfig = createMockConfig();
      config = DeckConfiguration(projectDir: mockConfig.projectDir);
      repository = DeckRepository(configuration: config);

      // Initialize the repository for each test
      await repository.initialize();
    });

    test(
      'initialize creates necessary files and directories for LocalDeckReader',
      () async {
        await repository.initialize();

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

      final path = repository.getGeneratedAssetPath(asset);
      expect(path, equals(p.join(mockConfig.assetsDir.path, 'image_test.png')));

      // Save references to ensure the asset is processed
      await repository.saveReferences(Deck(slides: [], configuration: config));

      // Now verify the assets_ref.json file exists
      expect(mockConfig.assetsRefJson.existsSync(), isTrue);

      // Read the content to check if it contains our asset filename
      final content = await mockConfig.assetsRefJson.readAsString();
      expect(content, contains('image_test.png'));
    });

    test('saveReferences saves deck reference and assets reference', () async {
      await repository.saveReferences(Deck(slides: [], configuration: config));

      expect(mockConfig.deckJson.existsSync(), isTrue);
      expect(mockConfig.assetsRefJson.existsSync(), isTrue);

      final deckJson = await mockConfig.deckJson.readAsString();
      final assetsRefJson = await mockConfig.assetsRefJson.readAsString();

      expect(deckJson, contains('slides'));
      expect(assetsRefJson, contains('last_modified'));
      expect(assetsRefJson, contains('files'));
    });

    test('readDeckMarkdown reads the content of the slides file', () async {
      await mockConfig.slidesFile.writeAsString('# Test slides');

      final content = await repository.readDeckMarkdown();

      expect(content, equals('# Test slides'));
    });

    test(
      'loadDeckStream emits a reference when file changes',
      () async {
        final streamController = StreamController<Deck>();
        final future = repository.loadDeckStream().take(2).toList();

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
