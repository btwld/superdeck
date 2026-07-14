import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/router.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_page.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_view.dart';
import 'package:playground/features/editor/presentation/pages/editor_page.dart';

import '../../../../helpers/fake_deck_file_repository.dart';

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
        builder: (context, child) => HeroTheme(
          data: HeroThemeData.light(),
          child: AppProviders(
            deckFileRepository: FakeDeckFileRepository(),
            imageGenerator: const UnavailableImageGenerator(),
            child: child!,
          ),
        ),
        home: const WizardPage(isConfigured: true),
      ),
    );
    await tester.pump();

    expect(find.byType(WizardView), findsOneWidget);
    expect(find.byType(EditorPage), findsNothing);
    expect(find.text('Startup pitch deck'), findsOneWidget);
  });
}
