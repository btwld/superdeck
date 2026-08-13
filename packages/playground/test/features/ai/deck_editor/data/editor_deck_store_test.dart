import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/data/mappers/deck_markdown_codec.dart';
import 'package:playground/features/ai/deck_editor/data/editor_deck_store.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_tool_error.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:playground/features/editor/domain/stores/editor_store.dart';
import 'package:playground/features/editor/utils/text_editor_controller.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'a real loader and controller observe each write before completion',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.store.synchronize();
      final updated = [
        ...harness.store.read(),
        Slide(
          key: 'new',
          options: SlideOptions(title: 'Second'),
          sections: [SectionBlock.text('# Second')],
        ),
      ];

      final observed = await harness.store.write(updated);

      expect(
        harness.documentStore.markdown,
        const DeckMarkdownCodec().encode(updated),
      );
      expect(harness.controller.slides.value, hasLength(2));
      expect(harness.controller.slides.value.last.options.title, 'Second');
      expect(observed, hasLength(2));
      expect(observed.last.options?.title, 'Second');
    },
  );

  test('read always decodes the current editor document', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.documentStore.replaceMarkdown(
      '---\ntitle: Changed\n---\n\n# Changed\n',
    );

    final slide = harness.store.read().single;

    expect(slide.options?.title, 'Changed');
  });

  test('invalid editor Markdown maps to deck_parse_failed', () {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.documentStore.replaceMarkdown(
      '---\nlayout: diagonal\n---\n\n# Invalid\n',
    );

    expect(
      harness.store.read,
      throwsA(
        isA<DeckToolError>().having(
          (error) => error.code,
          'code',
          DeckToolErrorCode.deckParseFailed,
        ),
      ),
    );
  });

  test('a preview timeout maps to deck_write_failed', () async {
    final editorLoader = MemoryDeckLoader();
    final silentLoader = _SilentDeckLoader();
    final controller = DeckController(
      deckLoader: silentLoader,
      options: DeckOptions(),
    );
    final editorStore = EditorStore();
    final documentStore = DeckDocumentStore(markdown: '# Initial');
    final editor = TextEditorController(
      editorStore: editorStore,
      deckLoader: editorLoader,
      documentStore: documentStore,
    );
    final store = EditorDeckStore(
      documentStore: documentStore,
      deckController: controller,
      barrierTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(() async {
      editor.dispose();
      editorStore.dispose();
      documentStore.dispose();
      controller.dispose();
      await editorLoader.dispose();
    });

    await expectLater(
      store.write([
        Slide(key: 'new', sections: [SectionBlock.text('# New')]),
      ]),
      throwsA(
        isA<DeckToolError>().having(
          (error) => error.code,
          'code',
          DeckToolErrorCode.deckWriteFailed,
        ),
      ),
    );
  });

  test(
    'restore preserves exact raw Markdown after the preview barrier',
    () async {
      const baseline = '# Baseline  \n\nText with trailing spaces.\n';
      final harness = _Harness(initialText: baseline);
      addTearDown(harness.dispose);
      await harness.store.synchronize();
      await harness.store.write([
        Slide(key: 'changed', sections: [SectionBlock.text('# Changed')]),
      ]);

      await harness.store.restore(baseline);

      expect(harness.documentStore.markdown, baseline);
      expect(harness.controller.slides.value.single.slide.sections, isNotEmpty);
    },
  );
}

class _Harness {
  _Harness({String initialText = '# Initial'})
    : loader = MemoryDeckLoader(),
      editorStore = EditorStore(),
      documentStore = DeckDocumentStore(markdown: initialText) {
    controller = DeckController(deckLoader: loader, options: DeckOptions());
    editor = TextEditorController(
      editorStore: editorStore,
      deckLoader: loader,
      documentStore: documentStore,
    );
    store = EditorDeckStore(
      documentStore: documentStore,
      deckController: controller,
    );
  }

  final MemoryDeckLoader loader;
  final EditorStore editorStore;
  final DeckDocumentStore documentStore;
  late final DeckController controller;
  late final TextEditorController editor;
  late final EditorDeckStore store;

  Future<void> dispose() async {
    editor.dispose();
    editorStore.dispose();
    documentStore.dispose();
    controller.dispose();
  }
}

class _SilentDeckLoader extends DeckLoader {
  final _controller = StreamController<SlidesEvent>.broadcast();

  @override
  Stream<SlidesEvent> load() => _controller.stream;

  @override
  Future<void> reload() async {}

  @override
  Future<void> dispose() => _controller.close();
}
