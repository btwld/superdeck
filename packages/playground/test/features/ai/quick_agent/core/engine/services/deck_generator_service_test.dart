import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_model_client.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_progress.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_trace.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_validation_issue.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/retry_policy.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rejects an outline that violates the typed request count', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The outline must have the requested number of slides.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'only-one')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The repaired outline is still incomplete.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'still-only-one')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The final outline repair is still incomplete.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'still-incomplete')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The bounded outline repairs remain incomplete.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'still-invalid')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The final bounded repair remains incomplete.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'still-invalid-final')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The extra semantic sweep remains incomplete.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'still-invalid-extra')],
      }),
    ]);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      maxOutlineValidationAttempts: 6,
      maxRepairRequests: 5,
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      const DeckGenerationRequest(
        userIntent: 'Create a concise two-slide explanation.',
        slideCount: 2,
        headlineFont: 'Montserrat',
        bodyFont: 'Inter',
      ),
    );

    expect(result.success, isFalse);
    expect(client.requests, hasLength(6));
    final input = client.requests.first.contents.single.parts.single.text!;
    expect(jsonDecode(input), containsPair('slideCount', 2));
  });

  test('repairs one semantically invalid outline before composition', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Repair contract',
        'story': 'The first outline has the wrong count.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'only-one')],
      }),
      _jsonResponse({
        'topic': 'Repair contract',
        'story': 'The repaired outline now has the exact requested count.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'opening'), _planSlide(key: 'closing')],
      }),
      _jsonResponse(
        _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
      ),
      _jsonResponse(
        _generatedSlide(key: 'closing', title: 'Closing', style: 'content'),
      ),
    ]);
    final traces = <GenerationTraceEvent>[];
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create two connected slides.', slideCount: 2),
      onTrace: traces.add,
    );

    expect(result.success, isTrue);
    expect(result.slides, hasLength(2));
    expect(client.requests, hasLength(4));
    expect(client.requests.map((request) => request.model), [
      'models/gemini-3.5-flash',
      'models/gemini-3.1-flash-lite',
      'models/gemini-3.1-flash-lite',
      'models/gemini-3.1-flash-lite',
    ]);
    final repairPrompt =
        client.requests[1].systemInstruction!.parts.single.text!;
    expect(repairPrompt, contains('Deck plan has 1 slides'));
    expect(repairPrompt, contains('only-one'));
    expect(
      traces
          .where(
            (event) =>
                event.kind == GenerationTraceKind.request &&
                event.phase == GenerationTracePhase.outline,
          )
          .map((event) => event.attempt),
      [1, 2],
    );
  });

  test('repairs slide-scoped plan errors without rewriting the deck', () async {
    final invalidSlide = {
      ..._planSlide(key: 'opening'),
      'contentUnits': ['Start your free trial today'],
    };
    invalidSlide.remove('elements');
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Local plan repair',
        'story': 'Repair only the invalid slide content.',
        'theme': _testThemeSelection,
        'slides': [invalidSlide],
      }),
      _jsonResponse(_planSlide(key: 'opening')),
      _jsonResponse(
        _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
      ),
    ]);
    final traces = <GenerationTraceEvent>[];
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create one grounded opening slide.', slideCount: 1),
      onTrace: traces.add,
    );

    expect(result.success, isTrue);
    expect(client.requests, hasLength(3));
    expect(
      client.requests[1].systemInstruction!.parts.single.text,
      allOf(
        contains('repair exactly one slide'),
        contains('Start your free trial today'),
        contains('unsupported commitment claim(s): free trial'),
        contains('`groundedNumericFacts` are authoritative'),
        contains('turning 31% into 69%'),
      ),
    );
    final outlineRequests = traces.where(
      (event) =>
          event.kind == GenerationTraceKind.request &&
          event.phase == GenerationTracePhase.outline,
    );
    expect(outlineRequests.map((event) => event.slideIndex), [null, 1]);
    expect(result.plan!.slides.single.contentUnits, [
      'One concrete supporting point',
    ]);
  });

  test('repairs multiple invalid plan slides with targeted requests', () async {
    final firstInvalid = {
      ..._planSlide(key: 'opening'),
      'contentUnits': ['Start your free trial today'],
    };
    final secondInvalid = {
      ..._planSlide(key: 'closing'),
      'contentUnits': ['Join the waitlist today'],
    };
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Targeted plan repair',
        'story': 'Repair several plan slides without rewriting the deck.',
        'theme': _testThemeSelection,
        'slides': [firstInvalid, secondInvalid],
      }),
      _jsonResponse(_planSlide(key: 'opening')),
      _jsonResponse(_planSlide(key: 'closing')),
      _jsonResponse(
        _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
      ),
      _jsonResponse(
        _generatedSlide(key: 'closing', title: 'Closing', style: 'content'),
      ),
    ]);
    final traces = <GenerationTraceEvent>[];
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create a grounded two-slide deck.', slideCount: 2),
      onTrace: traces.add,
    );

    expect(result.success, isTrue);
    expect(client.requests, hasLength(5));
    expect(
      traces
          .where(
            (event) =>
                event.kind == GenerationTraceKind.request &&
                event.phase == GenerationTracePhase.outline,
          )
          .map((event) => event.slideIndex),
      [null, 1, 2],
    );
    final openingRepairPrompt =
        client.requests[1].systemInstruction!.parts.single.text!;
    final closingRepairPrompt =
        client.requests[2].systemInstruction!.parts.single.text!;
    expect(openingRepairPrompt, contains('repair exactly one slide'));
    expect(openingRepairPrompt, contains('Start your free trial today'));
    expect(closingRepairPrompt, contains('repair exactly one slide'));
    expect(closingRepairPrompt, contains('Join the waitlist today'));
  });

  test('repairs three invalid plan slides with one deck request', () async {
    final invalidSlides = [
      {
        ..._planSlide(key: 'opening'),
        'contentUnits': ['Start your free trial today'],
      },
      {
        ..._planSlide(key: 'evidence'),
        'contentUnits': ['Join the waitlist today'],
      },
      {
        ..._planSlide(key: 'closing'),
        'contentUnits': ['SOC2 compliance is included'],
      },
    ];
    final validSlides = [
      _planSlide(key: 'opening'),
      _planSlide(key: 'evidence'),
      _planSlide(key: 'closing'),
    ];
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Bounded global repair',
        'story': 'Repair a broad invalid plan in one request.',
        'theme': _testThemeSelection,
        'slides': invalidSlides,
      }),
      _jsonResponse({
        'topic': 'Bounded global repair',
        'story': 'Repair a broad invalid plan in one request.',
        'theme': _testThemeSelection,
        'slides': validSlides,
      }),
      for (final (index, slide) in validSlides.indexed)
        _jsonResponse(
          _generatedSlide(
            key: slide['key']! as String,
            title: 'Slide ${index + 1}',
            style: 'content',
          ),
        ),
    ]);
    final traces = <GenerationTraceEvent>[];
    final result =
        await DeckGeneratorService(
          apiKey: 'test-key',
          modelClientFactory: (_) => client,
        ).generate(
          _request('Create a grounded three-slide deck.', slideCount: 3),
          onTrace: traces.add,
        );

    expect(result.success, isTrue, reason: result.error);
    expect(client.requests, hasLength(5));
    expect(
      traces
          .where(
            (event) =>
                event.kind == GenerationTraceKind.request &&
                event.phase == GenerationTracePhase.outline,
          )
          .map((event) => event.slideIndex),
      [null, null],
    );
    expect(
      client.requests[1].systemInstruction!.parts.single.text,
      startsWith('You repair one SuperDeck deck plan.'),
    );
  });

  test(
    'repairs multiple remaining slide issues after one deck-plan repair',
    () async {
      final invalidOpening = {
        ..._planSlide(key: 'opening'),
        'contentUnits': ['Start your free trial today'],
        'treatment': 'data',
      };
      final invalidClosing = {
        ..._planSlide(key: 'closing'),
        'contentUnits': ['Join the waitlist today'],
      };
      final client = _FakeGenerationModelClient([
        _jsonResponse({
          'topic': 'Layered plan repair',
          'story': 'Repair the global shape, then the remaining local copy.',
          'theme': _testThemeSelection,
          'slides': [invalidOpening, invalidClosing],
        }),
        _jsonResponse({
          'topic': 'Layered plan repair',
          'story': 'Repair the global shape, then the remaining local copy.',
          'theme': _testThemeSelection,
          'slides': [
            {
              ..._planSlide(key: 'opening'),
              'contentUnits': ['Start your free trial today'],
            },
            invalidClosing,
          ],
        }),
        _jsonResponse(_planSlide(key: 'opening')),
        _jsonResponse(_planSlide(key: 'closing')),
        _jsonResponse(
          _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
        ),
        _jsonResponse(
          _generatedSlide(key: 'closing', title: 'Closing', style: 'content'),
        ),
      ]);
      final service = DeckGeneratorService(
        apiKey: 'test-key',
        modelClientFactory: (_) => client,
      );

      final result = await service.generate(
        _request('Create a grounded two-slide deck.', slideCount: 2),
      );

      expect(result.success, isTrue, reason: result.error);
      expect(client.requests, hasLength(6));
      expect(
        client.requests
            .take(4)
            .map((request) => request.systemInstruction!.parts.single.text!),
        [
          isNot(contains('repair exactly one slide')),
          startsWith('You repair one SuperDeck deck plan.'),
          contains('repair exactly one slide'),
          contains('repair exactly one slide'),
        ],
      );
    },
  );

  test('resolves the selected catalog theme without a model repair', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Catalog theme',
        'story': 'Resolve the selected theme locally.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'opening')],
      }),
      _jsonResponse(
        _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
      ),
    ]);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create one themed slide.', slideCount: 1),
    );

    expect(result.success, isTrue);
    expect(result.plan!.theme.id, 'technical-paper');
    expect(result.plan!.theme.version, 1);
    expect(result.theme!.descriptor.id, 'technical-paper');
    expect(result.theme!.palette.accent, '#0967D2');
    expect(client.requests, hasLength(2));
  });

  test('an explicit theme is the only model-eligible ID', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Explicit theme',
        'story': 'Keep the exact user-selected theme.',
        'theme': const {'id': 'bold-product'},
        'slides': [_planSlide(key: 'opening')],
      }),
      _jsonResponse(
        _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
      ),
    ]);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      const DeckGenerationRequest(
        userIntent: 'Create one product slide.',
        slideCount: 1,
        themeId: 'bold-product',
      ),
    );

    expect(result.success, isTrue);
    expect(result.plan!.theme.id, 'bold-product');
    final schema = client.requests.first.generationConfig!.responseSchema!;
    expect(schema.properties['theme']!.properties['id']!.enum$, [
      'bold-product',
    ]);
  });

  for (final themeId in defaultPresentationThemeIds) {
    test('resolves $themeId through plan, slide, and runtime output', () async {
      final client = _FakeGenerationModelClient([
        _jsonResponse({
          'topic': 'Representative theme',
          'story': 'Carry one exact theme through the full fake pipeline.',
          'theme': {'id': themeId},
          'slides': [_planSlide(key: 'opening')],
        }),
        _jsonResponse(
          _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
        ),
      ]);
      final result =
          await DeckGeneratorService(
            apiKey: 'test-key',
            modelClientFactory: (_) => client,
          ).generate(
            DeckGenerationRequest(
              userIntent: 'Create one representative themed slide.',
              slideCount: 1,
              themeId: themeId,
            ),
          );

      expect(result.success, isTrue, reason: result.error);
      expect(result.plan!.theme.id, themeId);
      expect(result.plan!.theme.version, 1);
      expect(result.theme!.descriptor.id, themeId);
      expect(result.slides, hasLength(1));
    });
  }

  test('rejects an unknown explicit theme before any provider call', () async {
    final client = _FakeGenerationModelClient(const []);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      const DeckGenerationRequest(
        userIntent: 'Create one product slide.',
        slideCount: 1,
        themeId: 'missing-theme',
      ),
    );

    expect(result.success, isFalse);
    expect(result.error, contains('Unknown presentation theme'));
    expect(client.requests, isEmpty);
  });

  test('rejects an unknown exact font before any provider call', () async {
    final client = _FakeGenerationModelClient(const []);
    final result =
        await DeckGeneratorService(
          apiKey: 'test-key',
          modelClientFactory: (_) => client,
        ).generate(
          const DeckGenerationRequest(
            userIntent: 'Create one branded slide.',
            slideCount: 1,
            headlineFont: 'Invented Display',
          ),
        );

    expect(result.success, isFalse);
    expect(result.error, contains('is not registered'));
    expect(client.requests, isEmpty);
  });

  test(
    'rejects an unreadable palette override before any provider call',
    () async {
      final client = _FakeGenerationModelClient(const []);
      final result =
          await DeckGeneratorService(
            apiKey: 'test-key',
            modelClientFactory: (_) => client,
          ).generate(
            const DeckGenerationRequest(
              userIntent: 'Create one branded slide.',
              slideCount: 1,
              colors: ['#FFFFFF', '#FFFFFF', '#FFFFFF'],
            ),
          );

      expect(result.success, isFalse);
      expect(result.error, contains('expected at least'));
      expect(client.requests, isEmpty);
    },
  );

  test(
    'drops invalid optional comments without another model request',
    () async {
      final client = _FakeGenerationModelClient([
        _jsonResponse({
          'topic': 'Comment fallback',
          'story': 'Visible evidence stays intact.',
          'theme': _testThemeSelection,
          'slides': [_planSlide(key: 'evidence')],
        }),
        _jsonResponse({
          ..._generatedSlide(
            key: 'evidence',
            title: 'Exact evidence',
            style: 'content',
          ),
          'comments': ['Nearly half of the work disappeared.'],
        }),
      ]);
      final service = DeckGeneratorService(
        apiKey: 'test-key',
        modelClientFactory: (_) => client,
      );

      final result = await service.generate(
        _request('Create one evidence slide.', slideCount: 1),
      );

      expect(result.success, isTrue);
      expect(result.slides.single.comments, isEmpty);
      expect(client.requests, hasLength(2));
    },
  );

  test('loads prompt assets before rendering the slide prompt', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Test topic',
        'story': 'Introduce and explain the test topic.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'intro')],
      }),
      _jsonResponse(
        _generatedSlide(key: 'intro', title: 'Test title', style: 'content'),
      ),
    ]);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );
    final traces = <GenerationTraceEvent>[];

    final result = await service.generate(
      _request('Create one test slide.', slideCount: 1),
      onTrace: traces.add,
    );

    expect(result.success, isTrue);
    expect(client.requests, hasLength(2));
    expect(client.requests.map((request) => request.model), [
      'models/gemini-3.5-flash',
      'models/gemini-3.1-flash-lite',
    ]);
    final outlinePrompt =
        client.requests.first.systemInstruction!.parts.single.text;
    expect(outlinePrompt, contains('narrativeRole'));
    expect(outlinePrompt, contains('composition'));
    expect(outlinePrompt, contains('## Eligible presentation themes'));
    expect(outlinePrompt, contains('Choose exactly one `theme.id`'));
    expect(outlinePrompt, isNot(contains('Registered typography catalog')));
    expect(outlinePrompt, contains('ordered narrative acts'));
    final slidePrompt =
        client.requests.last.systemInstruction!.parts.single.text;
    expect(slidePrompt, contains('## Relevant composition example'));
    expect(slidePrompt, contains('## Recent design ledger'));
    expect(slidePrompt, isNot(contains('example.com')));
    expect(slidePrompt, contains('## Available elements'));
    expect(slidePrompt, contains('None planned for this slide.'));
    expect(slidePrompt, isNot(contains('`image`: A supplied image asset')));
    final slideSchema = client
        .requests
        .last
        .generationConfig!
        .responseSchema!
        .properties['sections']!
        .items!
        .properties['blocks']!
        .items!;
    final widgetSchema = slideSchema.anyOf.last;
    expect(widgetSchema.properties, contains('args'));
    expect(
      widgetSchema.properties['args']!.properties.keys,
      containsAll(['src', 'text', 'url', 'id']),
    );
    expect(widgetSchema.properties, isNot(contains('text')));
    expect(
      client.requests.map(
        (request) => request.generationConfig!.thinkingConfig,
      ),
      everyElement(
        isA<google_ai.ThinkingConfig>().having(
          (config) => config.thinkingBudget,
          'thinking budget',
          0,
        ),
      ),
      reason: 'Deck generation must explicitly disable thinking.',
    );
    expect(client.isClosed, isTrue);
    final requests = traces
        .where((event) => event.kind == GenerationTraceKind.request)
        .toList();
    expect(requests, hasLength(2));
    expect(requests.map((event) => event.phase), [
      GenerationTracePhase.outline,
      GenerationTracePhase.slide,
    ]);
    expect(requests, everyElement(isNot(_containsSecret('test-key'))));
    expect(
      traces.where((event) => event.kind == GenerationTraceKind.response),
      hasLength(2),
    );
  });

  test(
    'composes narrative sections concurrently with one request each',
    () async {
      final client = _ConcurrentSectionModelClient();
      final progress = <GenerationProgress>[];
      final service = DeckGeneratorService(
        apiKey: 'test-key',
        sectionBatchThreshold: 4,
        modelClientFactory: (_) => client,
      );

      final generation = service.generate(
        _request('Create a four-slide story.', slideCount: 4),
        onProgress: progress.add,
      );

      await client.bothSectionsStarted.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TestFailure(
          'The second narrative section did not start while the first was pending.',
        ),
      );
      client.completeSections();
      final result = await generation;

      expect(result.success, isTrue, reason: result.error);
      expect(result.slides.map((slide) => slide.key), [
        'opening',
        'problem',
        'solution',
        'closing',
      ]);
      expect(client.requests, hasLength(3));
      expect(client.requests.map((request) => request.model), [
        'models/gemini-3.5-flash',
        'models/gemini-3.1-flash-lite',
        'models/gemini-3.1-flash-lite',
      ]);
      expect(
        progress
            .where((event) => event.sectionIndex != null)
            .map((event) => event.sectionIndex),
        containsAll([1, 2]),
      );
    },
  );

  test('keeps valid slides when one section response omits a slide', () async {
    final client = _ConcurrentSectionModelClient(omitProblem: true);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      sectionBatchThreshold: 4,
      modelClientFactory: (_) => client,
    );

    final generation = service.generate(
      _request('Create a four-slide story.', slideCount: 4),
    );
    await client.bothSectionsStarted.future;
    client.completeSections();
    final result = await generation;

    expect(result.success, isFalse);
    expect(result.isPartial, isTrue);
    expect(result.slides.map((slide) => slide.key), [
      'opening',
      'solution',
      'closing',
    ]);
    expect(result.slideFailures, hasLength(1));
    expect(result.slideFailures.single.slideKey, 'problem');
    expect(result.slideFailures.single.retryable, isTrue);
    expect(result.slideFailures.single.message, contains('omitted slide'));
    expect(client.requests, hasLength(3));
  });

  test('stops after an outline with duplicate slide keys', () async {
    final client = _FakeGenerationModelClient([
      for (final story in const [
        'A plan that should not reach composition.',
        'The repair still has duplicate keys.',
        'The final repair still has duplicate keys.',
        'The bounded repairs still have duplicate keys.',
        'The final bounded repair still has duplicate keys.',
        'The extra semantic sweep still has duplicate keys.',
      ])
        _jsonResponse(_duplicateKeyPlan(story)),
    ]);
    final traces = <GenerationTraceEvent>[];
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      maxOutlineValidationAttempts: 6,
      maxRepairRequests: 5,
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      const DeckGenerationRequest(
        userIntent: 'Create an invalid plan.',
        slideCount: 2,
        themeId: 'technical-paper',
      ),
      onTrace: traces.add,
    );

    expect(result.success, isFalse);
    expect(client.requests, hasLength(6));
    expect(
      traces.where(
        (event) =>
            event.kind == GenerationTraceKind.validation &&
            event.phase == GenerationTracePhase.outline,
      ),
      contains(
        isA<GenerationTraceEvent>().having(
          (event) => event.validationErrors,
          'validation errors',
          contains('Duplicate slide key "duplicate".'),
        ),
      ),
    );
  });

  test(
    'composes slides sequentially and repairs only the invalid slide',
    () async {
      final client = _FakeGenerationModelClient([
        _jsonResponse({
          'topic': 'Flow',
          'story': 'A connected three-slide story.',
          'theme': _testThemeSelection,
          'slides': [
            _planSlide(key: 'opening', composition: 'title'),
            _planSlide(key: 'evidence'),
            _planSlide(key: 'closing', composition: 'titleLeft'),
          ],
        }),
        _jsonResponse(
          _generatedSlide(key: 'opening', title: 'Start here', style: 'hero'),
        ),
        _jsonResponse({'key': 'evidence', 'sections': <Object?>[]}),
        _jsonResponse(
          _generatedSlide(
            key: 'evidence',
            title: 'The proof',
            style: 'content',
          ),
        ),
        _jsonResponse(
          _generatedSlide(
            key: 'closing',
            title: 'Take action',
            style: 'closing',
          ),
        ),
      ]);
      final traces = <GenerationTraceEvent>[];
      final progress = <GenerationProgress>[];
      final service = DeckGeneratorService(
        apiKey: 'test-key',
        modelClientFactory: (_) => client,
      );

      final result = await service.generate(
        _request('Create a connected deck.', slideCount: 3),
        onTrace: traces.add,
        onProgress: progress.add,
      );

      expect(result.success, isTrue);
      expect(result.slides.map((slide) => slide.key), [
        'opening',
        'evidence',
        'closing',
      ]);
      expect(client.requests, hasLength(5));
      final slideRequests = traces
          .where(
            (event) =>
                event.kind == GenerationTraceKind.request &&
                event.phase == GenerationTracePhase.slide,
          )
          .toList();
      expect(slideRequests.map((event) => event.slideIndex), [1, 2, 2, 3]);
      expect(slideRequests.map((event) => event.attempt), [1, 1, 2, 1]);

      final secondSlidePrompt =
          client.requests[2].systemInstruction!.parts.single.text!;
      expect(secondSlidePrompt, contains('Start here'));
      expect(secondSlidePrompt, contains('closing'));
      final repairPrompt =
          client.requests[3].systemInstruction!.parts.single.text!;
      expect(repairPrompt, contains('## Blocking issues'));
      expect(repairPrompt, contains('at least one usable section'));
      expect(repairPrompt, contains('## Invalid draft'));
      expect(repairPrompt, contains('"key": "evidence"'));
      expect(
        progress.map((event) => event.label),
        containsAllInOrder([
          'Composing slide 1 of 3…',
          'Composing slide 2 of 3…',
          'Repairing slide 2 of 3…',
          'Composing slide 3 of 3…',
        ]),
      );
    },
  );

  test('keeps accepted slides and continues after one slide fails', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Partial flow',
        'story': 'Preserve useful work when one slide cannot be repaired.',
        'theme': _testThemeSelection,
        'slides': [
          _planSlide(key: 'opening', composition: 'title'),
          _planSlide(key: 'evidence'),
          _planSlide(key: 'closing', composition: 'titleLeft'),
        ],
      }),
      _jsonResponse(
        _generatedSlide(key: 'opening', title: 'Start here', style: 'hero'),
      ),
      _jsonResponse({'key': 'evidence', 'sections': <Object?>[]}),
      _jsonResponse({'key': 'evidence', 'sections': <Object?>[]}),
      _jsonResponse(
        _generatedSlide(key: 'closing', title: 'Take action', style: 'closing'),
      ),
    ]);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      maxSlideValidationAttempts: 2,
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create a resilient deck.', slideCount: 3),
    );

    expect(result.success, isFalse);
    expect(result.isPartial, isTrue);
    expect(result.slides.map((slide) => slide.key), ['opening', 'closing']);
    expect(result.slideFailures, hasLength(1));
    expect(result.slideFailures.single.slideIndex, 2);
    expect(result.slideFailures.single.slideKey, 'evidence');
    expect(result.slideFailures.single.retryable, isTrue);
    expect(
      result.slideFailures.single.issues,
      everyElement(
        isA<GenerationValidationIssue>().having(
          (issue) => issue.isBlocking,
          'isBlocking',
          isTrue,
        ),
      ),
    );
    expect(result.plan?.slides, hasLength(3));
    expect(result.theme, isNotNull);
    expect(result.error, allOf(contains('evidence'), contains('2 of 3')));
    expect(client.requests, hasLength(5));
    expect(
      client.requests.last.systemInstruction!.parts.single.text,
      contains('Start here'),
      reason: 'Later slides should use the most recent accepted slide context.',
    );
  });

  test('uses one targeted semantic repair per slide by default', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Bounded repair',
        'story': 'Repair one display heading without restarting the deck.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'evidence')],
      }),
      _jsonResponse({'key': 'evidence', 'sections': <Object?>[]}),
      _jsonResponse(
        _generatedSlide(
          key: 'evidence',
          title: 'Evidence',
          style: 'content',
          content: '## Evidence Compounds\n\nA concrete supporting point.',
        ),
      ),
    ]);
    final traces = <GenerationTraceEvent>[];
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create one evidence slide.', slideCount: 1),
      onTrace: traces.add,
    );

    expect(result.success, isTrue);
    expect(client.requests, hasLength(3));
    expect(
      traces
          .where(
            (event) =>
                event.kind == GenerationTraceKind.request &&
                event.phase == GenerationTracePhase.slide,
          )
          .map((event) => event.attempt),
      [1, 2],
    );
    final finalRepairPrompt =
        client.requests[2].systemInstruction!.parts.single.text!;
    expect(finalRepairPrompt, contains('at least one usable section'));
    expect(finalRepairPrompt, contains('## Blocking issues'));
  });

  test('caps slide repairs across the deck and keeps composing', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Repair budget',
        'story': 'Spend a bounded number of repairs across the whole deck.',
        'theme': _testThemeSelection,
        'slides': [
          _planSlide(key: 'one'),
          _planSlide(key: 'two'),
          _planSlide(key: 'three'),
          _planSlide(key: 'four'),
        ],
      }),
      _jsonResponse({'key': 'one', 'sections': <Object?>[]}),
      _jsonResponse(
        _generatedSlide(key: 'one', title: 'Alpha', style: 'content'),
      ),
      _jsonResponse({'key': 'two', 'sections': <Object?>[]}),
      _jsonResponse(
        _generatedSlide(key: 'two', title: 'Beta', style: 'content'),
      ),
      _jsonResponse({'key': 'three', 'sections': <Object?>[]}),
      _jsonResponse(
        _generatedSlide(key: 'four', title: 'Delta', style: 'content'),
      ),
    ]);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      maxRepairRequests: 2,
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create a bounded four-slide deck.', slideCount: 4),
    );

    expect(result.isPartial, isTrue);
    expect(result.slides.map((slide) => slide.key), ['one', 'two', 'four']);
    expect(result.slideFailures.single.slideKey, 'three');
    expect(client.requests, hasLength(7));
  });

  test('continues after an isolated slide transport failure', () async {
    final client = _PartiallyFailingSlideModelClient();
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      retryPolicy: RetryPolicy(maxAttempts: 2, baseDelay: Duration.zero),
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create a resilient three-slide deck.', slideCount: 3),
    );

    expect(result.isPartial, isTrue);
    expect(result.slides.map((slide) => slide.key), ['opening', 'closing']);
    expect(result.slideFailures.single.slideKey, 'evidence');
    expect(
      result.slideFailures.single.issues.single.code,
      GenerationValidationCode.invalidResponse,
    );
    expect(client.requests, hasLength(5));
    expect(
      client.requests.last.systemInstruction!.parts.single.text,
      contains('Opening'),
    );
  });

  test('stops between slides when generation is cancelled', () async {
    var cancelled = false;
    final client = _FakeGenerationModelClient(
      [
        _jsonResponse({
          'topic': 'Cancel',
          'story': 'Stop after one slide.',
          'theme': _testThemeSelection,
          'slides': [_planSlide(key: 'one'), _planSlide(key: 'two')],
        }),
        _jsonResponse(
          _generatedSlide(key: 'one', title: 'Opening', style: 'content'),
        ),
      ],
      onRequest: (requestCount) {
        if (requestCount == 2) cancelled = true;
      },
    );
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create two slides.', slideCount: 2),
      isCancelled: () => cancelled,
    );

    expect(result.success, isFalse);
    expect(result.error, 'Generation cancelled.');
    expect(client.requests, hasLength(2));
  });

  test('does not start an outline repair after cancellation', () async {
    var cancelled = false;
    final client = _FakeGenerationModelClient(
      [
        _jsonResponse({
          'topic': 'Cancel outline repair',
          'story': 'The first outline has the wrong count.',
          'theme': _testThemeSelection,
          'slides': [_planSlide(key: 'only-one')],
        }),
        _jsonResponse({
          'topic': 'Cancel outline repair',
          'story': 'This repair must never be requested.',
          'theme': _testThemeSelection,
          'slides': [_planSlide(key: 'one'), _planSlide(key: 'two')],
        }),
      ],
      onRequest: (requestCount) {
        if (requestCount == 1) cancelled = true;
      },
    );
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create two slides.', slideCount: 2),
      isCancelled: () => cancelled,
    );

    expect(result.success, isFalse);
    expect(result.error, 'Generation cancelled.');
    expect(client.requests, hasLength(1));
  });

  test('does not start a slide repair after cancellation', () async {
    var cancelled = false;
    final client = _FakeGenerationModelClient(
      [
        _jsonResponse({
          'topic': 'Cancel slide repair',
          'story': 'Stop while validating the first slide draft.',
          'theme': _testThemeSelection,
          'slides': [_planSlide(key: 'opening')],
        }),
        _jsonResponse({'key': 'opening', 'sections': <Object?>[]}),
        _jsonResponse(
          _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
        ),
      ],
      onRequest: (requestCount) {
        if (requestCount == 2) cancelled = true;
      },
    );
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create one slide.', slideCount: 1),
      isCancelled: () => cancelled,
    );

    expect(result.success, isFalse);
    expect(result.error, 'Generation cancelled.');
    expect(client.requests, hasLength(2));
  });

  test('traces transport retries separately from semantic repairs', () async {
    final client = _RetryingSlideModelClient();
    final traces = <GenerationTraceEvent>[];
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      retryPolicy: RetryPolicy(maxAttempts: 2, baseDelay: Duration.zero),
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create one slide.', slideCount: 1),
      onTrace: traces.add,
    );

    expect(result.success, isTrue);
    final slideRequests = traces
        .where(
          (event) =>
              event.kind == GenerationTraceKind.request &&
              event.phase == GenerationTracePhase.slide,
        )
        .map((event) => event.toJson())
        .toList();
    expect(slideRequests.map((event) => event['attempt']), [1, 1]);
    expect(slideRequests.map((event) => event['semanticAttempt']), [1, 1]);
    expect(slideRequests.map((event) => event['transportAttempt']), [1, 2]);
  });

  test('caps pathological nested outline requests globally', () async {
    final client = _RepeatingInvalidOutlineClient();
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      maxOutlineValidationAttempts: 100,
      maxRepairRequests: 1000,
      retryPolicy: RetryPolicy(maxAttempts: 1),
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create two slides.', slideCount: 2),
    );

    expect(result.success, isFalse);
    expect(result.error, contains('request budget'));
    expect(client.requestCount, lessThan(100));
  });

  test('hydrates an exact planned source into generated widget args', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Elements',
        'story': 'Show a supplied visual.',
        'theme': _testThemeSelection,
        'slides': [
          _planSlide(
            key: 'visual',
            composition: 'imageFullBleed',
            elements: const [
              {
                'type': 'image',
                'purpose': 'Show the supplied system image.',
                'source': 'assets/system-map.png',
              },
            ],
          ),
        ],
      }),
      _jsonResponse({
        'key': 'visual',
        'options': {'style': 'visual'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {
                'type': 'widget',
                'name': 'image',
                'args': {
                  'fit': 'contain',
                  'text': 'Copied QR field',
                  'url': 'https://wrong.example.com',
                },
              },
            ],
          },
        ],
      }),
    ]);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      const DeckGenerationRequest(
        userIntent: 'Use the supplied image.',
        slideCount: 1,
        groundedElements: [
          GroundedGenerationElement(
            type: 'image',
            source: 'assets/system-map.png',
            purpose: 'Show the supplied system image.',
          ),
        ],
      ),
    );

    expect(result.success, isTrue);
    final widget = result.slides.single.sections.single.blocks.single;
    expect(widget, isA<WidgetBlock>());
    expect((widget as WidgetBlock).args['src'], 'assets/system-map.png');
    expect(widget.args['fit'], 'contain');
    expect(widget.args, isNot(contains('text')));
    expect(widget.args, isNot(contains('url')));
  });

  test('retries the current slide once after its request timeout', () async {
    final client = _HangingSlideModelClient();
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      requestTimeout: const Duration(milliseconds: 10),
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create one test slide.', slideCount: 1),
    );

    expect(result.success, isFalse);
    expect(result.isPartial, isTrue);
    expect(result.error, contains('Connection issue'));
    expect(result.slideFailures.single.slideKey, 'intro');
    expect(client.requestCount, 3);
  });
}

const _testThemeSelection = <String, Object?>{'id': 'technical-paper'};

DeckGenerationRequest _request(String userIntent, {required int slideCount}) =>
    DeckGenerationRequest(userIntent: userIntent, slideCount: slideCount);

Map<String, Object?> _planSlide({
  required String key,
  String sectionKey = 'main',
  String composition = 'content',
  List<Map<String, Object?>> elements = const [],
}) => {
  'key': key,
  'title': 'Test title',
  'purpose': 'Introduce the test topic',
  'sectionKey': sectionKey,
  'assertion': 'The test topic matters now.',
  'contentUnits': ['One concrete supporting point'],
  'narrativeRole': 'insight',
  'contentBrief': 'Explain the core idea.',
  'continuity': 'Connect the surrounding ideas.',
  'composition': composition,
  'treatment': switch (composition) {
    'title' => 'hero',
    'titleLeft' => 'closing',
    'imageFullBleed' => 'visual',
    _ => 'content',
  },
  'density': 'balanced',
  'elements': elements,
};

Map<String, Object?> _duplicateKeyPlan(String story) => {
  'topic': 'Invalid plan',
  'story': story,
  'theme': _testThemeSelection,
  'sections': [
    {
      'key': 'main',
      'title': 'Main story',
      'purpose': 'Advance the test narrative.',
      'transition': 'Carry the story to its conclusion.',
      'slideKeys': ['duplicate', 'duplicate'],
    },
  ],
  'slides': [_planSlide(key: 'duplicate'), _planSlide(key: 'duplicate')],
};

Map<String, Object?> _generatedSlide({
  required String key,
  required String title,
  required String style,
  String? content,
}) {
  final heading = style == 'content' || style == 'visual' ? '##' : '#';
  return {
    'key': key,
    'options': {'title': title, 'style': style},
    'sections': [
      {
        'type': 'section',
        'blocks': [
          {
            'type': 'block',
            'content':
                content ?? '$heading $title\n\nA concrete supporting point.',
          },
        ],
      },
    ],
  };
}

Matcher _containsSecret(String secret) {
  return isA<GenerationTraceEvent>().having(
    (event) => event.toJson().toString(),
    'serialized event',
    contains(secret),
  );
}

google_ai.GenerateContentResponse _jsonResponse(Map<String, Object?> value) {
  final normalized = Map<String, Object?>.from(value);
  final rawSlides = normalized['slides'];
  if (normalized.containsKey('story') &&
      rawSlides is List &&
      !normalized.containsKey('sections')) {
    normalized['sections'] = [
      {
        'key': 'main',
        'title': 'Main story',
        'purpose': 'Advance the test narrative.',
        'transition': 'Carry the story to its conclusion.',
        'slideKeys': [
          for (final slide in rawSlides)
            if (slide is Map) slide['key'],
        ],
      },
    ];
  }
  return google_ai.GenerateContentResponse(
    candidates: [
      google_ai.Candidate(
        content: google_ai.Content(
          role: 'model',
          parts: [google_ai.Part(text: jsonEncode(normalized))],
        ),
      ),
    ],
  );
}

final class _FakeGenerationModelClient implements GenerationModelClient {
  _FakeGenerationModelClient(
    Iterable<google_ai.GenerateContentResponse> responses, {
    this.onRequest,
  }) : _responses = Queue.of(responses);

  final Queue<google_ai.GenerateContentResponse> _responses;
  final requests = <google_ai.GenerateContentRequest>[];
  bool isClosed = false;
  final void Function(int requestCount)? onRequest;

  @override
  void close() => isClosed = true;

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) async {
    requests.add(request);
    onRequest?.call(requests.length);
    return _responses.removeFirst();
  }
}

final class _ConcurrentSectionModelClient implements GenerationModelClient {
  _ConcurrentSectionModelClient({this.omitProblem = false});

  final bool omitProblem;
  final requests = <google_ai.GenerateContentRequest>[];
  final bothSectionsStarted = Completer<void>();
  final _sectionResponses =
      <String, Completer<google_ai.GenerateContentResponse>>{
        'section-a': Completer<google_ai.GenerateContentResponse>(),
        'section-b': Completer<google_ai.GenerateContentResponse>(),
      };
  final _startedSections = <String>{};

  @override
  void close() {}

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) {
    requests.add(request);
    if (requests.length == 1) {
      return Future.value(
        _jsonResponse({
          'topic': 'Concurrent story',
          'story': 'Move from problem to solution.',
          'theme': _testThemeSelection,
          'sections': [
            {
              'key': 'section-a',
              'title': 'Problem',
              'purpose': 'Frame the need.',
              'transition': 'Hand the need to the solution.',
              'slideKeys': ['opening', 'problem'],
            },
            {
              'key': 'section-b',
              'title': 'Solution',
              'purpose': 'Resolve the need.',
              'transition': 'Close with a clear takeaway.',
              'slideKeys': ['solution', 'closing'],
            },
          ],
          'slides': [
            _planSlide(key: 'opening', sectionKey: 'section-a'),
            _planSlide(key: 'problem', sectionKey: 'section-a'),
            _planSlide(key: 'solution', sectionKey: 'section-b'),
            _planSlide(key: 'closing', sectionKey: 'section-b'),
          ],
        }),
      );
    }

    final sectionKey = requests.length == 2 ? 'section-a' : 'section-b';
    _startedSections.add(sectionKey);
    if (_startedSections.length == 2 && !bothSectionsStarted.isCompleted) {
      bothSectionsStarted.complete();
    }
    return _sectionResponses[sectionKey]!.future;
  }

  void completeSections() {
    _sectionResponses['section-a']!.complete(
      _jsonResponse({
        'slides': [
          _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
          if (!omitProblem)
            _generatedSlide(key: 'problem', title: 'Problem', style: 'content'),
        ],
      }),
    );
    _sectionResponses['section-b']!.complete(
      _jsonResponse({
        'slides': [
          _generatedSlide(key: 'solution', title: 'Solution', style: 'content'),
          _generatedSlide(key: 'closing', title: 'Closing', style: 'content'),
        ],
      }),
    );
  }
}

final class _HangingSlideModelClient implements GenerationModelClient {
  var requestCount = 0;

  @override
  void close() {}

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) {
    requestCount++;
    if (requestCount == 1) {
      return Future.value(
        _jsonResponse({
          'topic': 'Timeout',
          'story': 'Verify the request deadline.',
          'theme': _testThemeSelection,
          'slides': [_planSlide(key: 'intro')],
        }),
      );
    }
    return Completer<google_ai.GenerateContentResponse>().future;
  }
}

final class _RetryingSlideModelClient implements GenerationModelClient {
  var requestCount = 0;

  @override
  void close() {}

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) async {
    requestCount++;
    if (requestCount == 1) {
      return _jsonResponse({
        'topic': 'Retry trace',
        'story': 'Distinguish transport retries from semantic repairs.',
        'theme': _testThemeSelection,
        'slides': [_planSlide(key: 'opening')],
      });
    }
    if (requestCount == 2) {
      throw TimeoutException('Transient slide timeout.');
    }
    return _jsonResponse(
      _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
    );
  }
}

final class _PartiallyFailingSlideModelClient implements GenerationModelClient {
  final requests = <google_ai.GenerateContentRequest>[];

  @override
  void close() {}

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) async {
    requests.add(request);
    return switch (requests.length) {
      1 => _jsonResponse({
        'topic': 'Transport recovery',
        'story': 'Continue after one isolated request failure.',
        'theme': _testThemeSelection,
        'slides': [
          _planSlide(key: 'opening'),
          _planSlide(key: 'evidence'),
          _planSlide(key: 'closing'),
        ],
      }),
      2 => _jsonResponse(
        _generatedSlide(key: 'opening', title: 'Opening', style: 'content'),
      ),
      3 || 4 => throw TimeoutException('Transient evidence timeout.'),
      _ => _jsonResponse(
        _generatedSlide(key: 'closing', title: 'Closing', style: 'content'),
      ),
    };
  }
}

final class _RepeatingInvalidOutlineClient implements GenerationModelClient {
  var requestCount = 0;

  @override
  void close() {}

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) async {
    requestCount++;
    return _jsonResponse({
      'topic': 'Request budget',
      'story': 'Keep returning an outline with the wrong slide count.',
      'theme': _testThemeSelection,
      'slides': [_planSlide(key: 'only-one')],
    });
  }
}
