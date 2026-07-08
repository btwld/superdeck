import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck/src/deck/default_deck_setup.dart';
import 'package:superdeck/src/deck/loaders/bundled_deck_loader.dart';
import 'package:superdeck/src/deck/loaders/file_deck_loader.dart';
import 'package:superdeck_core/superdeck_core.dart';

void _disposeSetup(({DeckLoader loader, DeckWorkspace workspace}) setup) {
  final subscription = setup.loader.load().listen((_) {});
  addTearDown(() async {
    await setup.loader.dispose();
    await subscription.cancel();
  });
}

void main() {
  group('findProjectRoot', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'superdeck_default_deck_setup_test_',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns nearest ancestor containing pubspec.yaml', () async {
      final projectDir = Directory(p.join(tempDir.path, 'project'));
      final nestedDir = Directory(p.join(projectDir.path, 'lib', 'src'));
      await nestedDir.create(recursive: true);
      await File(
        p.join(projectDir.path, 'pubspec.yaml'),
      ).writeAsString('name: project\n');

      final root = findProjectRoot(nestedDir);

      expect(root?.path, projectDir.absolute.path);
    });

    test(
      'prefers nearest pubspec.yaml when multiple ancestors qualify',
      () async {
        final projectDir = Directory(p.join(tempDir.path, 'project'));
        final nestedDir = Directory(p.join(projectDir.path, 'lib', 'src'));
        await nestedDir.create(recursive: true);
        await File(
          p.join(tempDir.path, 'pubspec.yaml'),
        ).writeAsString('name: outer\n');
        await File(
          p.join(projectDir.path, 'pubspec.yaml'),
        ).writeAsString('name: project\n');

        final root = findProjectRoot(nestedDir);

        expect(root?.path, projectDir.absolute.path);
      },
    );

    test('returns null when no ancestor contains pubspec.yaml', () async {
      final nestedDir = Directory(p.join(tempDir.path, 'project', 'lib'));
      await nestedDir.create(recursive: true);

      final root = findProjectRoot(nestedDir);

      expect(root, isNull);
    });
  });

  group('resolveDeckSetup', () {
    test('uses file loader for explicit workspace in debug IO runtimes', () {
      final workspace = DeckWorkspace(projectDir: '/explicit/root');
      var findRootCalled = false;

      final setup = resolveDeckSetup(
        workspace: workspace,
        canRunProcess: true,
        findRoot: (_) {
          findRootCalled = true;

          return null;
        },
      );
      _disposeSetup(setup);

      final loader = setup.loader;
      expect(loader, isA<FileDeckLoader>());
      expect((loader as FileDeckLoader).workspace, same(workspace));
      expect(setup.workspace, same(workspace));
      expect(findRootCalled, isFalse);
    });

    test(
      'uses bundled loader for explicit workspace when IO is unavailable',
      () {
        final workspace = DeckWorkspace(projectDir: '/explicit/root');
        var findRootCalled = false;

        final setup = resolveDeckSetup(
          workspace: workspace,
          canRunProcess: false,
          findRoot: (_) {
            findRootCalled = true;

            return null;
          },
        );
        _disposeSetup(setup);

        final loader = setup.loader;
        expect(loader, isA<BundledDeckLoader>());
        expect((loader as BundledDeckLoader).workspace, same(workspace));
        expect(setup.workspace, same(workspace));
        expect(findRootCalled, isFalse);
      },
    );

    test('uses file loader for discovered project root', () {
      final setup = resolveDeckSetup(
        canRunProcess: true,
        findRoot: (_) => Directory('/found/root'),
      );
      _disposeSetup(setup);

      final loader = setup.loader;
      expect(loader, isA<FileDeckLoader>());
      expect(setup.workspace, DeckWorkspace(projectDir: '/found/root'));
      expect((loader as FileDeckLoader).workspace, same(setup.workspace));
    });

    test(
      'falls back to bundled loader when no project root is discoverable',
      () {
        final setup = resolveDeckSetup(
          canRunProcess: true,
          findRoot: (_) => null,
        );
        _disposeSetup(setup);

        final loader = setup.loader;
        expect(loader, isA<BundledDeckLoader>());
        expect(setup.workspace, DeckWorkspace());
        expect((loader as BundledDeckLoader).workspace, same(setup.workspace));
      },
    );

    test(
      'uses bundled loader without checking roots when IO is unavailable',
      () {
        var findRootCalled = false;

        final setup = resolveDeckSetup(
          canRunProcess: false,
          findRoot: (_) {
            findRootCalled = true;
            throw StateError('findRoot should not be called');
          },
        );
        _disposeSetup(setup);

        final loader = setup.loader;
        expect(loader, isA<BundledDeckLoader>());
        expect(setup.workspace, DeckWorkspace());
        expect((loader as BundledDeckLoader).workspace, same(setup.workspace));
        expect(findRootCalled, isFalse);
      },
    );
  });
}
