import 'dart:async';
import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/app/router.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/features/ai/deck_editor/presentation/deck_edit_screen.dart';
import 'package:playground/features/ai/deck_editor/presentation/deck_edit_session_controller.dart';
import 'package:playground/features/ai/wizard/core/ai/services/ai_conversation_profile.dart';
import 'package:playground/features/ai/wizard/core/ai/services/ai_conversation_viewmodel.dart';
import 'package:playground/features/ai/wizard/core/ai/services/superdeck_agent_client.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:playground/features/editor/domain/stores/editor_store.dart';
import 'package:playground/features/editor/presentation/pages/editor_page.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../../helpers/fake_deck_file_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'pushed route retains the exact document store and becomes ready',
    (tester) async {
      await _pumpApp(tester);
      await tester.pump();
      final documentStore = _read<DeckDocumentStore>(
        tester,
        find.byType(EditorPage),
      );

      await tester.tap(find.byKey(const Key('edit-with-ai')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DeckEditScreen), findsOneWidget);
      final screen = tester.widget<DeckEditScreen>(find.byType(DeckEditScreen));
      expect(screen.args.documentStore, same(documentStore));
      expect(
        tester
            .widget<IgnorePointer>(
              find.byKey(const Key('deck-edit-input-gate')),
            )
            .ignoring,
        isFalse,
      );
    },
  );

  testWidgets('direct route entry without live args redirects to editor', (
    tester,
  ) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await _pumpApp(tester, router: router);

    router.go('/ai/edit');
    await tester.pump();
    await tester.pump();

    expect(find.byType(EditorPage), findsOneWidget);
    expect(find.byType(DeckEditScreen), findsNothing);
  });

  testWidgets('Apply keeps AI Markdown and clamps the entry slide position', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.pump();
    final documentStore = _read<DeckDocumentStore>(
      tester,
      find.byType(EditorPage),
    );
    final editorStore = _read<EditorStore>(tester, find.byType(EditorPage));
    documentStore.replaceMarkdown('# One\n\n---\n\n# Two\n');
    editorStore.activeSlideIndex = 1;
    await tester.pump();
    await tester.tap(find.byKey(const Key('edit-with-ai')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final session = _read<DeckEditSessionController>(
      tester,
      find.byKey(const Key('deck-edit-input-gate')),
    );

    await session.tools.deleteSlide(1);
    await tester.pump();
    await tester.tap(find.byKey(const Key('deck-edit-apply')));
    await tester.pumpAndSettle();

    expect(find.byType(EditorPage), findsOneWidget);
    expect(find.byType(DeckEditScreen), findsNothing);
    expect(documentStore.markdown, contains('# One'));
    expect(documentStore.markdown, isNot(contains('# Two')));
    expect(editorStore.activeSlideIndex, 0);
  });

  testWidgets(
    'Discard restores exact Markdown, customization, and slide position',
    (tester) async {
      await _pumpApp(tester);
      await tester.pump();
      final documentStore = _read<DeckDocumentStore>(
        tester,
        find.byType(EditorPage),
      );
      final editorStore = _read<EditorStore>(tester, find.byType(EditorPage));
      final customization = _read<DeckCustomizationStore>(
        tester,
        find.byType(EditorPage),
      );
      const baseline = '# One  \n\n---\n\n# Two\n';
      documentStore.replaceMarkdown(baseline);
      editorStore.activeSlideIndex = 1;
      final customizationBaseline = customization.captureSnapshot();
      await tester.pump();
      await tester.tap(find.byKey(const Key('edit-with-ai')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final session = _read<DeckEditSessionController>(
        tester,
        find.byKey(const Key('deck-edit-input-gate')),
      );

      await session.tools.createSlide(
        Slide(key: 'new', sections: [SectionBlock.text('# New')]),
      );
      await session.tools.updateStyle({
        'name': 'Changed',
        'colors': {
          'background': '#123456',
          'heading': '#ABCDEF',
          'body': '#FEDCBA',
        },
        'fonts': {'headline': 'poppins', 'body': 'roboto'},
      });
      await tester.pump();
      await tester.tap(find.byKey(const Key('deck-edit-discard')));
      await tester.pumpAndSettle();

      expect(find.byType(EditorPage), findsOneWidget);
      expect(find.byType(DeckEditScreen), findsNothing);
      expect(documentStore.markdown, baseline);
      expect(customization.background, customizationBaseline.background);
      expect(
        customization.level(TextLevel.h1).family,
        customizationBaseline.level(TextLevel.h1).family,
      );
      expect(editorStore.activeSlideIndex, 1);
    },
  );

  testWidgets('dirty Back requires an Apply or Discard decision', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.pump();
    final documentStore = _read<DeckDocumentStore>(
      tester,
      find.byType(EditorPage),
    );
    final baseline = documentStore.markdown;
    await tester.tap(find.byKey(const Key('edit-with-ai')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final session = _read<DeckEditSessionController>(
      tester,
      find.byKey(const Key('deck-edit-input-gate')),
    );
    await session.tools.createSlide(
      Slide(key: 'new', sections: [SectionBlock.text('# New')]),
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Keep AI deck changes?'), findsOneWidget);
    expect(find.byType(DeckEditScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('deck-edit-back-discard')));
    await tester.pumpAndSettle();
    expect(find.byType(DeckEditScreen), findsNothing);
    expect(documentStore.markdown, baseline);
  });

  testWidgets('request startup through streaming blocks actions and pop', (
    tester,
  ) async {
    final gate = Completer<void>();
    AiConversationViewModel conversationFactory(AiConversationProfile profile) {
      return AiConversationViewModel(
        profile: profile,
        apiKeyProvider: () => 'test-api-key',
        agentClientFactory:
            ({required apiKey, required modelName, required tools}) =>
                _GatedAgentClient(gate.future),
      );
    }

    final router = createRouter(
      deckEditConversationFactory: conversationFactory,
    );
    addTearDown(router.dispose);
    await _pumpApp(tester, router: router);
    await tester.pump();
    await tester.tap(find.byKey(const Key('edit-with-ai')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final session = _read<DeckEditSessionController>(
      tester,
      find.byKey(const Key('deck-edit-input-gate')),
    );

    final request = session.sendMessage('Inspect the deck');
    await tester.pump();

    expect(session.requestInFlight, isTrue);
    expect(
      tester
          .widget<IgnorePointer>(find.byKey(const Key('deck-edit-input-gate')))
          .ignoring,
      isTrue,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('deck-edit-apply')))
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(DeckEditScreen), findsOneWidget);
    expect(find.text('Keep AI deck changes?'), findsNothing);

    gate.complete();
    await request;
    await tester.pump();
    expect(session.requestInFlight, isFalse);

    final uiGate = Completer<void>();
    session.viewModel.onUiRequest!(uiGate.future);
    await tester.pump();
    expect(session.requestInFlight, isTrue);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('deck-edit-apply')))
          .onPressed,
      isNull,
    );
    uiGate.complete();
    await tester.pump();
    expect(session.requestInFlight, isFalse);
  });

  testWidgets('two mutations, capture, and Apply update editor and preview', (
    tester,
  ) async {
    final router = _captureRouter();
    addTearDown(router.dispose);
    await _pumpApp(tester, router: router);
    await tester.pump();
    final documentStore = _read<DeckDocumentStore>(
      tester,
      find.byType(EditorPage),
    );
    final deckController = _read<DeckController>(
      tester,
      find.byType(EditorPage),
    );
    await tester.tap(find.byKey(const Key('edit-with-ai')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final session = _read<DeckEditSessionController>(
      tester,
      find.byKey(const Key('deck-edit-input-gate')),
    );

    await Future.wait([
      session.tools.createSlide(
        Slide(key: 'two', sections: [SectionBlock.text('# Two')]),
      ),
      session.tools.createSlide(
        Slide(key: 'three', sections: [SectionBlock.text('# Three')]),
      ),
    ]);
    final captured = await session.tools.readSlide(2);

    expect(captured['thumbnailBase64'], isNot(isEmpty));
    expect(deckController.slides.value, hasLength(3));
    await tester.tap(find.byKey(const Key('deck-edit-apply')));
    await tester.pumpAndSettle();
    expect(find.byType(DeckEditScreen), findsNothing);
    expect(documentStore.markdown, contains('# Two'));
    expect(documentStore.markdown, contains('# Three'));
    expect(deckController.slides.value, hasLength(3));
  });

  testWidgets('two mutations, capture, and Discard restore the baseline', (
    tester,
  ) async {
    final router = _captureRouter();
    addTearDown(router.dispose);
    await _pumpApp(tester, router: router);
    await tester.pump();
    final documentStore = _read<DeckDocumentStore>(
      tester,
      find.byType(EditorPage),
    );
    final deckController = _read<DeckController>(
      tester,
      find.byType(EditorPage),
    );
    final baseline = documentStore.markdown;
    await tester.tap(find.byKey(const Key('edit-with-ai')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final session = _read<DeckEditSessionController>(
      tester,
      find.byKey(const Key('deck-edit-input-gate')),
    );

    await Future.wait([
      session.tools.createSlide(
        Slide(key: 'two', sections: [SectionBlock.text('# Two')]),
      ),
      session.tools.updateSlide(
        0,
        Slide(key: 'changed', sections: [SectionBlock.text('# Changed')]),
      ),
    ]);
    final captured = await session.tools.readSlide(1);

    expect(captured['thumbnailBase64'], isNot(isEmpty));
    await tester.tap(find.byKey(const Key('deck-edit-discard')));
    await tester.pumpAndSettle();
    expect(find.byType(DeckEditScreen), findsNothing);
    expect(documentStore.markdown, baseline);
    expect(deckController.slides.value, hasLength(1));
  });
}

Widget _app({GoRouter? router}) {
  return MaterialApp.router(
    routerConfig: router ?? createRouter(),
    builder: (context, child) => _Theme(
      child: AppProviders(
        deckFileRepository: FakeDeckFileRepository(),
        child: child!,
      ),
    ),
  );
}

Future<void> _pumpApp(WidgetTester tester, {GoRouter? router}) async {
  await tester.pumpWidget(_app(router: router));
}

GoRouter _captureRouter() {
  return createRouter(
    deckEditCapture:
        ({required context, required quality, required slide}) async {
          return Uint8List.fromList([137, 80, 78, 71]);
        },
  );
}

T _read<T>(WidgetTester tester, Finder finder) {
  return Provider.of<T>(tester.element(finder), listen: false);
}

class _Theme extends StatelessWidget {
  const _Theme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HeroTheme(
      data: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? .dark()
          : .light(),
      child: child,
    );
  }
}

class _GatedAgentClient implements SuperdeckAgentClient {
  const _GatedAgentClient(this.gate);

  final Future<void> gate;

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    await gate;
    yield const SuperdeckAgentResponseChunk(text: 'Done');
  }

  @override
  void dispose() {}
}
