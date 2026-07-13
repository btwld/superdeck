import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:playground/core/result.dart';
import 'package:playground/features/editor/domain/files/deck_file.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:playground/features/editor/domain/stores/deck_file_session.dart';

import '../../../../helpers/fake_deck_file_repository.dart';

void main() {
  const debounce = Duration(milliseconds: 5);

  Future<void> afterDebounce() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  ({DeckDocumentStore document, DeckFileSession session}) newSession(
    FakeDeckFileRepository repository, {
    DeckFileReference? reference,
    String markdown = kStarterDeckMarkdown,
  }) {
    final deckReference =
        reference ?? const DeckFileReference(path: '/decks/a.md');
    repository.files.putIfAbsent(deckReference.path, () => markdown);
    final document = DeckDocumentStore(markdown: markdown);
    final session = DeckFileSession(
      initialSnapshot: DeckFileSnapshot(
        reference: deckReference,
        markdown: markdown,
      ),
      repository: repository,
      documentStore: document,
      autoSaveDebounce: debounce,
    );
    addTearDown(() {
      session.dispose();
      document.dispose();
    });
    return (document: document, session: session);
  }

  group('initial load', () {
    test('creates and remembers a default deck on first run', () async {
      final repository = FakeDeckFileRepository();

      final result = await repository.loadInitialDeck(
        starterMarkdown: kStarterDeckMarkdown,
      );

      switch (result) {
        case Failure(:final error):
          fail('$error');
        case Ok(:final value):
          final expectedPath = p.join('/decks', 'untitled.md');
          expect(value.reference.path, expectedPath);
          expect(value.markdown, kStarterDeckMarkdown);
          expect(repository.files[expectedPath], kStarterDeckMarkdown);
          expect(repository.rememberedDeck?.path, expectedPath);
      }
    });

    test('reopens and refreshes a remembered bookmark', () async {
      const remembered = DeckFileReference(
        path: '/somewhere/deck.md',
        bookmark: 'old-bookmark',
      );
      const restored = DeckFileReference(
        path: '/moved/deck.md',
        bookmark: 'refreshed-bookmark',
      );
      final repository = FakeDeckFileRepository()
        ..rememberedDeck = remembered
        ..accessResults[remembered] = restored
        ..files[restored.path] = '# Remembered';

      final result = await repository.loadInitialDeck(
        starterMarkdown: kStarterDeckMarkdown,
      );

      expect(repository.accessStarts, [remembered]);
      expect(repository.rememberedDeck, restored);
      expect(result, isA<Ok<DeckFileSnapshot>>());
      final snapshot = (result as Ok<DeckFileSnapshot>).value;
      expect(snapshot.reference, restored);
      expect(snapshot.markdown, '# Remembered');
    });

    test('falls back when the remembered deck cannot be restored', () async {
      const remembered = DeckFileReference(
        path: '/gone/deck.md',
        bookmark: 'bookmark',
      );
      final repository = FakeDeckFileRepository()..rememberedDeck = remembered;

      final result = await repository.loadInitialDeck(
        starterMarkdown: kStarterDeckMarkdown,
      );

      expect(result, isA<Ok<DeckFileSnapshot>>());
      expect(
        (result as Ok<DeckFileSnapshot>).value.reference.path,
        p.join('/decks', 'untitled.md'),
      );
      expect(repository.accessStops, [remembered]);
    });

    test('does not overwrite an unreadable existing default deck', () async {
      final repository = FakeDeckFileRepository();
      final path = p.join('/decks', 'untitled.md');
      repository.files[path] = '# Existing work';
      repository.failReads.add(path);

      final result = await repository.loadInitialDeck(
        starterMarkdown: kStarterDeckMarkdown,
      );

      expect(result, isA<Failure<DeckFileSnapshot>>());
      expect(repository.files[path], '# Existing work');
    });

    test('settings failures do not prevent a usable initial deck', () async {
      final repository = FakeDeckFileRepository()..failRememberWrites = true;

      final result = await repository.loadInitialDeck(
        starterMarkdown: kStarterDeckMarkdown,
      );

      expect(result, isA<Ok<DeckFileSnapshot>>());
    });
  });

  group('auto-save', () {
    test('debounces document changes and writes the latest text', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);

      scope.document.replaceMarkdown('# Edited');
      scope.document.replaceMarkdown('# Edited twice');
      await afterDebounce();

      expect(repository.files[scope.session.boundPath], '# Edited twice');
      expect(repository.writeCount, 1);
    });

    test(
      'reverting within the debounce window cancels the stale save',
      () async {
        final repository = FakeDeckFileRepository();
        final scope = newSession(repository);
        final initial = scope.document.markdown;

        scope.document.replaceMarkdown('# Intermediate');
        scope.document.replaceMarkdown(initial);
        await afterDebounce();

        expect(repository.files[scope.session.boundPath], initial);
        expect(repository.writeCount, 0);
      },
    );

    test(
      'a failed write leaves the content eligible for external reload',
      () async {
        final repository = FakeDeckFileRepository();
        final scope = newSession(repository);
        final path = scope.session.boundPath!;
        repository.failWrites = true;

        scope.document.replaceMarkdown('# Never persisted');
        await afterDebounce();
        repository.failWrites = false;
        await repository.externalWrite(path, '# External');

        expect(scope.document.markdown, '# External');
        expect(scope.session.warning, isNotNull);
      },
    );

    test('opening another deck flushes a pending edit first', () async {
      final repository = FakeDeckFileRepository()
        ..files['/elsewhere/other.md'] = '# Other'
        ..pickResult = const DeckFileReference(path: '/elsewhere/other.md');
      final scope = newSession(repository);
      final originalPath = scope.session.boundPath!;

      scope.document.replaceMarkdown('# Last-second edit');
      await scope.session.openDeck();

      expect(repository.files[originalPath], '# Last-second edit');
      expect(scope.document.markdown, '# Other');
    });

    test(
      'a stale save completion cannot affect a replacement binding',
      () async {
        final repository = FakeDeckFileRepository();
        final scope = newSession(repository);
        final originalPath = scope.session.boundPath!;
        final writeStarted = Completer<void>();
        final allowWrite = Completer<void>();
        repository.writeStarted[originalPath] = writeStarted;
        repository.writeGates[originalPath] = allowWrite;

        scope.document.replaceMarkdown('# Slow save');
        await writeStarted.future;
        repository.files['/elsewhere/other.md'] = '# Other';
        repository.pickResult = const DeckFileReference(
          path: '/elsewhere/other.md',
        );
        final open = scope.session.openDeck();
        await Future<void>.delayed(Duration.zero);
        allowWrite.complete();
        await open;
        await afterDebounce();

        final writesBeforeEcho = repository.writeCount;
        scope.document.replaceMarkdown('# Other');
        await afterDebounce();

        expect(scope.document.markdown, '# Other');
        expect(repository.writeCount, writesBeforeEcho);
      },
    );

    test('flush writes an edit before the debounce fires', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);

      scope.document.replaceMarkdown('# Last-second edit');

      expect(await scope.session.flushPendingSave(), isTrue);
      expect(repository.files[scope.session.boundPath], '# Last-second edit');
    });

    test('flush reports a failed final write', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);
      repository.failWrites = true;

      scope.document.replaceMarkdown('# Cannot save');

      expect(await scope.session.flushPendingSave(), isFalse);
      expect(scope.session.warning, isNotNull);
    });

    test('flush includes a change made during its in-flight write', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);
      final path = scope.session.boundPath!;
      final writeStarted = Completer<void>();
      final allowWrite = Completer<void>();
      repository.writeStarted[path] = writeStarted;
      repository.writeGates[path] = allowWrite;

      scope.document.replaceMarkdown('# First edit');
      final flush = scope.session.flushPendingSave();
      await writeStarted.future;
      scope.document.replaceMarkdown('# Edit during flush');
      allowWrite.complete();

      expect(await flush, isTrue);
      expect(repository.files[path], '# Edit during flush');
    });
  });

  group('external changes', () {
    test('filters a self-write watcher echo', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);
      final path = scope.session.boundPath!;

      scope.document.replaceMarkdown('# Ours');
      await afterDebounce();
      final writesBeforeEcho = repository.writeCount;
      await repository.externalWrite(path, '# Ours');

      expect(scope.document.markdown, '# Ours');
      expect(repository.writeCount, writesBeforeEcho);
    });

    test(
      'external content replaces the document without a save loop',
      () async {
        final repository = FakeDeckFileRepository();
        final scope = newSession(repository);
        final path = scope.session.boundPath!;

        await repository.externalWrite(path, '# From another app');
        await afterDebounce();

        expect(scope.document.markdown, '# From another app');
        expect(repository.writeCount, 0);
      },
    );

    test('external content wins over an in-flight local write', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);
      final path = scope.session.boundPath!;
      final writeStarted = Completer<void>();
      final allowWrite = Completer<void>();
      repository.writeStarted[path] = writeStarted;
      repository.writeGates[path] = allowWrite;

      scope.document.replaceMarkdown('# Local save');
      await writeStarted.future;
      await repository.externalWrite(path, '# External wins');
      allowWrite.complete();
      await afterDebounce();

      expect(scope.document.markdown, '# External wins');
      expect(repository.files[path], '# External wins');
      expect(repository.writeCount, 2);
    });

    test(
      'deletion unbinds and keeps the document editable in memory',
      () async {
        final repository = FakeDeckFileRepository();
        final scope = newSession(repository);
        final path = scope.session.boundPath!;
        scope.document.replaceMarkdown('# In progress');
        await afterDebounce();

        await repository.externalDelete(path);

        expect(scope.session.isBound, isFalse);
        expect(scope.session.status, DeckBindingStatus.unbound);
        expect(scope.session.warning, isNotNull);
        expect(scope.document.markdown, '# In progress');

        final writesBefore = repository.writeCount;
        scope.document.replaceMarkdown('# More');
        await afterDebounce();
        expect(repository.writeCount, writesBefore);
        expect(repository.files.containsKey(path), isFalse);
      },
    );

    test('a stale watcher read cannot replace a newly opened deck', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);
      final originalPath = scope.session.boundPath!;
      final readStarted = Completer<void>();
      final allowRead = Completer<void>();
      repository.readStarted[originalPath] = readStarted;
      repository.readGates[originalPath] = allowRead;

      final externalChange = repository.externalWrite(originalPath, '# Stale');
      await readStarted.future;
      repository.files['/elsewhere/other.md'] = '# Other';
      repository.pickResult = const DeckFileReference(
        path: '/elsewhere/other.md',
      );
      await scope.session.openDeck();
      allowRead.complete();
      await externalChange;
      await afterDebounce();

      expect(scope.session.boundPath, '/elsewhere/other.md');
      expect(scope.document.markdown, '# Other');
    });
  });

  group('new deck', () {
    test('creates, seeds, and rebinds a new deck', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);

      final result = await scope.session.createDeck('talk');

      final path = p.join('/decks', 'talk.md');
      expect(result, isA<Ok<void>>());
      expect(scope.session.boundPath, path);
      expect(scope.document.markdown, kStarterDeckMarkdown);
      expect(repository.files[path], kStarterDeckMarkdown);
    });

    test('returns a name collision instead of overwriting', () async {
      final repository = FakeDeckFileRepository()
        ..files[p.join('/decks', 'talk.md')] = 'existing';
      final scope = newSession(repository);

      final result = await scope.session.createDeck('talk');

      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure<void>).error,
        isA<DeckNameCollisionException>(),
      );
    });
  });

  group('open deck', () {
    test('binds the selected deck and retains its bookmark', () async {
      const picked = DeckFileReference(
        path: '/elsewhere/other.md',
        bookmark: 'bookmark',
      );
      final repository = FakeDeckFileRepository()
        ..files[picked.path] = '# Other'
        ..pickResult = picked;
      final scope = newSession(repository);

      await scope.session.openDeck();

      expect(scope.session.boundPath, picked.path);
      expect(scope.document.markdown, '# Other');
      expect(repository.accessStarts, [picked]);
    });

    test('releases the previous bookmark after replacement', () async {
      const previous = DeckFileReference(
        path: '/outside/previous.md',
        bookmark: 'previous-bookmark',
      );
      const replacement = DeckFileReference(
        path: '/outside/replacement.md',
        bookmark: 'replacement-bookmark',
      );
      final repository = FakeDeckFileRepository()
        ..files[previous.path] = '# Previous'
        ..files[replacement.path] = '# Replacement'
        ..pickResult = replacement;
      final scope = newSession(
        repository,
        reference: previous,
        markdown: '# Previous',
      );

      await scope.session.openDeck();

      expect(scope.session.boundPath, replacement.path);
      expect(repository.accessStops, [previous]);
    });

    test('cancellation is a no-op', () async {
      final repository = FakeDeckFileRepository();
      final scope = newSession(repository);
      final originalPath = scope.session.boundPath;

      await scope.session.openDeck();

      expect(scope.session.boundPath, originalPath);
    });

    test('failures warn while preserving the current deck', () async {
      final repository = FakeDeckFileRepository()
        ..pickResult = const DeckFileReference(path: '/elsewhere/missing.md');
      final scope = newSession(repository);
      final originalPath = scope.session.boundPath;

      await scope.session.openDeck();

      expect(scope.session.boundPath, originalPath);
      expect(scope.session.warning, isNotNull);
      expect(scope.session.isBound, isTrue);
    });

    test('a failed replacement releases only its candidate bookmark', () async {
      const current = DeckFileReference(
        path: '/outside/current.md',
        bookmark: 'current-bookmark',
      );
      const candidate = DeckFileReference(
        path: '/outside/missing.md',
        bookmark: 'candidate-bookmark',
      );
      final repository = FakeDeckFileRepository()
        ..files[current.path] = '# Current'
        ..pickResult = candidate;
      final scope = newSession(
        repository,
        reference: current,
        markdown: '# Current',
      );

      await scope.session.openDeck();

      expect(scope.session.boundPath, current.path);
      expect(repository.accessStops, [candidate]);
    });
  });
}
