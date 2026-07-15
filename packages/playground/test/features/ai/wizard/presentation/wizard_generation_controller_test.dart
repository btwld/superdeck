import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_theme_resolution.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_validation_issue.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_generation_controller.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  test('plans, edits, and composes the exact approved outline', () async {
    const request = DeckGenerationRequest(
      userIntent: 'Urban gardens',
      slideCount: 1,
      themeId: 'technical-paper',
    );
    final service = _FakeWizardGenerationService(_plan(request));
    DeckGenerationResult? appliedResult;
    final controller = WizardGenerationController(
      service: service,
      applyResult: (result) => appliedResult = result,
    );
    addTearDown(controller.dispose);

    await controller.createOutline(request);

    expect(controller.stage, WizardGenerationStage.outlineReview);
    expect(controller.plan, isNotNull);
    expect(
      controller.updateSlide(
        0,
        title: 'A greener city starts block by block',
        assertion: 'Small urban gardens create city-scale resilience.',
      ),
      isTrue,
    );

    await controller.generateSlides();

    expect(controller.stage, WizardGenerationStage.completed);
    expect(service.approvedPlan, isNotNull);
    expect(
      service.approvedPlan!.slides.single.title,
      'A greener city starts block by block',
    );
    expect(
      service.approvedPlan!.slides.single.assertion,
      'Small urban gardens create city-scale resilience.',
    );
    expect(appliedResult, isNotNull);
    expect(controller.result, same(appliedResult));
  });

  test(
    'keeps the approved outline available after composition failure',
    () async {
      const request = DeckGenerationRequest(
        userIntent: 'Urban gardens',
        slideCount: 1,
        themeId: 'technical-paper',
      );
      final service = _FakeWizardGenerationService(
        _plan(request),
        compositionError: 'Composition failed.',
      );
      final controller = WizardGenerationController(
        service: service,
        applyResult: (_) {},
      );
      addTearDown(controller.dispose);

      await controller.createOutline(request);
      await controller.generateSlides();

      expect(controller.stage, WizardGenerationStage.failed);
      expect(controller.failedPhase, WizardGenerationPhase.composition);
      expect(controller.errorMessage, 'Composition failed.');
      expect(controller.plan, isNotNull);

      controller.returnToOutline();
      expect(controller.stage, WizardGenerationStage.outlineReview);
    },
  );

  test('retries only failed slide slots and keeps accepted slides', () async {
    const request = DeckGenerationRequest(
      userIntent: 'Urban gardens',
      slideCount: 2,
      themeId: 'technical-paper',
    );
    final service = _FakeWizardGenerationService(
      _plan(request, slideKeys: const ['opening', 'evidence']),
      partialComposition: true,
    );
    final applied = <DeckGenerationResult>[];
    final controller = WizardGenerationController(
      service: service,
      applyResult: applied.add,
    );
    addTearDown(controller.dispose);

    await controller.createOutline(request);
    await controller.generateSlides();

    expect(controller.stage, WizardGenerationStage.completed);
    expect(controller.result?.isPartial, isTrue);
    expect(controller.result?.slides.map((slide) => slide.key), ['opening']);

    await controller.retryFailedSlides();

    expect(controller.stage, WizardGenerationStage.completed);
    expect(controller.result?.success, isTrue);
    expect(controller.result?.slides.map((slide) => slide.key), [
      'opening',
      'evidence',
    ]);
    expect(service.retryCalls, 1);
    expect(applied, hasLength(2));
  });

  test('cancels immediately and ignores the late planning result', () async {
    const request = DeckGenerationRequest(
      userIntent: 'Urban gardens',
      slideCount: 1,
      themeId: 'technical-paper',
    );
    final pending = Completer<DeckPlanningResult>();
    final service = _FakeWizardGenerationService(_plan(request))
      ..pendingPlanning = pending;
    final controller = WizardGenerationController(
      service: service,
      applyResult: (_) {},
    );
    addTearDown(controller.dispose);

    final planning = controller.createOutline(request);
    await Future<void>.delayed(Duration.zero);
    expect(controller.stage, WizardGenerationStage.planning);

    controller.cancel();
    expect(controller.stage, WizardGenerationStage.setup);

    pending.complete(DeckPlanningResult.success(_plan(request)));
    await planning;
    expect(controller.stage, WizardGenerationStage.setup);
  });

  testWidgets('keeps composing after the 30-second performance target', (
    tester,
  ) async {
    const request = DeckGenerationRequest(
      userIntent: 'Urban gardens',
      slideCount: 1,
      themeId: 'technical-paper',
    );
    final pending = Completer<DeckGenerationResult>();
    final service = _FakeWizardGenerationService(_plan(request))
      ..pendingComposition = pending;
    final controller = WizardGenerationController(
      service: service,
      applyResult: (_) {},
    );
    addTearDown(controller.dispose);

    await controller.createOutline(request);
    final composition = controller.generateSlides();
    await tester.pump();
    await tester.pump(
      WizardGenerationController.generationBudget + const Duration(seconds: 1),
    );

    expect(controller.stage, WizardGenerationStage.composing);
    expect(controller.errorMessage, isNull);

    pending.complete(_successfulResult(service, controller.plan!));
    await composition;

    expect(controller.stage, WizardGenerationStage.completed);
  });

  test('keeps the edited outline when regeneration fails', () async {
    const request = DeckGenerationRequest(
      userIntent: 'Urban gardens',
      slideCount: 1,
      themeId: 'technical-paper',
    );
    final service = _FakeWizardGenerationService(_plan(request));
    final controller = WizardGenerationController(
      service: service,
      applyResult: (_) {},
    );
    addTearDown(controller.dispose);

    await controller.createOutline(request);
    controller.updateSlide(
      0,
      title: 'Edited title',
      assertion: 'Edited assertion.',
    );
    service.planningError = 'Regeneration failed.';

    await controller.regenerateOutline();

    expect(controller.stage, WizardGenerationStage.failed);
    expect(controller.plan?.slides.single.title, 'Edited title');
    controller.returnToOutline();
    expect(controller.stage, WizardGenerationStage.outlineReview);
  });
}

DeckPlanType _plan(
  DeckGenerationRequest request, {
  List<String> slideKeys = const ['opening'],
}) {
  final themes = PresentationThemeCatalog.withDefaults();
  final typography = PresentationTypographyCatalog.withDefaults();
  final descriptor = themes.current(request.themeId!)!;
  return DeckPlanType.parse({
    'topic': request.userIntent,
    'story': 'Small interventions build toward city-scale resilience.',
    'theme': buildDeckThemeReference(
      descriptor: descriptor,
      request: request,
      typographyCatalog: typography,
    ),
    'sections': [
      {
        'key': 'main',
        'title': 'Main story',
        'purpose': 'Explain the opportunity.',
        'transition': 'Move from context to action.',
        'slideKeys': slideKeys,
      },
    ],
    'slides': [
      for (final key in slideKeys)
        {
          'key': key,
          'title': key == 'opening' ? 'Urban gardens matter' : 'The evidence',
          'purpose': 'Introduce the opportunity.',
          'sectionKey': 'main',
          'assertion': 'Urban gardens strengthen neighborhood resilience.',
          'contentUnits': ['One concrete supporting point'],
          'narrativeRole': key == 'opening' ? 'opening' : 'evidence',
          'contentBrief': 'Frame the opportunity clearly.',
          'continuity': 'Open the story and lead into action.',
          'composition': 'content',
          'treatment': 'content',
          'density': 'balanced',
          'elements': <Object?>[],
        },
    ],
  });
}

final class _FakeWizardGenerationService extends DeckGeneratorService {
  _FakeWizardGenerationService(
    this.planned, {
    this.compositionError,
    this.partialComposition = false,
  }) : super(apiKey: 'test-key');

  final DeckPlanType planned;
  final String? compositionError;
  final bool partialComposition;
  DeckPlanType? approvedPlan;
  Completer<DeckPlanningResult>? pendingPlanning;
  Completer<DeckGenerationResult>? pendingComposition;
  String? planningError;
  var retryCalls = 0;

  @override
  Future<DeckPlanningResult> plan(
    DeckGenerationRequest request, {
    onProgress,
    onTrace,
    isCancelled,
  }) async {
    if (pendingPlanning case final pending?) return pending.future;
    if (planningError case final error?) {
      return DeckPlanningResult.failure(error);
    }
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
    this.approvedPlan = approvedPlan;
    if (pendingComposition case final pending?) return pending.future;
    if (compositionError case final error?) {
      return DeckGenerationResult.failure(error);
    }
    if (partialComposition) {
      return DeckGenerationResult.partial(
        slides: [_generatedSlide('opening')],
        slideFailures: [
          SlideGenerationFailure(
            slideIndex: 2,
            slideKey: 'evidence',
            issues: const [
              GenerationValidationIssue(
                code: GenerationValidationCode.invalidSchema,
                category: GenerationValidationCategory.schema,
                severity: GenerationValidationSeverity.blocking,
                location: GenerationValidationLocation.visibleContent,
                message: 'Invalid slide JSON.',
              ),
            ],
          ),
        ],
        plan: approvedPlan,
        theme: resolveDeckThemeReference(
          approvedPlan.theme,
          themeCatalog: themeCatalog,
          typographyCatalog: typographyCatalog,
        ),
      );
    }
    return _successfulResult(this, approvedPlan);
  }

  @override
  Future<DeckGenerationResult> retryFailedSlides(
    DeckGenerationRequest request,
    DeckGenerationResult partialResult, {
    onProgress,
    onTrace,
    isCancelled,
  }) async {
    retryCalls++;
    return DeckGenerationResult.success(
      slides: [_generatedSlide('opening'), _generatedSlide('evidence')],
      plan: partialResult.plan!,
      theme: partialResult.theme!,
    );
  }
}

DeckGenerationResult _successfulResult(
  DeckGeneratorService service,
  DeckPlanType plan,
) => DeckGenerationResult.success(
  slides: [_generatedSlide('opening')],
  plan: plan,
  theme: resolveDeckThemeReference(
    plan.theme,
    themeCatalog: service.themeCatalog,
    typographyCatalog: service.typographyCatalog,
  ),
);

Slide _generatedSlide(String key) => Slide.parse({
  'key': key,
  'options': {'title': key, 'style': 'content'},
  'sections': [
    {
      'type': 'section',
      'blocks': [
        {
          'type': 'block',
          'content': '## $key\n\nOne concrete supporting point.',
        },
      ],
    },
  ],
});
