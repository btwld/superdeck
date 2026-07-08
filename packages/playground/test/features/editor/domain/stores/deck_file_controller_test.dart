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
  FakeMarkdownEditor(this.controller);

  final DeckFileController controller;
  final List<String> replaced = [];

  @override
  void replaceMarkdown(String markdown) {
    replaced.add(markdown);
    controller.handleEditorChange(markdown);
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

    test('falls back to default when the remembered file is missing', () async {
      final store = FakeDeckFileStore();
      final settings = FakeAppSettingsStore();
      settings.path = '/gone/deck.md';
      final controller = newController(store, settings);

      await controller.initialize();

      expect(controller.boundPath, p.join('/decks', 'untitled.md'));
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
      store.pickResult = '/elsewhere/other.md';
      final controller = newController(store, FakeAppSettingsStore());
      await controller.initialize();
      final editor = FakeMarkdownEditor(controller);
      controller.attachEditor(editor);

      await controller.openDeck();

      expect(controller.boundPath, '/elsewhere/other.md');
      expect(controller.content, '# Other');
      expect(editor.replaced, ['# Other']);
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
      store.pickResult = '/elsewhere/missing.md'; // not in files → read throws
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
