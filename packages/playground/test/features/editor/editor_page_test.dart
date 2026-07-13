import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/app/router.dart';
import 'package:playground/features/editor/domain/stores/deck_file_controller.dart';
import 'package:playground/features/editor/presentation/pages/editor_page.dart';
import 'package:playground/features/editor/presentation/widgets/customization_sidebar.dart';
import 'package:playground/features/editor/presentation/widgets/new_deck_dialog.dart';
import 'package:playground/features/editor/presentation/widgets/preview_sidebar.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_deck_file_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app({
    FakeDeckFileStore? deckFileStore,
    FakeAppSettingsStore? appSettingsStore,
  }) {
    // In-memory store/settings so the editor's file-backed bootstrap resolves
    // without touching disk or spinning a real file watcher.
    return MaterialApp.router(
      routerConfig: createRouter(),
      builder: (context, child) => _Theme(
        child: AppProviders(
          deckFileStore: deckFileStore ?? FakeDeckFileStore(),
          appSettingsStore: appSettingsStore ?? FakeAppSettingsStore(),
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
    final fileStore = FakeDeckFileStore();
    await tester.pumpWidget(app(deckFileStore: fileStore));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final context = tester.element(find.byType(EditorPage));
    final controller = context.read<DeckFileController>();
    final path = controller.boundPath!;

    controller.handleEditorChange('# Final edit');
    final response = await tester.binding.handleRequestAppExit();

    expect(response, AppExitResponse.exit);
    expect(fileStore.files[path], '# Final edit');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('exit request is cancelled when the final save fails', (
    tester,
  ) async {
    final fileStore = FakeDeckFileStore();
    await tester.pumpWidget(app(deckFileStore: fileStore));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final context = tester.element(find.byType(EditorPage));
    final controller = context.read<DeckFileController>();
    fileStore.failWrites = true;

    controller.handleEditorChange('# Cannot persist');
    final response = await tester.binding.handleRequestAppExit();

    expect(response, AppExitResponse.cancel);
    expect(controller.warning, isNotNull);

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
    final controller = context.read<DeckFileController>();
    unawaited(showNewDeckDialog(context, controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Saved as a .md file in SuperDeck app storage'),
      findsOneWidget,
    );

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
