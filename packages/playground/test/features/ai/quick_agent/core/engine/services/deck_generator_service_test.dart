import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_model_client.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_progress.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_trace.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rejects an outline that violates the typed request count', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The outline must have the requested number of slides.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'only-one')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The repaired outline is still incomplete.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'still-only-one')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The final outline repair is still incomplete.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'still-incomplete')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The bounded outline repairs remain incomplete.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'still-invalid')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The final bounded repair remains incomplete.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'still-invalid-final')],
      }),
      _jsonResponse({
        'topic': 'Count contract',
        'story': 'The extra semantic sweep remains incomplete.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'still-invalid-extra')],
      }),
    ]);
    final service = DeckGeneratorService(
      apiKey: 'test-key',
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
        'style': _testStyle,
        'slides': [_planSlide(key: 'only-one')],
      }),
      _jsonResponse({
        'topic': 'Repair contract',
        'story': 'The repaired outline now has the exact requested count.',
        'style': _testStyle,
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
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Local plan repair',
        'story': 'Repair only the invalid slide content.',
        'style': _testStyle,
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

  test('normalizes derived accent contrast without a model repair', () async {
    final lowContrastStyle = <String, Object?>{
      ..._testStyle,
      'colors': {
        ..._testStyle['colors']! as Map<String, Object?>,
        'accent': '#FF8A00',
        'accentContrast': '#FFFFFF',
      },
    };
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Accessible palette',
        'story': 'Keep the generated accent and derive readable foreground.',
        'style': lowContrastStyle,
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
      _request('Create one accessible slide.', slideCount: 1),
    );

    expect(result.success, isTrue);
    expect(result.plan, isNotNull);
    expect(result.plan!.style.colors.accent, '#FF8A00');
    expect(result.plan!.style.colors.accentContrast, '#000000');
    expect(client.requests, hasLength(2));
  });

  test(
    'drops invalid optional comments without another model request',
    () async {
      final client = _FakeGenerationModelClient([
        _jsonResponse({
          'topic': 'Comment fallback',
          'story': 'Visible evidence stays intact.',
          'style': _testStyle,
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
        'style': _testStyle,
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
    expect(
      client.requests.map((request) => request.model),
      everyElement('models/gemini-3-flash-preview'),
    );
    final outlinePrompt =
        client.requests.first.systemInstruction!.parts.single.text;
    expect(outlinePrompt, contains('narrativeRole'));
    expect(outlinePrompt, contains('composition'));
    expect(outlinePrompt, contains('one shared design system'));
    expect(outlinePrompt, contains('Registered typography catalog'));
    expect(outlinePrompt, contains('ordered narrative acts'));
    final slidePrompt =
        client.requests.last.systemInstruction!.parts.single.text;
    expect(slidePrompt, contains('## Relevant composition example'));
    expect(slidePrompt, contains('## Recent design ledger'));
    expect(slidePrompt, isNot(contains('example.com')));
    expect(slidePrompt, contains('## Available elements'));
    expect(slidePrompt, contains('`image`: A supplied image asset'));
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
      everyElement(isNull),
      reason: 'Deck generation must keep explicit thinking disabled.',
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

  test('stops after an outline with duplicate slide keys', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Invalid plan',
        'story': 'A plan that should not reach composition.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'duplicate'), _planSlide(key: 'duplicate')],
      }),
      _jsonResponse({
        'topic': 'Invalid plan',
        'story': 'The repair still has duplicate keys.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'duplicate'), _planSlide(key: 'duplicate')],
      }),
      _jsonResponse({
        'topic': 'Invalid plan',
        'story': 'The final repair still has duplicate keys.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'duplicate'), _planSlide(key: 'duplicate')],
      }),
      _jsonResponse({
        'topic': 'Invalid plan',
        'story': 'The bounded repairs still have duplicate keys.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'duplicate'), _planSlide(key: 'duplicate')],
      }),
      _jsonResponse({
        'topic': 'Invalid plan',
        'story': 'The final bounded repair still has duplicate keys.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'duplicate'), _planSlide(key: 'duplicate')],
      }),
      _jsonResponse({
        'topic': 'Invalid plan',
        'story': 'The extra semantic sweep still has duplicate keys.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'duplicate'), _planSlide(key: 'duplicate')],
      }),
    ]);
    final traces = <GenerationTraceEvent>[];
    final service = DeckGeneratorService(
      apiKey: 'test-key',
      modelClientFactory: (_) => client,
    );

    final result = await service.generate(
      _request('Create an invalid plan.', slideCount: 2),
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
          'style': _testStyle,
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
      expect(repairPrompt, contains('validation constraints'));
      expect(repairPrompt, contains('at least one usable section'));
      expect(repairPrompt, contains('Invalid slide draft to repair'));
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

  test('allows one final targeted semantic repair before aborting', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Bounded repair',
        'story': 'Repair one display heading without restarting the deck.',
        'style': _testStyle,
        'slides': [_planSlide(key: 'evidence')],
      }),
      _jsonResponse(
        _generatedSlide(
          key: 'evidence',
          title: 'Evidence',
          style: 'content',
          content:
              '## This heading still contains far too many words to fit\n\n'
              'A concrete supporting point.',
        ),
      ),
      _jsonResponse({'key': 'evidence', 'sections': <Object?>[]}),
      _jsonResponse(
        _generatedSlide(
          key: 'evidence',
          title: 'Evidence',
          style: 'content',
          content:
              '## This third heading is still much too long to display\n\n'
              'A concrete supporting point.',
        ),
      ),
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
    expect(client.requests, hasLength(5));
    expect(
      traces
          .where(
            (event) =>
                event.kind == GenerationTraceKind.request &&
                event.phase == GenerationTracePhase.slide,
          )
          .map((event) => event.attempt),
      [1, 2, 3, 4],
    );
    final finalRepairPrompt =
        client.requests[4].systemInstruction!.parts.single.text!;
    expect(finalRepairPrompt, contains('use at most 8'));
    expect(finalRepairPrompt, contains('at least one usable section'));
    expect(finalRepairPrompt, contains('This list is cumulative'));
  });

  test('stops between slides when generation is cancelled', () async {
    var cancelled = false;
    final client = _FakeGenerationModelClient(
      [
        _jsonResponse({
          'topic': 'Cancel',
          'story': 'Stop after one slide.',
          'style': _testStyle,
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

  test('hydrates an exact planned source into generated widget args', () async {
    final client = _FakeGenerationModelClient([
      _jsonResponse({
        'topic': 'Elements',
        'story': 'Show a supplied visual.',
        'style': _testStyle,
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
    expect(result.error, contains('Connection issue'));
    expect(client.requestCount, 3);
  });
}

const _testStyle = <String, Object?>{
  'name': 'test',
  'direction': 'technical',
  'density': 'balanced',
  'typeScale': 'balanced',
  'colors': {
    'background': '#101010',
    'surface': '#202020',
    'surfaceAlt': '#303030',
    'heading': '#FFFFFF',
    'body': '#E5E5E5',
    'accent': '#6941C6',
    'accentContrast': '#FFFFFF',
  },
  'fonts': {'headline': 'Montserrat', 'body': 'Inter'},
};

DeckGenerationRequest _request(String userIntent, {required int slideCount}) =>
    DeckGenerationRequest(userIntent: userIntent, slideCount: slideCount);

Map<String, Object?> _planSlide({
  required String key,
  String composition = 'content',
  List<Map<String, Object?>> elements = const [],
}) => {
  'key': key,
  'title': 'Test title',
  'purpose': 'Introduce the test topic',
  'sectionKey': 'main',
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
          'style': _testStyle,
          'slides': [_planSlide(key: 'intro')],
        }),
      );
    }
    return Completer<google_ai.GenerateContentResponse>().future;
  }
}
