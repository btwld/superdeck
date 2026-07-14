import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/router.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/features/ai/quick_agent/domain/commands/generate_deck_command.dart';
import 'package:playground/features/ai/wizard/core/ui/components/sd_custom.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_page.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_view.dart';
import 'package:playground/features/editor/presentation/pages/editor_page.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('default route reports a missing API key immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: createRouter(),
        builder: (context, child) =>
            HeroTheme(data: HeroThemeData.light(), child: child!),
      ),
    );
    await tester.pump();

    expect(find.byType(WizardPage), findsOneWidget);
    expect(find.byType(WizardView), findsNothing);
    expect(find.byType(EditorPage), findsNothing);
    expect(find.text('Google AI API key is not configured'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('configured page opens the isolated Wizard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            HeroTheme(data: HeroThemeData.light(), child: child!),
        home: const WizardPage(isConfigured: true),
      ),
    );
    await tester.pump();

    expect(find.byType(WizardView), findsOneWidget);
    expect(find.byType(EditorPage), findsNothing);
    expect(find.text('Startup pitch deck'), findsOneWidget);
  });

  testWidgets('generated Markdown opens presentation mode', (tester) async {
    final loader = MemoryDeckLoader();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WizardPage(isConfigured: true),
        ),
        GoRoute(
          path: '/present/:index',
          builder: (context, state) =>
              const Scaffold(body: Text('Generated presentation')),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(loader.dispose);

    await tester.pumpWidget(
      Provider<MemoryDeckLoader>.value(
        value: loader,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              HeroTheme(data: HeroThemeData.light(), child: child!),
        ),
      ),
    );
    await tester.pump();

    final wizardContext = tester.element(find.byType(WizardView));
    wizardContext.read<DeckDocumentStore>().replaceMarkdown('''
---
title: Generated deck
---
@section
@block
# Generated deck
''');
    await tester.pumpAndSettle();

    expect(find.text('Generated presentation'), findsOneWidget);
  });

  testWidgets('generation failure is visible in the Wizard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            HeroTheme(data: HeroThemeData.light(), child: child!),
        home: const WizardPage(isConfigured: true),
      ),
    );
    await tester.pump();

    final wizardContext = tester.element(find.byType(WizardView));
    await wizardContext.read<GenerateDeckCommand>()('Generate a deck');
    await tester.pump();

    expect(
      find.textContaining('No Gemini API key configured.'),
      findsOneWidget,
    );
  });

  testWidgets('debug menu offers three direct-generation presets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            HeroTheme(data: HeroThemeData.light(), child: child!),
        home: const WizardPage(isConfigured: true),
      ),
    );
    await tester.pump();

    expect(find.text('Debug generate'), findsOneWidget);
    await tester.tap(find.text('Debug generate'));
    await tester.pumpAndSettle();

    expect(find.text('Investor pitch (6 slides)'), findsOneWidget);
    expect(find.text('Quarterly review (8 slides)'), findsOneWidget);
    expect(find.text('Team onboarding (7 slides)'), findsOneWidget);
    expect(find.byType(SdColorCircle), findsNWidgets(9));
    expect(find.text('Clean and technical'), findsOneWidget);
    expect(find.text('Editorial and professional'), findsOneWidget);
    expect(find.text('Friendly and modern'), findsOneWidget);

    await tester.tap(find.text('Investor pitch (6 slides)'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No Gemini API key configured.'),
      findsOneWidget,
    );
  });
}
