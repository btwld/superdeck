import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_image_style_catalog.dart';
import 'package:playground/features/ai/wizard/core/ai/wizard_context.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_selection_review.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders canonical selections and creates an outline', (
    tester,
  ) async {
    var createOutlineCalls = 0;
    final themeCatalog = PresentationThemeCatalog.withDefaults();
    final imageStyleCatalog = PresentationImageStyleCatalog.withDefaults();
    final theme = themeCatalog.currentThemes.first;
    final imageStyle = imageStyleCatalog.current(
      featuredPresentationImageStyleIds.first,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: WizardSelectionReview(
              wizardContext: WizardContext(
                topic: 'Urban gardens',
                audience: 'City planners',
                approach: 'Policy blueprint',
                emphasis: const ['Zoning', 'Community funding'],
                slideCount: 10,
                themeId: theme.id,
                imageStyleId: imageStyle.id,
                imageStyleVersion: imageStyle.version,
              ),
              themeCatalog: themeCatalog,
              imageStyleCatalog: imageStyleCatalog,
              onCreateOutline: () => createOutlineCalls++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Review your deck setup'), findsOneWidget);
    expect(find.text('Urban gardens'), findsOneWidget);
    expect(find.text('City planners'), findsOneWidget);
    expect(find.text('Policy blueprint'), findsOneWidget);
    expect(find.text('Zoning, Community funding'), findsOneWidget);
    expect(find.text('10 slides'), findsOneWidget);
    expect(find.text(theme.title), findsOneWidget);
    expect(find.text(imageStyle.title), findsOneWidget);

    await tester.ensureVisible(find.text('Create outline'));
    await tester.tap(find.text('Create outline'));
    expect(createOutlineCalls, 1);
  });
}
