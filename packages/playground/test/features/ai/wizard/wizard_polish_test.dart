import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_progress.dart';
import 'package:playground/features/ai/wizard/chat/view/widgets/chat_genui_panels.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_question_cards.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_slider.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/catalog_question_step.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/summary_card.dart';
import 'package:playground/features/ai/wizard/core/utils/color_utils.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_generation_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget host(Widget child) {
    return MaterialApp(
      home: HeroTheme(
        data: HeroThemeData.light(),
        child: Scaffold(
          body: Center(child: SizedBox(width: 720, height: 720, child: child)),
        ),
      ),
    );
  }

  testWidgets('radio options have an icon before they are selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 220,
            child: RadioOptionCard(
              title: 'Executive team',
              description: 'Decisive and concise',
              selected: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('theme options combine palette and typography in one preview', (
    tester,
  ) async {
    final theme = PresentationThemeCatalog.withDefaults().current(
      'editorial-midnight',
    )!;

    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: StyleOptionCard(theme: theme, selected: false),
          ),
        ),
      ),
    );

    final heading = tester.widget<Text>(find.text('Build what’s next'));
    final subtitle = tester.widget<Text>(
      find.text('A clear story, beautifully presented.'),
    );

    expect(heading.style?.color, hexToColor(theme.recipe.palette.heading));
    expect(subtitle.style?.color, hexToColor(theme.recipe.palette.body));
    expect(find.text(theme.title), findsOneWidget);
    expect(find.text(theme.description), findsOneWidget);
    expect(find.text(theme.recipe.headlineFamily), findsNothing);
    expect(find.text(theme.recipe.bodyFamily), findsNothing);
  });

  testWidgets('wizard instructions use a plain heading and description', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        CatalogQuestionStep(
          question: 'Who should this deck persuade?',
          description: 'Choose the audience that matters most.',
          body: const SizedBox(height: 80),
          onSubmit: null,
        ),
      ),
    );

    expect(find.text('Who should this deck persuade?'), findsOneWidget);
    expect(find.text('Choose the audience that matters most.'), findsOneWidget);
  });

  testWidgets('active wizard controls keep the available panel width', (
    tester,
  ) async {
    final inputKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 720,
                height: 600,
                child: AiSurfacesPanel(
                  controller: null,
                  surfaceIds: const [],
                  isThinking: false,
                  inputWidget: SizedBox(key: inputKey, height: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(inputKey)).width, 720);
  });

  testWidgets('missing surfaces show a flat recovery message', (tester) async {
    await tester.pumpWidget(
      host(
        const AiSurfacesPanel(
          controller: null,
          surfaceIds: [],
          isThinking: false,
          errorMessage: 'I couldn\'t prepare the next step.',
          inputWidget: SizedBox(height: 48),
        ),
      ),
    );

    expect(find.text('I couldn\'t prepare the next step.'), findsOneWidget);
  });

  testWidgets('generation status communicates the active pipeline stage', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const WizardGenerationStatus(
          kind: WizardGenerationStatusKind.running,
          progress: GenerationProgress(
            GenerationPhase.composingSlides,
            sectionIndex: 2,
            sectionCount: 4,
          ),
        ),
      ),
    );

    expect(find.text('Building your presentation'), findsOneWidget);
    expect(find.text('Composing section 2 of 4…'), findsOneWidget);
    expect(find.text('Shape the story'), findsOneWidget);
    expect(find.text('Compose the slides'), findsOneWidget);
    expect(find.text('Polish the deck'), findsOneWidget);
  });

  testWidgets('generation failure keeps a path back to the deck plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const WizardGenerationStatus(
          kind: WizardGenerationStatusKind.failed,
          errorMessage: 'The service did not return valid slide JSON.',
        ),
      ),
    );

    expect(find.text('We couldn\'t finish the deck'), findsOneWidget);
    expect(
      find.text('The service did not return valid slide JSON.'),
      findsOneWidget,
    );
    expect(find.text('Back to deck plan'), findsOneWidget);
  });

  testWidgets('partial generation completes with a visible warning', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const WizardGenerationStatus(
          kind: WizardGenerationStatusKind.completed,
          noticeMessage: 'Generated 11 of 12 slides; one slide was skipped.',
        ),
      ),
    );

    expect(find.text('Your presentation is ready'), findsOneWidget);
    expect(
      find.text('Generated 11 of 12 slides; one slide was skipped.'),
      findsOneWidget,
    );
    expect(find.text('Back to deck plan'), findsOneWidget);
  });

  testWidgets('summary ends with a sentence-case generation action', (
    tester,
  ) async {
    final items = [
      SummaryItemType.parse({
        'kind': 'text',
        'label': 'Audience',
        'title': 'Executive leadership',
        'description': 'Decisive and concise',
      }),
      SummaryItemType.parse({
        'kind': 'text',
        'label': 'Length',
        'text': '12 slides',
      }),
    ];

    await tester.pumpWidget(
      host(
        SummaryCard(
          title: 'Your deck plan',
          items: items,
          themeCatalog: PresentationThemeCatalog.withDefaults(),
        ),
      ),
    );

    expect(find.text('Your deck plan'), findsOneWidget);
    expect(find.text('Audience'), findsOneWidget);
    expect(find.text('12 slides'), findsOneWidget);
    expect(find.text('Generate slides'), findsOneWidget);
  });

  testWidgets('deck length uses a counter and useful presets', (tester) async {
    var selectedValue = 10;

    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => DeckLengthSelector(
            value: selectedValue,
            min: 5,
            max: 20,
            onChanged: (value) => setState(() => selectedValue = value),
          ),
        ),
      ),
    );

    expect(find.text('Deck length'), findsOneWidget);
    expect(find.text('10'), findsNWidgets(2));

    await tester.tap(find.byTooltip('One more slide'));
    await tester.pump();
    expect(find.text('11'), findsOneWidget);

    await tester.tap(find.text('20'));
    await tester.pump();
    expect(selectedValue, 20);
  });
}
