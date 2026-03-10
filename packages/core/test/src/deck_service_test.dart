import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import 'helpers/testing_utils.dart';

void main() {
  group('DeckService runtime API', () {
    late MockDeckConfiguration mockConfig;
    late DeckService deckService;
    late DeckConfiguration config;

    setUp(() {
      mockConfig = createMockConfig();
      config = DeckConfiguration(projectDir: mockConfig.projectDir);
      deckService = DeckService(configuration: config);
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

    test(
      'watchBuildStatus emits only fresh statuses and ignores existing file at startup',
      () async {
        await config.superdeckDir.create(recursive: true);
        await config.buildStatusJson.writeAsString(
          '{"status":"building","timestamp":"2026-03-10T10:00:00.000Z"}',
        );

        final events = <DeckBuildStatus>[];
        final subscription = deckService.watchBuildStatus().listen(events.add);
        addTearDown(subscription.cancel);

        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(events, isEmpty);

        await config.buildStatusJson.writeAsString(
          '{"status":"success","timestamp":"2026-03-10T10:00:01.000Z","slideCount":3}',
        );

        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(events, hasLength(1));
        expect(events.first.phase, DeckBuildPhase.success);
        expect(events.first.slideCount, 3);
      },
    );

    test(
      'watchBuildStatus ignores invalid or partial writes and dedupes by timestamp',
      () async {
        await config.superdeckDir.create(recursive: true);

        final events = <DeckBuildStatus>[];
        final subscription = deckService.watchBuildStatus().listen(events.add);
        addTearDown(subscription.cancel);

        await config.buildStatusJson.writeAsString('{"status":"building"');
        await config.buildStatusJson.writeAsString(
          '{"status":"building","timestamp":"not-a-date"}',
        );

        await config.buildStatusJson.writeAsString(
          '{"status":"building","timestamp":"2026-03-10T10:10:00.000Z"}',
        );
        await config.buildStatusJson.writeAsString(
          '{"status":"building","timestamp":"2026-03-10T10:10:00.000Z"}',
        );

        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(events, hasLength(1));
        expect(events.first.phase, DeckBuildPhase.building);
      },
    );

    test(
      'watchBuildStatus recovers when output directory is created after startup',
      () async {
        final events = <DeckBuildStatus>[];
        final subscription = deckService.watchBuildStatus().listen(events.add);
        addTearDown(subscription.cancel);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, isEmpty);

        await config.superdeckDir.create(recursive: true);
        await config.buildStatusJson.writeAsString(
          '{"status":"success","timestamp":"2026-03-10T10:20:00.000Z","slideCount":4}',
        );

        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(events, hasLength(1));
        expect(events.first.phase, DeckBuildPhase.success);
        expect(events.first.slideCount, 4);
      },
    );

    test(
      'watchBuildStatus recovers when nested output directory is created in steps',
      () async {
        final nestedConfig = DeckConfiguration(
          projectDir: mockConfig.projectDir,
          outputDir: 'build/output/slides',
        );
        final nestedDeckService = DeckService(configuration: nestedConfig);
        final events = <DeckBuildStatus>[];
        final subscription = nestedDeckService.watchBuildStatus().listen(
          events.add,
        );
        addTearDown(subscription.cancel);
        final projectDir = mockConfig.projectDir!;

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, isEmpty);

        await Directory(p.join(projectDir, 'build')).create();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await Directory(p.join(projectDir, 'build', 'output')).create();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await nestedConfig.superdeckDir.create();
        await nestedConfig.buildStatusJson.writeAsString(
          '{"status":"success","timestamp":"2026-03-10T10:30:00.000Z","slideCount":2}',
        );

        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(events, hasLength(1));
        expect(events.first.phase, DeckBuildPhase.success);
        expect(events.first.slideCount, 2);
      },
    );
  });

  group('DeckBuildStore build-side API', () {
    late MockDeckConfiguration mockConfig;
    late DeckConfiguration config;
    late DeckBuildStore store;

    setUp(() async {
      mockConfig = createMockConfig();
      config = DeckConfiguration(projectDir: mockConfig.projectDir);
      store = DeckBuildStore(configuration: config);
      await store.initialize();
    });

    test('initialize creates necessary files and directories', () async {
      expect(mockConfig.deckJson.existsSync(), isTrue);
      expect(mockConfig.slidesFile.existsSync(), isTrue);
      expect(mockConfig.assetsDir.existsSync(), isTrue);
      expect(mockConfig.buildStatusJson.existsSync(), isTrue);
    });

    test('getGeneratedAssetPath returns the correct path', () {
      final asset = GeneratedAsset(
        name: 'test',
        extension: AssetExtension.png,
        type: 'image',
      );

      final path = store.getGeneratedAssetPath(asset);

      expect(path, equals(p.join(mockConfig.assetsDir.path, 'image_test.png')));
    });

    test('saveBuildStatus writes expected JSON wire format', () async {
      await store.saveBuildStatus(phase: DeckBuildPhase.building);
      var decoded =
          jsonDecode(await config.buildStatusJson.readAsString())
              as Map<String, Object?>;
      expect(decoded['status'], 'building');

      await store.saveBuildStatus(phase: DeckBuildPhase.success, slideCount: 5);
      decoded =
          jsonDecode(await config.buildStatusJson.readAsString())
              as Map<String, Object?>;
      expect(decoded['status'], 'success');
      expect(decoded['slideCount'], 5);

      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: StateError('boom'),
      );
      decoded =
          jsonDecode(await config.buildStatusJson.readAsString())
              as Map<String, Object?>;
      expect(decoded['status'], 'failure');
      expect(decoded['error'], isA<Map<String, Object?>>());
    });

    test('saveReferences saves deck reference and assets reference', () async {
      await store.saveReferences(Deck(slides: [], configuration: config));

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

        await store.saveReferences(deck);
        final initialJson =
            jsonDecode(await mockConfig.assetsRefJson.readAsString())
                as Map<String, dynamic>;
        final initialLastModified = initialJson['last_modified'] as String;

        // Delay to ensure DateTime.now would differ if rewriting happens.
        await Future<void>.delayed(const Duration(milliseconds: 5));

        await store.saveReferences(deck);
        final subsequentJson =
            jsonDecode(await mockConfig.assetsRefJson.readAsString())
                as Map<String, dynamic>;

        expect(subsequentJson['last_modified'], equals(initialLastModified));
      },
    );

    test('readDeckMarkdown reads the content of the slides file', () async {
      await mockConfig.slidesFile.writeAsString('# Test slides');

      final content = await store.readDeckMarkdown();

      expect(content, equals('# Test slides'));
    });
  });
}
