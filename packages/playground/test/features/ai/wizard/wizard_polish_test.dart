import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_progress.dart';
import 'package:playground/features/ai/wizard/chat/view/widgets/chat_input.dart';
import 'package:playground/features/ai/wizard/chat/view/widgets/chat_genui_panels.dart';
import 'package:playground/features/ai/wizard/chat/view/widgets/empty_state.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_question_cards.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_slider.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/catalog_question_step.dart';
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

  testWidgets('opening topic input is ready for keyboard entry', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      host(
        ChatInput(
          controller: controller,
          autofocus: true,
          enabled: true,
          onSubmitted: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('first-turn failures remain visible beside the topic input', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const EmptyState(
          errorMessage: 'The first Wizard step could not be prepared.',
          input: SizedBox(height: 48),
        ),
      ),
    );

    expect(
      find.text('The first Wizard step could not be prepared.'),
      findsOneWidget,
    );
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
        WizardGenerationStatus(
          kind: WizardGenerationStatusKind.running,
          progress: const GenerationProgress(
            GenerationPhase.composingSlides,
            sectionIndex: 2,
            sectionCount: 4,
          ),
          onCancel: () {},
        ),
      ),
    );

    expect(find.text('Building your presentation'), findsOneWidget);
    expect(find.text('Composed section 2 of 4…'), findsOneWidget);
    expect(find.text('Shape the story'), findsOneWidget);
    expect(find.text('Create the artwork'), findsOneWidget);
    expect(find.text('Compose the slides'), findsOneWidget);
    expect(find.text('Polish the deck'), findsOneWidget);
    expect(find.text('Usually 20–30 seconds'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, isNotNull);
    expect(indicator.value, greaterThan(0));
  });

  testWidgets('generation failure keeps a path back to the deck plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        WizardGenerationStatus(
          kind: WizardGenerationStatusKind.failed,
          planAvailable: true,
          errorMessage: 'The service did not return valid slide JSON.',
          onRetry: () {},
          onBack: () {},
        ),
      ),
    );

    expect(find.text('We couldn\'t finish the deck'), findsOneWidget);
    expect(
      find.text('The service did not return valid slide JSON.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Edit outline'), findsOneWidget);
  });

  testWidgets('partial generation completes with a visible warning', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        WizardGenerationStatus(
          kind: WizardGenerationStatusKind.completed,
          noticeMessage: 'Generated 11 of 12 slides; one slide was skipped.',
          slideCount: 11,
          failedSlideCount: 1,
          elapsed: const Duration(seconds: 24),
          onRetryFailed: () {},
          onPresent: () {},
          onEditOutline: () {},
          onStartOver: () {},
        ),
      ),
    );

    expect(find.text('Your presentation is almost ready'), findsOneWidget);
    expect(
      find.text('Generated 11 of 12 slides; one slide was skipped.'),
      findsOneWidget,
    );
    expect(find.text('11 slides • 24s'), findsOneWidget);
    expect(find.text('Present deck'), findsOneWidget);
    expect(find.text('Retry 1 slide'), findsOneWidget);
    expect(find.text('Edit outline'), findsOneWidget);
    expect(find.text('Start over'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(HeroButton), findsNWidgets(4));
  });

  testWidgets('artwork fallback stays visible on successful completion', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        WizardGenerationStatus(
          kind: WizardGenerationStatusKind.completed,
          noticeMessage:
              'Created 2 of 3 planned artworks. 1 image uses a text-first fallback.',
          slideCount: 10,
          artworkCount: 2,
          failedArtworkCount: 1,
          elapsed: const Duration(seconds: 27),
          onPresent: () {},
          onEditOutline: () {},
          onStartOver: () {},
        ),
      ),
    );

    expect(find.text('Your presentation is ready'), findsOneWidget);
    expect(
      find.text(
        'The deck is ready, with a text-first fallback where artwork was unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.text('10 slides • 2 artworks • 27s'), findsOneWidget);
    expect(
      find.text(
        'Created 2 of 3 planned artworks. 1 image uses a text-first fallback.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('deck length offers four plain slide-count choices', (
    tester,
  ) async {
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
    expect(find.text('5 slides'), findsOneWidget);
    expect(find.text('10 slides'), findsOneWidget);
    expect(find.text('15 slides'), findsOneWidget);
    expect(find.text('20 slides'), findsOneWidget);
    expect(find.text('Custom'), findsNothing);
    expect(find.byTooltip('One more slide'), findsNothing);

    await tester.tap(find.text('20 slides'));
    await tester.pump();
    expect(selectedValue, 20);
  });
}
