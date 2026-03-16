import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

void main() {
  group('DeckBuildStore build-side API', () {
    late Directory tempDir;
    late DeckWorkspace workspace;
    late DeckBuildStore store;

    setUp(() async {
      tempDir = createTempDir();
      workspace = DeckWorkspace(projectDir: tempDir.path);
      store = DeckBuildStore(workspace: workspace);
      await store.initialize();
    });

    test('initialize creates necessary files and directories', () async {
      expect(workspace.deckJson.existsSync(), isTrue);
      expect(workspace.slidesFile.existsSync(), isTrue);
      expect(workspace.assetsDir.existsSync(), isTrue);
      expect(workspace.buildStatusJson.existsSync(), isTrue);
    });

    test('getGeneratedAssetPath returns the correct path', () {
      final asset = GeneratedAsset(
        name: 'test',
        extension: AssetExtension.png,
        type: 'image',
      );

      final path = store.getGeneratedAssetPath(asset);

      expect(path, equals(p.join(workspace.assetsDir.path, 'image_test.png')));
    });

    test('saveBuildStatus writes expected JSON wire format', () async {
      await store.saveBuildStatus(phase: DeckBuildPhase.building);
      var decoded =
          jsonDecode(await workspace.buildStatusJson.readAsString())
              as Map<String, Object?>;
      expect(decoded['status'], 'building');

      await store.saveBuildStatus(phase: DeckBuildPhase.success, slideCount: 5);
      decoded =
          jsonDecode(await workspace.buildStatusJson.readAsString())
              as Map<String, Object?>;
      expect(decoded['status'], 'success');
      expect(decoded['slideCount'], 5);

      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: StateError('boom'),
      );
      decoded =
          jsonDecode(await workspace.buildStatusJson.readAsString())
              as Map<String, Object?>;
      expect(decoded['status'], 'failure');
      expect(decoded['error'], isA<Map<String, Object?>>());
    });

    test('saveReferences saves slide references as arrays', () async {
      await store.saveReferences(const []);

      expect(workspace.deckJson.existsSync(), isTrue);
      expect(workspace.deckFullJson.existsSync(), isTrue);
      expect(workspace.assetsRefJson.existsSync(), isTrue);

      final deckJson =
          jsonDecode(await workspace.deckJson.readAsString()) as List<dynamic>;
      final fullDeckJson =
          jsonDecode(await workspace.deckFullJson.readAsString())
              as List<dynamic>;
      final assetsRefJson = await workspace.assetsRefJson.readAsString();

      expect(deckJson, isEmpty);
      expect(fullDeckJson, isEmpty);
      expect(assetsRefJson, contains('last_modified'));
      expect(assetsRefJson, contains('files'));
    });

    test(
      'saveReferences retains last_modified when asset files are unchanged',
      () async {
        final slides = [Slide(key: 'intro')];

        await store.saveReferences(slides);
        final initialJson =
            jsonDecode(await workspace.assetsRefJson.readAsString())
                as Map<String, dynamic>;
        final initialLastModified = initialJson['last_modified'] as String;

        await Future<void>.delayed(const Duration(milliseconds: 5));

        await store.saveReferences(slides);
        final subsequentJson =
            jsonDecode(await workspace.assetsRefJson.readAsString())
                as Map<String, dynamic>;

        expect(subsequentJson['last_modified'], equals(initialLastModified));
      },
    );

    test(
      'saveReferences excludes runtime thumbnails from generated assets',
      () async {
        await store.saveReferences([Slide(key: 'intro'), Slide(key: 'agenda')]);

        final assetsRef =
            jsonDecode(await workspace.assetsRefJson.readAsString())
                as Map<String, dynamic>;

        expect(assetsRef['files'], isEmpty);
      },
    );

    test(
      'saveReferences writes slide data directly to both JSON files',
      () async {
        final slides = [
          Slide(
            key: 'intro',
            sections: [
              SectionBlock([ContentBlock('# Hello')]),
            ],
          ),
        ];

        await store.saveReferences(slides);

        final deckJson =
            jsonDecode(await workspace.deckJson.readAsString())
                as List<dynamic>;
        final fullDeckJson =
            jsonDecode(await workspace.deckFullJson.readAsString())
                as List<dynamic>;

        expect(deckJson.single, containsPair('key', 'intro'));
        expect(fullDeckJson.single, containsPair('key', 'intro'));
      },
    );

    test('readDeckMarkdown reads the content of the slides file', () async {
      await workspace.slidesFile.writeAsString('# Test slides');

      final content = await store.readDeckMarkdown();

      expect(content, equals('# Test slides'));
    });
  });
}
