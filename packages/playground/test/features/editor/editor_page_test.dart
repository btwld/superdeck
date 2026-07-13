import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/app/router.dart';
import 'package:playground/features/editor/domain/files/deck_file.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:playground/features/editor/domain/stores/deck_file_session.dart';
import 'package:playground/features/editor/presentation/pages/editor_page.dart';
import 'package:playground/features/editor/presentation/widgets/customization_sidebar.dart';
import 'package:playground/features/editor/presentation/widgets/new_deck_dialog.dart';
import 'package:playground/features/editor/presentation/widgets/preview_sidebar.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_deck_file_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app({FakeDeckFileRepository? deckFileRepository}) {
    // In-memory repository so the file-backed bootstrap resolves without
    // touching disk or spinning a real file watcher.
    return MaterialApp.router(
      routerConfig: createRouter(),
      builder: (context, child) => _Theme(
        child: AppProviders(
          deckFileRepository: deckFileRepository ?? FakeDeckFileRepository(),
          child: child!,
        ),
      ),
    );
  }

  testWidgets('editor route builds with its sidebars', (tester) async {
    await tester.pumpWidget(app());
    // Let the async bootstrap (seed the in-memory default deck) resolve so the
    // editor mounts past its loading spinner.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(EditorPage), findsOneWidget);
    expect(find.byType(PreviewSidebar), findsOneWidget);
    expect(find.byType(CustomizationSidebar), findsOneWidget);

    // The customization sidebar defaults to the Wizard tab; switch to the
    // Editor tab so its 'Background' section label renders.
    await tester.tap(find.text('Editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Background'), findsOneWidget);

    // Unmount so the editor's controllers/coordinator dispose and cancel their
    // timers, then drain any pending one-shot timers (thumbnail scheduling,
    // deck transition) before the test's timer invariant runs.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('exit request flushes the final debounced edit', (tester) async {
    final repository = FakeDeckFileRepository();
    await tester.pumpWidget(app(deckFileRepository: repository));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final context = tester.element(find.byType(EditorPage));
    final session = context.read<DeckFileSession>();
    final path = session.boundPath!;

    context.read<DeckDocumentStore>().replaceMarkdown('# Final edit');
    final response = await tester.binding.handleRequestAppExit();

    expect(response, AppExitResponse.exit);
    expect(repository.files[path], '# Final edit');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('exit request is cancelled when the final save fails', (
    tester,
  ) async {
    final repository = FakeDeckFileRepository();
    await tester.pumpWidget(app(deckFileRepository: repository));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final context = tester.element(find.byType(EditorPage));
    final session = context.read<DeckFileSession>();
    repository.failWrites = true;

    context.read<DeckDocumentStore>().replaceMarkdown('# Cannot persist');
    final response = await tester.binding.handleRequestAppExit();

    expect(response, AppExitResponse.cancel);
    expect(session.warning, isNotNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('new deck dialog describes sandboxed app storage', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(EditorPage));
    final session = context.read<DeckFileSession>();
    unawaited(showNewDeckDialog(context, session));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Saved as a .md file in SuperDeck app storage'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Command-N opens the new deck dialog', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();

    expect(find.text('New deck'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Command-O opens the picked deck', (tester) async {
    final repository = FakeDeckFileRepository()
      ..files['/decks/opened.md'] = '# Opened deck'
      ..pickResult = const DeckFileReference(path: '/decks/opened.md');
    await tester.pumpWidget(app(deckFileRepository: repository));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final context = tester.element(find.byType(EditorPage));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.pump();

    expect(context.read<DeckFileSession>().boundPath, '/decks/opened.md');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
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
