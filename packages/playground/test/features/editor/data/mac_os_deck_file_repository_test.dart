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
  SecurityScopedDirectoryReference? pickedDirectory;
  final Map<DeckFileReference, DeckFileReference> restored = {};
  final Map<SecurityScopedDirectoryReference, SecurityScopedDirectoryReference>
  restoredDirectories = {};
  final List<DeckFileReference> started = [];
  final List<DeckFileReference> stopped = [];
  final List<SecurityScopedDirectoryReference> startedDirectories = [];
  final List<SecurityScopedDirectoryReference> stoppedDirectories = [];
  Object? startError;
  Object? stopError;

  @override
  Future<DeckFileReference?> pickDeckFile() async => picked;

  @override
  Future<SecurityScopedDirectoryReference?> pickDecksDirectory() async {
    return pickedDirectory;
  }

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

  @override
  Future<SecurityScopedDirectoryReference> startAccessingDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    startedDirectories.add(reference);
    final error = startError;
    if (error != null) throw error;
    return restoredDirectories[reference] ?? reference;
  }

  @override
  Future<void> stopAccessingDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    stoppedDirectories.add(reference);
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
    access = _FakeSecurityScopedFileAccess()
      ..pickedDirectory = SecurityScopedDirectoryReference(
        path: temp.path,
        bookmark: 'directory-bookmark',
      );
    repository = MacOsDeckFileRepository(fileAccess: access);
  });

  tearDown(() async {
    repository.dispose();
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
            'decksDirectory': {
              'path': temp.path,
              'bookmark': 'directory-bookmark',
            },
            'lastOpenedDeck': {'path': path},
          });
      }
    },
  );

  test('creates decks under the remembered user-selected directory', () async {
    final selectedRoot = Directory(p.join(temp.path, 'user-documents'));
    await selectedRoot.create();
    await (await settingsFile()).writeAsString(
      jsonEncode({
        'decksDirectory': {
          'path': selectedRoot.path,
          'bookmark': 'directory-bookmark',
        },
      }),
    );

    final result = await repository.loadInitialDeck(
      starterMarkdown: '# Starter',
    );

    expect(result, isA<Ok<DeckFileSnapshot>>());
    final snapshot = (result as Ok<DeckFileSnapshot>).value;
    final expectedPath = p.join(selectedRoot.path, 'SuperDeck', 'untitled.md');
    expect(snapshot.reference.path, expectedPath);
    expect(await File(expectedPath).readAsString(), '# Starter');
    expect(access.startedDirectories, [
      SecurityScopedDirectoryReference(
        path: selectedRoot.path,
        bookmark: 'directory-bookmark',
      ),
    ]);
  });

  test('activates directory access before restoring a folder deck', () async {
    final selectedRoot = Directory(p.join(temp.path, 'user-documents'));
    final deckPath = p.join(selectedRoot.path, 'SuperDeck', 'talk.md');
    await File(deckPath).create(recursive: true);
    await File(deckPath).writeAsString('# Remembered talk');
    await (await settingsFile()).writeAsString(
      jsonEncode({
        'decksDirectory': {
          'path': selectedRoot.path,
          'bookmark': 'directory-bookmark',
        },
        'lastOpenedDeck': {'path': deckPath},
      }),
    );

    final result = await repository.loadInitialDeck(
      starterMarkdown: '# Starter',
    );

    expect(result, isA<Ok<DeckFileSnapshot>>());
    expect(
      (result as Ok<DeckFileSnapshot>).value.markdown,
      '# Remembered talk',
    );
    expect(access.startedDirectories, [
      SecurityScopedDirectoryReference(
        path: selectedRoot.path,
        bookmark: 'directory-bookmark',
      ),
    ]);
  });

  test(
    'returns an access failure when directory selection is cancelled',
    () async {
      access.pickedDirectory = null;

      final result = await repository.loadInitialDeck(
        starterMarkdown: '# Starter',
      );

      expect(result, isA<Failure<DeckFileSnapshot>>());
      expect(
        (result as Failure<DeckFileSnapshot>).error,
        isA<DeckFileAccessException>(),
      );
      expect(await Directory(p.join(temp.path, 'SuperDeck')).exists(), isFalse);
    },
  );

  test('persists a refreshed decks-directory bookmark', () async {
    final selected = access.pickedDirectory!;
    final refreshed = SecurityScopedDirectoryReference(
      path: selected.path,
      bookmark: 'refreshed-directory-bookmark',
    );
    access.restoredDirectories[selected] = refreshed;

    final result = await repository.loadInitialDeck(
      starterMarkdown: '# Starter',
    );

    expect(result, isA<Ok<DeckFileSnapshot>>());
    expect(jsonDecode(await (await settingsFile()).readAsString()), {
      'decksDirectory': {
        'path': refreshed.path,
        'bookmark': refreshed.bookmark,
      },
      'lastOpenedDeck': {'path': p.join(temp.path, 'SuperDeck', 'untitled.md')},
    });
  });

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

  test('remembers an existing default after a stale deck fallback', () async {
    final defaultPath = p.join(temp.path, 'SuperDeck', 'untitled.md');
    await File(defaultPath).create(recursive: true);
    await File(defaultPath).writeAsString('# Existing default');
    const stale = DeckFileReference(
      path: '/missing/talk.md',
      bookmark: 'stale-bookmark',
    );
    await (await settingsFile()).writeAsString(
      jsonEncode({
        'lastOpenedDeck': {'path': stale.path, 'bookmark': stale.bookmark},
      }),
    );

    final result = await repository.loadInitialDeck(
      starterMarkdown: '# Starter',
    );

    expect(result, isA<Ok<DeckFileSnapshot>>());
    expect((result as Ok<DeckFileSnapshot>).value.reference.path, defaultPath);
    expect(jsonDecode(await (await settingsFile()).readAsString()), {
      'decksDirectory': {'path': temp.path, 'bookmark': 'directory-bookmark'},
      'lastOpenedDeck': {'path': defaultPath},
    });
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

  test('releases the active decks directory when disposed', () async {
    final result = await repository.loadInitialDeck(
      starterMarkdown: '# Starter',
    );
    expect(result, isA<Ok<DeckFileSnapshot>>());
    final active = access.startedDirectories.single;

    repository.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(access.stoppedDirectories, [active]);
  });

  test('ignores a decks-directory release failure when disposed', () async {
    final result = await repository.loadInitialDeck(
      starterMarkdown: '# Starter',
    );
    expect(result, isA<Ok<DeckFileSnapshot>>());
    access.stopError = StateError('release failed');

    repository.dispose();
    await Future<void>.delayed(Duration.zero);
  });
}
