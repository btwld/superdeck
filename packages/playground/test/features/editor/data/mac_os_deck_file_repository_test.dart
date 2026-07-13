@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:playground/core/data/data_sources/security_scoped_file_access.dart';
import 'package:playground/core/result.dart';
import 'package:playground/features/editor/data/mac_os_deck_file_repository.dart';
import 'package:playground/features/editor/domain/files/deck_file.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

class _FakeSecurityScopedFileAccess extends SecurityScopedFileAccess {
  DeckFileReference? picked;
  final Map<DeckFileReference, DeckFileReference> restored = {};
  final List<DeckFileReference> started = [];
  final List<DeckFileReference> stopped = [];
  Object? startError;
  Object? stopError;

  @override
  Future<DeckFileReference?> pickDeckFile() async => picked;

  @override
  Future<DeckFileReference> startAccessing(DeckFileReference reference) async {
    started.add(reference);
    final error = startError;
    if (error != null) throw error;
    return restored[reference] ?? reference;
  }

  @override
  Future<void> stopAccessing(DeckFileReference reference) async {
    stopped.add(reference);
    final error = stopError;
    if (error != null) throw error;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late _FakeSecurityScopedFileAccess access;
  late MacOsDeckFileRepository repository;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('deck_file_repository_test');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    access = _FakeSecurityScopedFileAccess();
    repository = MacOsDeckFileRepository(fileAccess: access);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<File> settingsFile() async {
    final directory = Directory(p.join(temp.path, 'superdeck_playground'));
    await directory.create(recursive: true);
    return File(p.join(directory.path, 'settings.json'));
  }

  test(
    'creates the first default deck and remembers its current-format reference',
    () async {
      final result = await repository.loadInitialDeck(
        starterMarkdown: '# Starter',
      );

      switch (result) {
        case Failure(:final error):
          fail('$error');
        case Ok(:final value):
          final path = p.join(temp.path, 'SuperDeck', 'untitled.md');
          expect(value.reference, DeckFileReference(path: path));
          expect(value.markdown, '# Starter');
          expect(await File(path).readAsString(), '# Starter');
          expect(jsonDecode(await (await settingsFile()).readAsString()), {
            'lastOpenedDeck': {'path': path},
          });
      }
    },
  );

  test(
    'restores the current settings object and persists a refreshed bookmark',
    () async {
      const remembered = DeckFileReference(
        path: '/old/talk.md',
        bookmark: 'old-bookmark',
      );
      final restoredPath = p.join(temp.path, 'moved.md');
      const refreshed = DeckFileReference(
        path: '/unused',
        bookmark: 'refreshed-bookmark',
      );
      final restored = DeckFileReference(
        path: restoredPath,
        bookmark: refreshed.bookmark,
      );
      await File(restoredPath).writeAsString('# Restored');
      await (await settingsFile()).writeAsString(
        jsonEncode({
          'lastOpenedDeck': {
            'path': remembered.path,
            'bookmark': remembered.bookmark,
          },
        }),
      );
      access.restored[remembered] = restored;

      final result = await repository.loadInitialDeck(
        starterMarkdown: '# Starter',
      );

      expect(access.started, [remembered]);
      expect(result, isA<Ok<DeckFileSnapshot>>());
      final snapshot = (result as Ok<DeckFileSnapshot>).value;
      expect(snapshot.reference, restored);
      expect(snapshot.markdown, '# Restored');
      expect(jsonDecode(await (await settingsFile()).readAsString()), {
        'lastOpenedDeck': {
          'path': restored.path,
          'bookmark': restored.bookmark,
        },
      });
    },
  );

  test('falls back to the default deck when settings are corrupt', () async {
    await (await settingsFile()).writeAsString('{not json');

    final result = await repository.loadInitialDeck(
      starterMarkdown: '# Starter',
    );

    expect(result, isA<Ok<DeckFileSnapshot>>());
    expect(
      (result as Ok<DeckFileSnapshot>).value.reference.path,
      p.join(temp.path, 'SuperDeck', 'untitled.md'),
    );
  });

  test('never overwrites an existing unreadable default file', () async {
    final defaultPath = p.join(temp.path, 'SuperDeck', 'untitled.md');
    await Directory(defaultPath).create(recursive: true);

    final result = await repository.loadInitialDeck(
      starterMarkdown: '# Starter',
    );

    expect(result, isA<Failure<DeckFileSnapshot>>());
    expect(await Directory(defaultPath).exists(), isTrue);
  });

  test('normalizes names and reports collisions', () async {
    final first = await repository.createDeck(
      name: '../nested/talk',
      markdown: '# Talk',
    );
    final second = await repository.createDeck(
      name: 'talk.md',
      markdown: '# Replacement',
    );

    expect(first, isA<Ok<DeckFileSnapshot>>());
    expect(
      p.basename((first as Ok<DeckFileSnapshot>).value.reference.path),
      'talk.md',
    );
    expect(second, isA<Failure<DeckFileSnapshot>>());
    expect(
      (second as Failure<DeckFileSnapshot>).error,
      isA<DeckNameCollisionException>(),
    );
  });

  test('returns typed failures for failed reads and writes', () async {
    final missing = DeckFileReference(path: p.join(temp.path, 'missing.md'));

    final pick = await repository.pickDeck();
    final write = await repository.writeDeck(missing, '# Missing');

    expect(pick, isA<Ok<DeckFileSnapshot?>>());
    expect((pick as Ok<DeckFileSnapshot?>).value, isNull);
    expect(write, isA<Failure<void>>());
    expect((write as Failure<void>).error, isA<DeckFileWriteException>());
  });

  test(
    'releases a failed picked candidate without changing a successful result',
    () async {
      const candidate = DeckFileReference(
        path: '/missing.md',
        bookmark: 'candidate-bookmark',
      );
      access.picked = candidate;

      final result = await repository.pickDeck();

      expect(result, isA<Failure<DeckFileSnapshot?>>());
      expect(access.started, [candidate]);
      expect(access.stopped, [candidate]);
    },
  );

  test('emits file changes through the shared watcher', () async {
    final file = File(p.join(temp.path, 'watched.md'));
    await file.writeAsString('# Before');
    final reference = DeckFileReference(path: file.path);
    final event = repository
        .watchDeck(reference)
        .first
        .timeout(const Duration(seconds: 3));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await file.writeAsString('# After');

    final changed = await event;
    expect(changed, isA<DeckFileChanged>());
    expect((changed as DeckFileChanged).markdown, '# After');
  });
}
