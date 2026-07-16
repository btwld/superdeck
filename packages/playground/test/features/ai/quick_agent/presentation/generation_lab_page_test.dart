import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_theme_resolution.dart';
import 'package:playground/features/ai/quick_agent/presentation/pages/generation_lab_page.dart';

void main() {
  testWidgets('runs story planning separately from slide composition', (
    tester,
  ) async {
    const request = DeckGenerationRequest(
      userIntent: 'SuperDeck product story',
      slideCount: 10,
      themeId: 'bold-product',
    );
    final service = _FakeGenerationLabService(_plan(request));

    await tester.pumpWidget(
      MaterialApp(
        home: GenerationLabPage(generationService: service, isConfigured: true),
      ),
    );

    expect(find.text('SuperDeck booth story'), findsOneWidget);
    expect(find.text('10 slides'), findsOneWidget);
    expect(find.text('Bold Product'), findsOneWidget);
    expect(find.text('Gradient artwork'), findsOneWidget);
    expect(find.text('Montserrat + DM Sans'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Build slides'), 160);
    expect(
      tester.widget<OutlinedButton>(_buildSlidesButton()).onPressed,
      isNull,
    );

    await tester.tap(find.text('Generate story beats'));
    await tester.pumpAndSettle();

    expect(service.planCalls, 1);
    await tester.scrollUntilVisible(find.text('Story beats'), 200);
    expect(find.text('Story beats'), findsOneWidget);
    expect(find.text('Act 1 · The reveal'), findsOneWidget);
    expect(find.text('The blank-page problem'), findsOneWidget);
    expect(find.text('A rough idea needs a guided path.'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(_buildSlidesButton()).onPressed,
      isNotNull,
    );
    expect(service.compositionCalls, 0);
  });
}

Finder _buildSlidesButton() => find.ancestor(
  of: find.text('Build slides'),
  matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
);

DeckPlanType _plan(DeckGenerationRequest request) {
  final themes = PresentationThemeCatalog.withDefaults();
  final typography = PresentationTypographyCatalog.withDefaults();
  final descriptor = themes.current(request.themeId!)!;

  return DeckPlanType.parse({
    'topic': 'SuperDeck',
    'story': 'A rough idea becomes a presentation-ready story.',
    'theme': buildDeckThemeReference(
      descriptor: descriptor,
      request: request,
      typographyCatalog: typography,
    ),
    'sections': [
      {
        'key': 'reveal',
        'title': 'The reveal',
        'purpose': 'Introduce the transformation.',
        'transition': 'Move from friction to a guided workflow.',
        'slideKeys': ['blank-page'],
      },
    ],
    'slides': [
      {
        'key': 'blank-page',
        'title': 'The blank-page problem',
        'purpose': 'Frame the starting friction.',
        'sectionKey': 'reveal',
        'assertion': 'A rough idea needs a guided path.',
        'contentUnits': ['People begin with intent, not slide structure.'],
        'narrativeRole': 'opening',
        'contentBrief': 'Show the cost of starting from an empty canvas.',
        'continuity': 'Open with friction before revealing the workflow.',
        'composition': 'title',
        'treatment': 'hero',
        'density': 'spacious',
        'elements': <Object?>[],
      },
    ],
  });
}

final class _FakeGenerationLabService extends DeckGeneratorService {
  _FakeGenerationLabService(this.planned) : super(apiKey: 'test-key');

  final DeckPlanType planned;
  var planCalls = 0;
  var compositionCalls = 0;

  @override
  Future<DeckPlanningResult> plan(
    DeckGenerationRequest request, {
    onProgress,
    onTrace,
    isCancelled,
  }) async {
    planCalls++;
    return DeckPlanningResult.success(planned);
  }

  @override
  Future<DeckGenerationResult> generateFromPlan(
    DeckGenerationRequest request,
    DeckPlanType approvedPlan, {
    onProgress,
    onTrace,
    isCancelled,
  }) async {
    compositionCalls++;
    return DeckGenerationResult.failure('Not needed by this widget test.');
  }
}
