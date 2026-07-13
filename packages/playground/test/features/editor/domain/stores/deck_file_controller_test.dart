import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:playground/core/data/data_sources/deck_file_store.dart';
import 'package:playground/features/editor/domain/stores/deck_file_controller.dart';
import 'package:playground/features/editor/utils/markdown_editor.dart';

import '../../../../helpers/fake_deck_file_store.dart';

/// Editor stub that echoes reloads back into the controller, exactly as the
/// real `TextEditorController` forwards document changes to `handleEditorChange`
/// — so the loop-prevention paths are exercised.
class FakeMarkdownEditor implements MarkdownEditor {
  FakeMarkdownEditor(this.controller, {this.onReplace});

  final DeckFileController controller;
  final void Function()? onReplace;
  final List<String> replaced = [];

  @override
  void replaceMarkdown(String markdown) {
    replaced.add(markdown);
    controller.handleEditorChange(markdown);
    onReplace?.call();
  }
}

void main() {
  const debounce = Duration(milliseconds: 5);
  Future<void> afterDebounce() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  DeckFileController newController(
    FakeDeckFileStore store,
    FakeAppSettingsStore settings,
  ) {
    final controller = DeckFileController(
      store: store,
      settings: settings,
      autoSaveDebounce: debounce,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  group('initialize', () {
    test('creates and binds a default deck on first run', () async {
      final store = FakeDeckFileStore();
      final settings = FakeAppSettingsStore();
      final controller = newController(store, settings);

      await controller.initialize();

      final expectedPath = p.join('/decks', 'untitled.md');
      expect(controller.boundPath, expectedPath);
      expect(controller.isBound, isTrue);
      expect(controller.content, kStarterDeckMarkdown);
      expect(store.files[expectedPath], kStarterDeckMarkdown);
      expect(settings.path, expectedPath, reason: 'remembers last-opened');
    });

    test('reopens the remembered file when it exists', () async {
      final store = FakeDeckFileStore();
      final settings = FakeAppSettingsStore();
      store.files['/somewhere/deck.md'] = '# Remembered';
      settings.path = '/somewhere/deck.md';
      final controller = newController(store, settings);

      await controller.initialize();

      expect(controller.boundPath, '/somewhere/deck.md');
      expect(controller.content, '# Remembered');
    });

    test('restores and refreshes security-scoped access on launch', () async {
      const remembered = DeckFileReference(
        path: '/somewhere/deck.md',
        bookmark: 'old-bookmark',
      );
      const restored = DeckFileReference(
        path: '/moved/deck.md',
        bookmark: 'refreshed-bookmark',
      );
      final store = FakeDeckFileStore()
        ..accessResults[remembered] = restored
        ..files[restored.path] = '# Remembered';
      final settings = FakeAppSettingsStore()..deck = remembered;
      final controller = newController(store, settings);

      await controller.initialize();

      expect(store.accessStarts, [remembered]);
      expect(controller.boundPath, restored.path);
      expect(controller.content, '# Remembered');
      expect(settings.deck, restored, reason: 'persists refreshed bookmark');
    });

    test('falls back to default when the remembered file is missing', () async {
      final store = FakeDeckFileStore();
      final settings = FakeAppSettingsStore();
      settings.path = '/gone/deck.md';
      final controller = newController(store, settings);

      await controller.initialize();

      expect(controller.boundPath, p.join('/decks', 'untitled.md'));
    });

    test('binds and watches when remembering the path fails', () async {
      final store = FakeDeckFileStore();
      final settings = FakeAppSettingsStore()..failWrites = true;
      final controller = newController(store, settings);

      await controller.initialize();

      expect(controller.boundPath, p.join('/decks', 'untitled.md'));
      expect(controller.isBound, isTrue);
      expect(store.watchCount, 1);
    });

    test('does not overwrite an unreadable default deck', () async {
      final store = FakeDeckFileStore();
      final path = p.join('/decks', 'untitled.md');
      store.files[path] = '# Existing work';
      store.failReads.add(path);
      final controller = newController(store, FakeAppSettingsStore());

      await expectLater(
        controller.initialize(),
        throwsA(isA<DeckFileReadException>()),
      );

      expect(store.files[path], '# Existing work');
    });
  });

  group('auto-save', () {
    test('debounced write persists the latest edit', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final path = controller.boundPath!;
      final writesBefore = store.writeCount;

      controller.handleEditorChange('# Edited');
      controller.handleEditorChange('# Edited twice');
      await afterDebounce();

      expect(store.files[path], '# Edited twice');
      expect(store.writeCount, writesBefore + 1, reason: 'coalesced');
    });

    test('skips writing when content is unchanged (echo)', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final writesBefore = store.writeCount;

      controller.handleEditorChange(controller.content);
      await afterDebounce();

      expect(store.writeCount, writesBefore);
    });

    test(
      'reverting to synced content mid-debounce cancels the stale save',
      () async {
        final store = FakeDeckFileStore();
        final controller = newController(store, FakeAppSettingsStore());
        await controller.initialize();
        final path = controller.boundPath!;
        final synced = controller.content;
        final writesBefore = store.writeCount;

        // Type an edit, then revert back to the synced content before the
        // debounce fires. The pending save of the intermediate edit must not run.
        controller.handleEditorChange('# Intermediate');
        controller.handleEditorChange(synced);
        await afterDebounce();

        expect(
          store.files[path],
          synced,
          reason: 'disk keeps the synced content',
        );
        expect(
          store.writeCount,
          writesBefore,
          reason: 'stale save was cancelled',
        );
      },
    );

    test('a failed write does not mark content as synced', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final path = controller.boundPath!;
      final editor = FakeMarkdownEditor(controller);
      controller.attachEditor(editor);

      // Auto-save fails: nothing reaches disk and the synced marker must not
      // advance to the unwritten content.
      store.failWrites = true;
      controller.handleEditorChange('# Never persisted');
      await afterDebounce();

      // A later external edit must still be detected as external (not mistaken
      // for our own write) and reloaded into the editor.
      store.failWrites = false;
      await store.externalWrite(path, '# External');

      expect(editor.replaced, ['# External']);
      expect(controller.content, '# External');
    });

    test('switching decks flushes a pending debounced edit', () async {
      final store = FakeDeckFileStore();
      store.files['/elsewhere/other.md'] = '# Other';
      store.pickResult = const DeckFileReference(path: '/elsewhere/other.md');
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final originalPath = controller.boundPath!;

      controller.handleEditorChange('# Last-second edit');
      await controller.openDeck();

      expect(store.files[originalPath], '# Last-second edit');
      expect(controller.content, '# Other');
    });

    test('an old save completion cannot dirty the new binding', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final originalPath = controller.boundPath!;
      final writeStarted = Completer<void>();
      final allowWrite = Completer<void>();
      store.writeStarted[originalPath] = writeStarted;
      store.writeGates[originalPath] = allowWrite;

      controller.handleEditorChange('# Slow save');
      await writeStarted.future;

      store.files['/elsewhere/other.md'] = '# Other';
      store.pickResult = const DeckFileReference(path: '/elsewhere/other.md');
      final open = controller.openDeck();
      await Future<void>.delayed(Duration.zero);
      allowWrite.complete();
      await open;
      await afterDebounce();

      final writesBeforeEcho = store.writeCount;
      controller.handleEditorChange('# Other');
      await afterDebounce();

      expect(store.writeCount, writesBeforeEcho);
      expect(controller.content, '# Other');
    });

    test(
      'flushPendingSave persists an edit before its debounce fires',
      () async {
        final store = FakeDeckFileStore();
        final controller = newController(store, FakeAppSettingsStore());
        await controller.initialize();
        final path = controller.boundPath!;

        controller.handleEditorChange('# Last-second edit');
        final saved = await controller.flushPendingSave();

        expect(saved, isTrue);
        expect(store.files[path], '# Last-second edit');
      },
    );

    test('flushPendingSave reports a failed final write', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      store.failWrites = true;

      controller.handleEditorChange('# Cannot save');

      expect(await controller.flushPendingSave(), isFalse);
      expect(controller.warning, isNotNull);
    });

    test('flushPendingSave includes edits made during its write', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final path = controller.boundPath!;
      final writeStarted = Completer<void>();
      final allowWrite = Completer<void>();
      store.writeStarted[path] = writeStarted;
      store.writeGates[path] = allowWrite;

      controller.handleEditorChange('# First edit');
      final flush = controller.flushPendingSave();
      await writeStarted.future;
      controller.handleEditorChange('# Edit during flush');
      allowWrite.complete();

      expect(await flush, isTrue);
      expect(store.files[path], '# Edit during flush');
    });
  });

  group('external changes', () {
    test('self-write is filtered out (no reload)', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final editor = FakeMarkdownEditor(controller);
      controller.attachEditor(editor);
      final path = controller.boundPath!;

      controller.handleEditorChange('# Ours');
      await afterDebounce();
      // Watcher fires for our own write: disk content matches last synced.
      await store.externalWrite(path, '# Ours');

      expect(editor.replaced, isEmpty);
    });

    test(
      'external edit auto-reloads into the editor without looping',
      () async {
        final store = FakeDeckFileStore();
        final controller = newController(store, FakeAppSettingsStore());
        await controller.initialize();
        final editor = FakeMarkdownEditor(controller);
        controller.attachEditor(editor);
        final path = controller.boundPath!;
        final writesBefore = store.writeCount;

        await store.externalWrite(path, '# From another app');

        expect(editor.replaced, ['# From another app']);
        expect(controller.content, '# From another app');
        await afterDebounce();
        expect(
          store.writeCount,
          writesBefore,
          reason: 'reload must not trigger a re-save loop',
        );
      },
    );

    test('external edit wins over an in-flight auto-save', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final externalApplied = Completer<void>();
      final editor = FakeMarkdownEditor(
        controller,
        onReplace: externalApplied.complete,
      );
      controller.attachEditor(editor);
      final path = controller.boundPath!;
      final writeStarted = Completer<void>();
      final allowWrite = Completer<void>();
      store.writeStarted[path] = writeStarted;
      store.writeGates[path] = allowWrite;

      controller.handleEditorChange('# Local save');
      await writeStarted.future;
      await store.externalWrite(path, '# External wins');
      await externalApplied.future;
      allowWrite.complete();
      await afterDebounce();

      expect(controller.content, '# External wins');
      expect(
        store.writeCount,
        3,
        reason: 'external content is restored to disk',
      );
      expect(store.files[path], '# External wins');
      expect(editor.replaced, ['# External wins']);
    });

    test('deletion unbinds, warns, and keeps in-memory content', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final path = controller.boundPath!;
      controller.handleEditorChange('# In progress');
      await afterDebounce();

      await store.externalDelete(path);

      expect(controller.isBound, isFalse);
      expect(controller.status, DeckBindingStatus.unbound);
      expect(controller.warning, isNotNull);
      expect(controller.content, '# In progress');

      // Further edits are not persisted and the file is not resurrected.
      final writesBefore = store.writeCount;
      controller.handleEditorChange('# More');
      await afterDebounce();
      expect(store.writeCount, writesBefore);
      expect(store.files.containsKey(path), isFalse);
    });

    test('a stale watcher read cannot replace a newly opened deck', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final editor = FakeMarkdownEditor(controller);
      controller.attachEditor(editor);
      final originalPath = controller.boundPath!;
      final readStarted = Completer<void>();
      final allowRead = Completer<void>();
      store.readStarted[originalPath] = readStarted;
      store.readGates[originalPath] = allowRead;

      final externalChange = store.externalWrite(originalPath, '# Stale read');
      await readStarted.future;

      store.files['/elsewhere/other.md'] = '# Other';
      store.pickResult = const DeckFileReference(path: '/elsewhere/other.md');
      await controller.openDeck();
      allowRead.complete();
      await externalChange;
      await afterDebounce();

      expect(controller.boundPath, '/elsewhere/other.md');
      expect(controller.content, '# Other');
      expect(editor.replaced, ['# Other']);
    });
  });

  test('disposing during initialization does not start a watcher', () async {
    final store = FakeDeckFileStore();
    final settings = FakeAppSettingsStore();
    final readStarted = Completer<void>();
    final allowRead = Completer<void>();
    settings.readStarted = readStarted;
    settings.readGate = allowRead;
    final controller = DeckFileController(
      store: store,
      settings: settings,
      autoSaveDebounce: debounce,
    );

    final initialize = controller.initialize();
    await readStarted.future;
    controller.dispose();
    allowRead.complete();
    await initialize;

    expect(store.watchCount, 0);
  });

  group('newDeck', () {
    test('creates, seeds the starter, and rebinds', () async {
      final store = FakeDeckFileStore();
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final editor = FakeMarkdownEditor(controller);
      controller.attachEditor(editor);

      await controller.newDeck('talk');

      final path = p.join('/decks', 'talk.md');
      expect(controller.boundPath, path);
      expect(controller.content, kStarterDeckMarkdown);
      expect(store.files[path], kStarterDeckMarkdown);
      expect(editor.replaced, [kStarterDeckMarkdown]);
    });

    test('throws DeckNameCollisionException on a name clash', () async {
      final store = FakeDeckFileStore();
      store.files[p.join('/decks', 'talk.md')] = 'existing';
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();

      expect(
        () => controller.newDeck('talk'),
        throwsA(isA<DeckNameCollisionException>()),
      );
    });
  });

  group('openDeck', () {
    test('binds the picked file', () async {
      final store = FakeDeckFileStore();
      store.files['/elsewhere/other.md'] = '# Other';
      store.pickResult = const DeckFileReference(
        path: '/elsewhere/other.md',
        bookmark: 'bookmark',
      );
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final editor = FakeMarkdownEditor(controller);
      controller.attachEditor(editor);

      await controller.openDeck();

      expect(controller.boundPath, '/elsewhere/other.md');
      expect(controller.content, '# Other');
      expect(editor.replaced, ['# Other']);
      expect(store.accessStarts, [store.pickResult]);
    });

    test('releases the previous bookmark after a replacement opens', () async {
      const previous = DeckFileReference(
        path: '/outside/previous.md',
        bookmark: 'previous-bookmark',
      );
      const replacement = DeckFileReference(
        path: '/outside/replacement.md',
        bookmark: 'replacement-bookmark',
      );
      final store = FakeDeckFileStore()
        ..files[previous.path] = '# Previous'
        ..files[replacement.path] = '# Replacement'
        ..pickResult = replacement;
      final settings = FakeAppSettingsStore()..deck = previous;
      final controller = newController(store, settings);
      await controller.initialize();

      await controller.openDeck();

      expect(controller.boundPath, replacement.path);
      expect(store.accessStops, [previous]);
      expect(settings.deck, replacement);
    });

    test('cancelled picker is a no-op', () async {
      final store = FakeDeckFileStore();
      store.pickResult = null;
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final original = controller.boundPath;

      await controller.openDeck();

      expect(controller.boundPath, original);
    });

    test('read failure warns and keeps the current file', () async {
      final store = FakeDeckFileStore();
      store.pickResult = const DeckFileReference(
        path: '/elsewhere/missing.md',
      ); // not in files → read throws
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final original = controller.boundPath;

      await controller.openDeck();

      expect(controller.boundPath, original);
      expect(controller.warning, isNotNull);
      expect(controller.isBound, isTrue);
    });

    test('failed replacement releases only the candidate bookmark', () async {
      const current = DeckFileReference(
        path: '/outside/current.md',
        bookmark: 'current-bookmark',
      );
      const candidate = DeckFileReference(
        path: '/outside/missing.md',
        bookmark: 'candidate-bookmark',
      );
      final store = FakeDeckFileStore()
        ..files[current.path] = '# Current'
        ..pickResult = candidate;
      final settings = FakeAppSettingsStore()..deck = current;
      final controller = newController(store, settings);
      await controller.initialize();

      await controller.openDeck();

      expect(controller.boundPath, current.path);
      expect(store.accessStops, [candidate]);
    });

    test('picker failure warns and keeps the current file', () async {
      final store = FakeDeckFileStore()..pickError = Exception('picker failed');
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final original = controller.boundPath;

      await controller.openDeck();

      expect(controller.boundPath, original);
      expect(controller.warning, isNotNull);
      expect(controller.isBound, isTrue);
    });
  });
}
