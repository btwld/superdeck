import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

Directory createTempDir() {
  final dir = Directory.systemTemp.createTempSync('superdeck_test_');
  return dir;
}

class MockDeckConfiguration extends DeckConfiguration {
  final Directory tempDir;

  MockDeckConfiguration(this.tempDir);

  @override
  File get deckJson => File(p.join(tempDir.path, 'deck.json'));

  @override
  File get slidesFile => File(p.join(tempDir.path, 'slides.md'));

  @override
  Directory get assetsDir => Directory(p.join(tempDir.path, 'assets'));

  @override
  File get assetsRefJson => File(p.join(tempDir.path, 'assets_ref.json'));
}

void main() {
  group('LocalPresentationRepository', () {
    late Directory tempDir;
    late DeckConfiguration mockConfig;
    late LocalPresentationRepository repository;

    setUp(() {
      tempDir = createTempDir();
      mockConfig = MockDeckConfiguration(tempDir);
      repository = LocalPresentationRepository(mockConfig);
    });

    test('initialize does not create any files or directories', () async {
      await repository.initialize();

      expect(mockConfig.deckJson.existsSync(), isFalse);
      expect(mockConfig.slidesFile.existsSync(), isFalse);
      expect(mockConfig.assetsDir.existsSync(), isFalse);
    });

    test('readAssetByPath reads the content of a file', () async {
      final testFile = File(p.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      final content = await repository.readAssetByPath(testFile.path);

      expect(content, equals('test content'));
    });

    test('getAssetPath returns the correct path', () {
      final asset = Asset(
        id: 'test',
        extension: AssetExtension.png,
        type: AssetType.image,
      );

      final path = repository.getAssetPath(asset);

      expect(path, equals(p.join(mockConfig.assetsDir.path, 'image_test.png')));
    });

    test('loadDeckReference loads deck reference from file', () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString('{"slides":[],"config":{}}');

      final reference = await repository.loadDeckReference();

      expect(reference, isA<DeckReference>());
      expect(reference.slides, isEmpty);
    });

    test('loadDeckReference returns error slide when file is invalid',
        () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString('invalid json');

      final reference = await repository.loadDeckReference();

      expect(reference, isA<DeckReference>());
      expect(reference.slides, hasLength(1));
      expect(reference.slides.first, isA<ErrorSlide>());
    });

    test('loadDeckReferenceStream emits deck reference', () async {
      await mockConfig.deckJson.parent.create(recursive: true);
      await mockConfig.deckJson.writeAsString('{"slides":[],"config":{}}');

      final stream = repository.loadDeckReferenceStream();

      await expectLater(
        stream,
        emits(isA<DeckReference>()),
      );
    });
  });

  group('FileSystemPresentationRepository', () {
    late Directory tempDir;
    late DeckConfiguration mockConfig;
    late FileSystemPresentationRepository repository;

    setUp(() async {
      tempDir = createTempDir();
      mockConfig = MockDeckConfiguration(tempDir);
      repository = FileSystemPresentationRepository(mockConfig);

      // Initialize the repository for each test
      await repository.initialize();
    });

    test('initialize creates necessary files and directories', () async {
      expect(mockConfig.deckJson.existsSync(), isTrue);
      expect(mockConfig.slidesFile.existsSync(), isTrue);
      expect(mockConfig.assetsDir.existsSync(), isTrue);
    });

    test('getAssetPath adds asset to internal list', () async {
      // Create the asset directory first
      await mockConfig.assetsDir.create(recursive: true);

      final asset = Asset(
        id: 'test',
        extension: AssetExtension.png,
        type: AssetType.image,
      );

      final path = repository.getAssetPath(asset);
      expect(path, equals(p.join(mockConfig.assetsDir.path, 'image_test.png')));

      // Save references to ensure the asset is processed
      await repository.saveReferences(
        DeckReference(slides: [], config: mockConfig),
      );

      // Now verify the assets_ref.json file exists
      expect(mockConfig.assetsRefJson.existsSync(), isTrue);

      // Read the content to check if it contains our asset filename
      final content = await mockConfig.assetsRefJson.readAsString();
      expect(content, contains('image_test.png'));
    });

    test('saveReferences saves deck reference and assets reference', () async {
      await repository.saveReferences(
        DeckReference(slides: [], config: mockConfig),
      );

      expect(mockConfig.deckJson.existsSync(), isTrue);
      expect(mockConfig.assetsRefJson.existsSync(), isTrue);

      final deckJson = await mockConfig.deckJson.readAsString();
      final assetsRefJson = await mockConfig.assetsRefJson.readAsString();

      expect(deckJson, contains('slides'));
      expect(assetsRefJson, contains('last_modified'));
      expect(assetsRefJson, contains('assets'));
    });

    test('readDeckMarkdown reads the content of the slides file', () async {
      await mockConfig.slidesFile.writeAsString('# Test slides');

      final content = await repository.readDeckMarkdown();

      expect(content, equals('# Test slides'));
    });

    test('loadDeckReferenceStream emits a reference when file changes',
        () async {
      final streamController = StreamController<DeckReference>();
      final future = repository.loadDeckReferenceStream().take(2).toList();

      // Wait a bit to ensure the stream is listening
      await Future.delayed(Duration(milliseconds: 100));

      // Modify the deck.json file to trigger a new emission
      await mockConfig.deckJson.writeAsString('{"slides":[],"config":{}}');

      final results =
          await future.timeout(Duration(seconds: 2), onTimeout: () => []);

      // Should receive at least 1 event (the initial state)
      expect(results, isNotEmpty);

      streamController.close();
    },
        skip:
            'This test is flaky due to file watching behavior and might need platform-specific adjustments');
  });
}
