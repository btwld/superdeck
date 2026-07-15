import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_plan_validator.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/google_schema_adapter.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_validation_issue.dart';

void main() {
  test('accepts a theme-referenced plan with narrative and element intent', () {
    final result = deckPlanSchema.safeParse({
      'topic': 'Reliable systems',
      'story': 'Move from operational uncertainty to measurable confidence.',
      'theme': _validTheme,
      'sections': [
        {
          'key': 'main',
          'title': 'The system',
          'purpose': 'Explain the operating model.',
          'transition': 'Move from comparison to the complete system.',
          'slideKeys': ['compare-slos', 'system-map'],
        },
      ],
      'slides': [
        {
          'key': 'compare-slos',
          'title': 'SLOs create focus',
          'purpose': 'Compare reactive operations with SLO-led operations.',
          'sectionKey': 'main',
          'assertion': 'SLOs turn noise into shared priorities.',
          'contentUnits': ['Reactive signals', 'SLO-led decisions'],
          'narrativeRole': 'comparison',
          'contentBrief':
              'Use three concise comparison rows with real metrics.',
          'continuity': 'Turns the opening problem into a decision framework.',
          'composition': 'table',
          'treatment': 'data',
          'density': 'balanced',
          'elements': <Object?>[],
        },
        {
          'key': 'system-map',
          'title': 'See the whole system',
          'purpose': 'Show how service signals connect across the platform.',
          'sectionKey': 'main',
          'assertion': 'One operating view connects every service signal.',
          'contentUnits': ['Signal flow', 'Shared ownership'],
          'narrativeRole': 'solution',
          'contentBrief': 'Pair a short explanation with a supplied diagram.',
          'continuity':
              'Builds on the comparison with a concrete operating view.',
          'composition': 'imageRight',
          'treatment': 'visual',
          'density': 'spacious',
          'elements': [
            {
              'type': 'image',
              'purpose': 'Architecture diagram supplied by the user',
              'source': 'assets/system-map.png',
            },
          ],
        },
      ],
    });

    expect(result.isOk, isTrue);
  });

  test(
    'adapts the complete deck-plan contract for Google structured output',
    () {
      final result = GoogleSchemaAdapter().adapt(
        deckPlanSchema.toJsonSchemaBuilder(),
      );

      expect(
        result.errors,
        everyElement(
          predicate<Object>(
            (error) => error.toString().contains(
              'Unsupported keyword "additionalProperties"',
            ),
          ),
        ),
      );
      final schema = result.schema!;
      expect(
        schema.properties.keys,
        containsAll(['topic', 'story', 'theme', 'sections', 'slides']),
      );
      final slide = schema.properties['slides']!.items!;
      expect(
        slide.properties.keys,
        containsAll([
          'key',
          'title',
          'purpose',
          'sectionKey',
          'assertion',
          'contentUnits',
          'narrativeRole',
          'contentBrief',
          'continuity',
          'composition',
          'treatment',
          'density',
          'elements',
        ]),
      );
    },
  );

  test('rejects unknown narrative roles and composition intents', () {
    final result = deckPlanSchema.safeParse({
      'topic': 'Invalid plan',
      'story': 'This should fail.',
      'theme': _validTheme,
      'sections': [
        {
          'key': 'main',
          'title': 'Invalid',
          'purpose': 'Exercise validation.',
          'transition': 'None.',
          'slideKeys': ['invalid'],
        },
      ],
      'slides': [
        {
          'key': 'invalid',
          'title': 'Invalid',
          'purpose': 'Exercise enum validation.',
          'sectionKey': 'main',
          'assertion': 'This value is intentionally invalid.',
          'contentUnits': ['Invalid value'],
          'narrativeRole': 'surprise-me',
          'contentBrief': 'Invalid role.',
          'continuity': 'None.',
          'composition': 'floating-cards',
          'treatment': 'content',
          'density': 'balanced',
          'elements': <Object?>[],
        },
      ],
    });

    expect(result.isOk, isFalse);
  });

  test('rejects duplicate or empty slide keys after schema parsing', () {
    final plan = DeckPlanType.parse({
      'topic': 'Duplicate keys',
      'story': 'A short story.',
      'theme': _validTheme,
      'sections': [
        {
          'key': 'main',
          'title': 'Main',
          'purpose': 'Contain the test slides.',
          'transition': 'None.',
          'slideKeys': ['same', 'same', '   '],
        },
      ],
      'slides': [
        _validSlide(key: 'same'),
        _validSlide(key: 'same'),
        _validSlide(key: '   '),
      ],
    });

    expect(
      validateDeckPlan(plan),
      containsAll([
        contains('Duplicate slide key "same"'),
        contains('Slide 3 has an empty key'),
      ]),
    );
  });

  test('rejects a plan that does not match the requested slide count', () {
    final plan = DeckPlanType.parse({
      'topic': 'Count contract',
      'story': 'Every requested slide must be planned.',
      'theme': _validTheme,
      'sections': [
        {
          'key': 'main',
          'title': 'Main',
          'purpose': 'Contain the test slides.',
          'transition': 'None.',
          'slideKeys': ['one', 'two'],
        },
      ],
      'slides': [_validSlide(key: 'one'), _validSlide(key: 'two')],
    });

    expect(
      validateDeckPlan(plan, expectedSlideCount: 3),
      contains('Deck plan has 2 slides; expected exactly 3.'),
    );
  });

  test('validates a hierarchical ten-slide blueprint and design rhythm', () {
    final plan = DeckPlanType.parse(_hierarchicalPlan());

    expect(plan.sections.map((section) => section.key), [
      'tension',
      'system',
      'action',
    ]);
    expect(
      validateDeckPlan(
        plan,
        expectedSlideCount: 10,
        typographyCatalog: PresentationTypographyCatalog.withDefaults(),
      ),
      isEmpty,
    );
  });

  test('validates deterministic fifteen- and twenty-slide blueprints', () {
    for (final count in [15, 20]) {
      final plan = DeckPlanType.parse(_scaledHierarchicalPlan(count));

      expect(
        validateDeckPlan(plan, expectedSlideCount: count),
        isEmpty,
        reason: '$count-slide blueprint should satisfy the large-deck contract',
      );
    }
  });

  test('allows a treatment run when compositions still vary', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    const compositions = [
      'content',
      'twoColumn',
      'threeColumn',
      'content',
      'metric',
      'table',
      'twoColumn',
      'threeColumn',
    ];
    for (var index = 0; index < compositions.length; index++) {
      slides[index]['composition'] = compositions[index];
      slides[index]['treatment'] = index < 4 ? 'content' : 'data';
    }

    final errors = validateDeckPlan(DeckPlanType.parse(data));

    expect(errors.where((error) => error.contains('treatment')), isEmpty);
  });

  test('reports design rhythm as typed non-blocking diagnostics', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    for (final slide in slides) {
      slide['composition'] = 'content';
      slide['treatment'] = 'content';
    }

    final issues = validateDeckPlanIssues(DeckPlanType.parse(data));
    final rhythmIssues = issues
        .where((issue) => issue.code == GenerationValidationCode.designRhythm)
        .toList();

    expect(rhythmIssues, isNotEmpty);
    expect(
      rhythmIssues,
      everyElement(
        isA<GenerationValidationIssue>().having(
          (issue) => issue.severity,
          'severity',
          GenerationValidationSeverity.diagnostic,
        ),
      ),
    );
    expect(issues.where((issue) => issue.isBlocking), isEmpty);
  });

  test('rejects a stale theme and broken section membership', () {
    final data = _hierarchicalPlan();
    final theme = Map<String, Object?>.of(
      data['theme']! as Map<String, Object?>,
    );
    data['theme'] = theme;
    final sections = data['sections']! as List<Map<String, Object?>>;
    theme['version'] = 999;
    final finalSectionKeys = sections.last['slideKeys']! as List<String>;
    finalSectionKeys.removeLast();
    final plan = DeckPlanType.parse(data);

    final errors = validateDeckPlan(plan);

    expect(
      errors,
      containsAll([
        contains('Unknown or stale presentation theme'),
        contains('partition all deck slides'),
      ]),
    );
  });

  test('rejects changes to exact requested theme and font selections', () {
    final plan = DeckPlanType.parse(_hierarchicalPlan());

    final errors = validateDeckPlan(
      plan,
      request: const DeckGenerationRequest(
        userIntent: 'Explain reliable delivery.',
        slideCount: 10,
        themeId: 'technical-paper',
        headlineFont: 'Lora',
      ),
    );

    expect(
      errors,
      containsAll([
        contains('changed requested theme'),
        contains('does not exactly preserve the requested'),
      ]),
    );
  });

  test('rejects a visual composition without its grounded element', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides[1]['composition'] = 'imageRight';
    slides[1]['elements'] = <Object?>[];
    final plan = DeckPlanType.parse(data);

    expect(
      validateDeckPlan(plan),
      contains(
        'Slide "cost" uses composition "imageRight" but does not plan '
        'the required image element.',
      ),
    );
  });

  test('rejects an invented visible domain but allows a supplied one', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = ['Continue at signal-canvas.com/launch'];
    final plan = DeckPlanType.parse(data);

    final rejected = validateDeckPlan(
      plan,
      request: const DeckGenerationRequest(
        userIntent: 'Create a ten-slide product narrative without URLs.',
        slideCount: 10,
      ),
    );
    final allowed = validateDeckPlan(
      plan,
      request: const DeckGenerationRequest(
        userIntent: 'Create a ten-slide product narrative.',
        slideCount: 10,
        groundedElements: [
          GroundedGenerationElement(
            type: 'qrcode',
            source: 'https://signal-canvas.com/launch',
            purpose: 'Continue the experience.',
          ),
        ],
      ),
    );

    expect(
      rejected,
      contains(
        'Slide "close" introduces ungrounded visible domain '
        '"signal-canvas.com". Use only domains supplied in userIntent or '
        'groundedElements.',
      ),
    );
    expect(
      allowed.where((error) => error.contains('ungrounded visible domain')),
      isEmpty,
    );
  });

  test('requires unsupported numeric claims to be visibly qualified', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = ['100% retention after 90 days'];
    final unqualified = DeckPlanType.parse(data);

    final rejected = validateDeckPlan(
      unqualified,
      request: const DeckGenerationRequest(
        userIntent: 'Create a ten-slide story using the supplied 42% result.',
        slideCount: 10,
      ),
    );
    slides.last['contentUnits'] = [
      'Projected scenario: 100% retention after an estimated 90 days',
    ];
    final qualified = DeckPlanType.parse(data);
    final allowed = validateDeckPlan(
      qualified,
      request: const DeckGenerationRequest(
        userIntent: 'Create a ten-slide story using the supplied 42% result.',
        slideCount: 10,
      ),
    );

    expect(
      rejected,
      contains(
        'Slide "close" uses numeric claim(s) 100%, 90 that are not present '
        'in userIntent. Remove them or label the containing copy as a '
        'projection, estimate, assumption, calculation, scenario, or planned '
        'target.',
      ),
    );
    final numericIssues = validateDeckPlanIssues(
      unqualified,
      request: const DeckGenerationRequest(
        userIntent: 'Create a ten-slide story using the supplied 42% result.',
        slideCount: 10,
      ),
    ).where((issue) => issue.code == GenerationValidationCode.numericGrounding);
    expect(numericIssues, isNotEmpty);
    expect(
      numericIssues,
      everyElement(
        isA<GenerationValidationIssue>().having(
          (issue) => issue.severity,
          'severity',
          GenerationValidationSeverity.diagnostic,
        ),
      ),
    );
    expect(numericIssues.where((issue) => issue.isBlocking), isEmpty);
    expect(
      allowed.where((error) => error.contains('uses numeric claim(s)')),
      isEmpty,
    );

    slides.last['contentUnits'] = [
      'Planned target: 50% adoption after the proposed 90-day pilot',
    ];
    final plannedTarget = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent:
            'Describe a future pilot without claiming observed results.',
        slideCount: 10,
      ),
    );
    expect(
      plannedTarget.where((error) => error.contains('uses numeric claim(s)')),
      isEmpty,
    );

    slides.last['contentUnits'] = ['6 design partners'];
    final normalizedNumberWords = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe the six design partners.',
        slideCount: 10,
      ),
    );
    expect(
      normalizedNumberWords.where(
        (error) => error.contains('uses numeric claim(s)'),
      ),
      isEmpty,
    );

    slides.last['contentUnits'] = [
      '3 onboarding steps in Section 3 with no change to source systems',
    ];
    final structuralCounts = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe onboarding with no change to source systems.',
        slideCount: 10,
      ),
    );
    expect(
      structuralCounts.where(
        (error) => error.contains('uses numeric claim(s)'),
      ),
      isEmpty,
    );
    slides.last['contentUnits'] = ['0% disruption to source systems'];
    final inventedZero = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe onboarding with no change to source systems.',
        slideCount: 10,
      ),
    );
    expect(
      inventedZero.singleWhere(
        (error) => error.contains('uses numeric claim(s)'),
      ),
      allOf(
        contains('numeric claim(s) 0%'),
        contains('preserve those exact qualitative words'),
      ),
    );
    slides.last['contentUnits'] = ['A zero-friction onboarding workflow'];
    final qualitativeZero = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe a smooth onboarding workflow.',
        slideCount: 10,
      ),
    );
    expect(
      qualitativeZero.where((error) => error.contains('uses numeric claim(s)')),
      isEmpty,
    );
    slides.last['contentUnits'] = ['Planned direction for next quarter'];
    final calendarQuarter = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe a roadmap direction.',
        slideCount: 10,
      ),
    );
    expect(
      calendarQuarter.where((error) => error.contains('uses numeric claim(s)')),
      isEmpty,
    );
    slides.last['contentUnits'] = ['A quarter of teams changed direction'];
    final fractionalQuarter = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe a roadmap direction.',
        slideCount: 10,
      ),
    );
    expect(
      fractionalQuarter.singleWhere(
        (error) => error.contains('uses numeric claim(s)'),
      ),
      contains('numeric claim(s) 25%'),
    );
    slides.last['contentUnits'] = ['Setup completes in one afternoon'];
    final structuralSourceDoesNotGroundDuration = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Bring the evidence into one workspace.',
        slideCount: 10,
      ),
    );
    slides.last['contentUnits'] = [
      'Illustrative scenario: initial insight in one afternoon',
    ];
    final qualifiedDuration = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Bring the evidence into one workspace.',
        slideCount: 10,
      ),
    );
    expect(
      structuralSourceDoesNotGroundDuration.singleWhere(
        (error) => error.contains('uses numeric claim(s)'),
      ),
      contains('claim(s) 1'),
    );
    expect(
      qualifiedDuration.where(
        (error) => error.contains('changes the supplied meaning'),
      ),
      isEmpty,
    );

    slides.last['contentUnits'] = ['1 beta outcome'];
    final structuralSourceDoesNotGroundMetric = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Turn fragmented evidence into one workspace.',
        slideCount: 10,
      ),
    );
    expect(
      structuralSourceDoesNotGroundMetric.singleWhere(
        (error) => error.contains('uses numeric claim(s)'),
      ),
      contains('numeric claim(s) 1'),
    );
  });

  test('does not ground internal planning prose as audience-facing copy', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last
      ..['purpose'] = 'Prioritize the 13 internal review checkpoints.'
      ..['contentBrief'] = 'Designed to reduce review friction in 13 drafts.'
      ..['continuity'] = 'Transition after the 13 internal checkpoints.';

    final issues = validateDeckPlanIssues(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Close with a practical decision.',
        slideCount: 10,
      ),
    );

    expect(
      issues.where(
        (issue) =>
            issue.slideKey == 'close' &&
            (issue.code == GenerationValidationCode.numericGrounding ||
                issue.code == GenerationValidationCode.commitmentGrounding),
      ),
      isEmpty,
    );
  });

  test('rejects an unsupported commercial commitment', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = ['Start your free trial today'];
    final plan = DeckPlanType.parse(data);

    expect(
      validateDeckPlan(
        plan,
        request: const DeckGenerationRequest(
          userIntent: 'Invite the audience to scan the supplied QR code.',
          slideCount: 10,
        ),
      ),
      contains(
        'Slide "close" introduces unsupported commitment claim(s): free '
        'trial. Remove them unless userIntent supplied the exact claim.',
      ),
    );
    slides.last['contentUnits'] = ['SOC2 Compliant governance'];
    expect(
      validateDeckPlan(
        DeckPlanType.parse(data),
        request: const DeckGenerationRequest(
          userIntent: 'Describe the governance model.',
          slideCount: 10,
        ),
      ).singleWhere((error) => error.contains('soc2')),
      allOf(contains('unsupported commitment claim(s)'), contains('soc2')),
    );
  });

  test('reports broad editorial commitments without blocking the plan', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = ['Prioritize evidence before commitments'];

    final issues = validateDeckPlanIssues(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Close with an evidence-led operating decision.',
        slideCount: 10,
      ),
    );
    final commitmentIssues = issues
        .where(
          (issue) =>
              issue.code == GenerationValidationCode.commitmentGrounding &&
              issue.slideKey == 'close',
        )
        .toList();

    expect(commitmentIssues, hasLength(1));
    expect(
      commitmentIssues.single.severity,
      GenerationValidationSeverity.diagnostic,
    );
    expect(commitmentIssues.where((issue) => issue.isBlocking), isEmpty);
  });

  test('rejects invented availability, production, and delivery claims', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = [
      'Proven in production environments',
      'Signal Canvas is now live',
      'Launch in minutes with pre-built connectors',
      'Enterprise-grade security validated with one-click setup',
    ];

    final errors = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe a fictional product beta and adoption options.',
        slideCount: 10,
      ),
    );
    final commitmentError = errors.singleWhere(
      (error) => error.contains('unsupported commitment claim(s)'),
    );

    for (final phrase in [
      'proven in production',
      'production environments',
      'now live',
      'pre-built connectors',
      'in minutes',
      'enterprise-grade',
      'security validated',
      'one-click',
    ]) {
      expect(commitmentError, contains(phrase));
    }

    slides.last['contentUnits'] = ['Omitting real-time claims from this plan'];
    final negated = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe a fictional product beta.',
        slideCount: 10,
      ),
    );
    expect(negated.where((error) => error.contains('real-time')), isEmpty);

    slides.last['contentUnits'] = [
      'Illustrative option: SSO, data residency, and automated workflows',
    ];
    final explicitlyHypothetical = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe possible enterprise governance directions.',
        slideCount: 10,
      ),
    );
    expect(
      explicitlyHypothetical.where(
        (error) => error.contains('unsupported commitment claim(s)'),
      ),
      isEmpty,
    );
  });

  test('rejects evidence amplification, causality, and absolute scope', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = [
      'Verified performance demonstrated essential real-world impact at scale',
      '42% less weekly synthesis time by eliminating lag, reclaiming hours, '
          'and enabling rapid high-value work',
      'Universal capture maps every product signal back to immutable permanent '
          'history from any existing data stack',
      'No architectural disruption for teams from diverse industries',
      'Automated collection, smart triage, contextual tagging, and notifications',
      'Intensive software testing and feedback-driven development',
      'Technical documentation and launch team access',
    ];

    final errors = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent:
            'Present beta observations and discuss the evidence inbox without '
            'inventing unsourced claims. Teams spent 42% less weekly synthesis '
            'time.',
        slideCount: 10,
      ),
    );
    final error = errors.singleWhere(
      (candidate) => candidate.contains('unsupported commitment claim(s)'),
    );

    for (final phrase in [
      'verified',
      'demonstrated',
      'essential',
      'real-world impact',
      'at scale',
      'by eliminating',
      'hours',
      'rapid',
      'high-value',
      'universal capture',
      'every product signal',
      'immutable',
      'permanent',
      'any existing data stack',
      'no architectural disruption',
      'diverse industries',
      'automated',
      'smart triage',
      'tagging',
      'notifications',
      'intensive software testing',
      'feedback-driven development',
      'documentation',
      'launch team',
    ]) {
      expect(error, contains(phrase));
    }
  });

  test('allows ordinary causal wording in non-metric narrative framing', () {
    final data = _hierarchicalPlan();
    data['story'] =
        'Address friction caused by fragmented evidence, then present the '
        'supplied beta observations.';
    final sections = data['sections']! as List<Map<String, Object?>>;
    sections.first['purpose'] =
        'Frame the context caused by disconnected evidence sources.';
    sections[1]['purpose'] = 'Introduce observations from six design partners.';

    final errors = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent:
            'Explain fragmented evidence and observations from six design '
            'partners.',
        slideCount: 10,
      ),
    );

    expect(errors.where((error) => error.contains('caused by')), isEmpty);
  });

  test('requires beta capabilities and commercial shapes to stay qualified', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = [
      'Auto-collects support tags through a REST API',
      'Live-updating evidence with direct authentication',
      'Free: Core inbox and triage',
      'Pro: Advanced linked insights',
      'Exclusive launch event access',
    ];

    final rejected = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent:
            'Cover the evidence inbox, API extensibility, onboarding, pricing '
            'shape, and roadmap for a fictional beta product.',
        slideCount: 10,
      ),
    );
    final error = rejected.singleWhere(
      (candidate) => candidate.contains('unsupported commitment claim(s)'),
    );
    for (final phrase in [
      'auto-collects',
      'rest api',
      'live-updating',
      'direct authentication',
      'pricing tier "free"',
      'pricing tier "pro"',
      'exclusive launch event access',
    ]) {
      expect(error, contains(phrase));
    }

    slides.last['contentUnits'] = [
      'Proposed option: auto-collect support tags through a REST API',
      'Illustrative option: live-updating evidence with direct authentication',
      'Proposed tier — Free: Core inbox and triage',
      'Proposed tier — Pro: Advanced linked insights',
    ];
    final qualified = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent:
            'Cover the evidence inbox, API extensibility, onboarding, pricing '
            'shape, and roadmap for a fictional beta product.',
        slideCount: 10,
      ),
    );
    expect(
      qualified.where(
        (candidate) => candidate.contains('unsupported commitment claim(s)'),
      ),
      isEmpty,
    );
  });

  test(
    'allows requested category labels without treating them as commitments',
    () {
      final data = _hierarchicalPlan();
      final slides = data['slides']! as List<Map<String, Object?>>;
      slides.last['contentUnits'] = [
        'Pricing model',
        'Core features',
        'Data integrity',
      ];

      final errors = validateDeckPlan(
        DeckPlanType.parse(data),
        request: const DeckGenerationRequest(
          userIntent:
              'Cover pricing shape, core product capabilities, and system '
              'integrity without inventing implementation details.',
          slideCount: 10,
        ),
      );

      expect(
        errors.where(
          (candidate) => candidate.contains('unsupported commitment claim(s)'),
        ),
        isEmpty,
      );
    },
  );

  test('preserves grounded handoff identity in a qrcode plan', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last
      ..['composition'] = 'qrcode'
      ..['contentUnits'] = ['Scan to explore the live Signal Canvas experience']
      ..['elements'] = [
        {
          'type': 'qrcode',
          'source': 'https://superdeck-dev.web.app',
          'purpose': 'Let the audience open the live SuperDeck experience',
        },
      ];
    const request = DeckGenerationRequest(
      userIntent: 'End with the supplied QR code.',
      slideCount: 10,
      groundedElements: [
        GroundedGenerationElement(
          type: 'qrcode',
          source: 'https://superdeck-dev.web.app',
          purpose: 'Let the audience open the live SuperDeck experience',
        ),
      ],
    );

    final rejected = validateDeckPlan(
      DeckPlanType.parse(data),
      request: request,
    );
    expect(
      rejected,
      contains(
        'Slide "close" qrcode handoff omits grounded purpose term(s): '
        'superdeck. Preserve the supplied destination or experience identity '
        'in audience-facing copy.',
      ),
    );

    slides.last['contentUnits'] = [
      'Scan to open the live SuperDeck experience',
    ];
    final preserved = validateDeckPlan(
      DeckPlanType.parse(data),
      request: request,
    );
    expect(
      preserved.where((candidate) => candidate.contains('handoff omits')),
      isEmpty,
    );
  });

  test('keeps internal narrative grounding non-blocking', () {
    final data = _hierarchicalPlan();
    final sections = data['sections']! as List<Map<String, Object?>>;
    final slides = data['slides']! as List<Map<String, Object?>>;
    sections.first['transition'] =
        'The architecture is already proven through rigorous results.';
    slides.last['continuity'] =
        'The workflow was validated during the fictional beta.';

    final issues = validateDeckPlanIssues(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Describe a fictional beta using only supplied facts.',
        slideCount: 10,
      ),
    );

    final narrativeIssue = issues.singleWhere(
      (issue) => issue.message.startsWith('Deck narrative'),
    );
    expect(
      narrativeIssue.message,
      allOf(contains('already proven'), contains('rigorous results')),
    );
    expect(narrativeIssue.severity, GenerationValidationSeverity.diagnostic);
    expect(
      issues.where(
        (issue) =>
            issue.slideKey == 'close' &&
            issue.code == GenerationValidationCode.commitmentGrounding,
      ),
      isEmpty,
    );
  });

  test('rejects exact metrics inflated with an unsupplied plus sign', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = ['38+ design partners'];

    final exactOnly = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'The beta included 38 design partners.',
        slideCount: 10,
      ),
    );
    final explicitlyOpenEnded = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'The beta included 38+ design partners.',
        slideCount: 10,
      ),
    );

    expect(
      exactOnly.singleWhere(
        (error) => error.contains('changes the supplied meaning'),
      ),
      contains('claim(s) 38'),
    );
    expect(
      explicitlyOpenEnded.where(
        (error) => error.contains('changes the supplied meaning'),
      ),
      isEmpty,
    );
  });

  test('reports a supplied metric reused with a different meaning', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides.last['contentUnits'] = ['Reclaiming 42% of the work week'];
    final changedMeaning = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Teams spent 42% less weekly synthesis time.',
        slideCount: 10,
      ),
    );
    final changedMeaningIssues = validateDeckPlanIssues(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Teams spent 42% less weekly synthesis time.',
        slideCount: 10,
      ),
    ).where((issue) => issue.code == GenerationValidationCode.numericMeaning);
    expect(changedMeaningIssues, isNotEmpty);
    expect(
      changedMeaningIssues,
      everyElement(
        isA<GenerationValidationIssue>().having(
          (issue) => issue.severity,
          'severity',
          GenerationValidationSeverity.diagnostic,
        ),
      ),
    );
    expect(changedMeaningIssues.where((issue) => issue.isBlocking), isEmpty);
    slides.last['contentUnits'] = ['42% less weekly synthesis time'];
    final preservedMeaning = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Teams spent 42% less weekly synthesis time.',
        slideCount: 10,
      ),
    );
    slides.last['title'] = '42% productivity gain';
    slides.last['contentUnits'] = ['Less weekly synthesis time'];
    final standaloneMetric = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent: 'Teams spent 42% less weekly synthesis time.',
        slideCount: 10,
      ),
    );
    slides.last['contentUnits'] = [
      '19% decision velocity in the experiment',
      'No change to source systems',
    ];
    final normalizedWording = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent:
            'The beta delivered 19% faster experiment decisions and no '
            'change to source-of-truth systems.',
        slideCount: 10,
      ),
    );
    slides.last['title'] = 'Beta cohort';
    slides.last['contentUnits'] = [
      'One unified view',
      'Six enterprise beta cohort',
    ];
    final changedCohortMeaning = validateDeckPlan(
      DeckPlanType.parse(data),
      request: const DeckGenerationRequest(
        userIntent:
            'Create one evidence workspace validated by six design partners.',
        slideCount: 10,
      ),
    );

    expect(
      changedMeaning,
      contains(
        'Slide "close" changes the supplied meaning of numeric claim(s) 42%. '
        'Preserve each claim\'s original unit, comparison, and subject.',
      ),
    );
    expect(
      preservedMeaning.where(
        (error) => error.contains('changes the supplied meaning'),
      ),
      isEmpty,
    );
    expect(
      standaloneMetric.where(
        (error) => error.contains('changes the supplied meaning'),
      ),
      isEmpty,
    );
    expect(
      normalizedWording.where(
        (error) => error.contains('changes the supplied meaning'),
      ),
      isEmpty,
    );
    expect(
      changedCohortMeaning.singleWhere(
        (error) => error.contains('changes the supplied meaning'),
      ),
      contains('claim(s) 6'),
    );
  });

  test('reports a display treatment mismatch without blocking the plan', () {
    final data = _hierarchicalPlan();
    final slides = data['slides']! as List<Map<String, Object?>>;
    slides[6]['treatment'] = 'hero';
    final plan = DeckPlanType.parse(data);
    final issues = validateDeckPlanIssues(plan);

    expect(
      issues.singleWhere((issue) => issue.code == .treatmentIntent),
      isA<GenerationValidationIssue>()
          .having(
            (issue) => issue.severity,
            'severity',
            GenerationValidationSeverity.diagnostic,
          )
          .having((issue) => issue.isBlocking, 'isBlocking', isFalse)
          .having(
            (issue) => issue.message,
            'message',
            contains(
              'Slide "process" pairs treatment "hero" with composition '
              '"threeColumn"; allowed compositions are title.',
            ),
          ),
    );
  });

  test('requires metric plans to name the grounded numeric fact', () {
    final plan = DeckPlanType.parse(_hierarchicalPlan());

    expect(
      validateDeckPlan(
        plan,
        request: const DeckGenerationRequest(
          userIntent: 'Teams spent 42% less weekly synthesis time.',
          slideCount: 10,
        ),
      ),
      contains(
        'Slide "signal" selects composition "metric" without an explicit '
        'audience-facing numeric fact. Put the exact grounded value and what '
        'it measures in contentUnits, or choose a non-metric composition.',
      ),
    );
  });
}

Map<String, Object?> _validSlide({required String key}) => {
  'key': key,
  'title': 'Title',
  'purpose': 'Purpose',
  'sectionKey': 'main',
  'assertion': 'A concrete assertion',
  'contentUnits': ['A concrete supporting point'],
  'narrativeRole': 'insight',
  'contentBrief': 'Brief',
  'continuity': 'Continuity',
  'composition': 'content',
  'treatment': 'content',
  'density': 'balanced',
  'elements': <Object?>[],
};

const _validTheme = <String, Object?>{
  'id': 'editorial-midnight',
  'version': 1,
  'density': 'balanced',
};

Map<String, Object?> _hierarchicalPlan() {
  const slideKeys = [
    'opening',
    'cost',
    'signal',
    'compare',
    'system',
    'metric',
    'process',
    'practice',
    'commitment',
    'close',
  ];
  const compositions = [
    'title',
    'content',
    'metric',
    'table',
    'twoColumn',
    'metric',
    'threeColumn',
    'quote',
    'titleLeft',
    'title',
  ];
  const treatments = [
    'hero',
    'content',
    'data',
    'data',
    'content',
    'data',
    'content',
    'quote',
    'section',
    'closing',
  ];
  const sectionKeys = [
    'tension',
    'tension',
    'tension',
    'system',
    'system',
    'system',
    'system',
    'action',
    'action',
    'action',
  ];

  return {
    'topic': 'Reliable software delivery',
    'story': 'Move from release anxiety to measurable confidence.',
    'theme': _validTheme,
    'sections': [
      {
        'key': 'tension',
        'title': 'The tension',
        'purpose': 'Make release uncertainty concrete.',
        'transition': 'Turn the cost into a system design question.',
        'slideKeys': slideKeys.sublist(0, 3),
      },
      {
        'key': 'system',
        'title': 'The system',
        'purpose': 'Explain the operating model.',
        'transition': 'Translate the model into team action.',
        'slideKeys': slideKeys.sublist(3, 7),
      },
      {
        'key': 'action',
        'title': 'The action',
        'purpose': 'Make the first commitment practical.',
        'transition': 'Close with a measurable next step.',
        'slideKeys': slideKeys.sublist(7),
      },
    ],
    'slides': [
      for (var index = 0; index < slideKeys.length; index++)
        {
          ..._validSlide(key: slideKeys[index]),
          'sectionKey': sectionKeys[index],
          'assertion': 'Assertion for ${slideKeys[index]}',
          'contentUnits': [
            'Evidence for ${slideKeys[index]}',
            'Implication for ${slideKeys[index]}',
          ],
          'composition': compositions[index],
          'treatment': treatments[index],
          'density': index.isEven ? 'spacious' : 'balanced',
        },
    ],
  };
}

Map<String, Object?> _scaledHierarchicalPlan(int count) {
  const compositions = [
    'title',
    'content',
    'metric',
    'table',
    'twoColumn',
    'threeColumn',
    'quote',
  ];
  const treatments = [
    'hero',
    'content',
    'data',
    'data',
    'content',
    'data',
    'quote',
  ];
  final slideKeys = [
    for (var index = 0; index < count; index++) 'slide-$index',
  ];
  final sectionCount = count == 20 ? 4 : 3;
  final slidesPerSection = count ~/ sectionCount;
  final sections = <Map<String, Object?>>[];
  final sectionForSlide = <String, String>{};
  for (var sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
    final start = sectionIndex * slidesPerSection;
    final end = sectionIndex == sectionCount - 1
        ? count
        : start + slidesPerSection;
    final key = 'section-$sectionIndex';
    final keys = slideKeys.sublist(start, end);
    sections.add({
      'key': key,
      'title': 'Section ${sectionIndex + 1}',
      'purpose': 'Advance act ${sectionIndex + 1}.',
      'transition': 'Prepare the audience for the next act.',
      'slideKeys': keys,
    });
    for (final slideKey in keys) {
      sectionForSlide[slideKey] = key;
    }
  }

  return {
    'topic': 'Scaled quality fixture',
    'story': 'Move through a complete evidence-led narrative.',
    'theme': _validTheme,
    'sections': sections,
    'slides': [
      for (var index = 0; index < count; index++)
        {
          ..._validSlide(key: slideKeys[index]),
          'sectionKey': sectionForSlide[slideKeys[index]],
          'assertion': 'Assertion for ${slideKeys[index]}',
          'contentUnits': [
            'Evidence for ${slideKeys[index]}',
            'Implication for ${slideKeys[index]}',
          ],
          'narrativeRole': index == 0
              ? 'opening'
              : index == count - 1
              ? 'closing'
              : 'insight',
          'composition': compositions[index % compositions.length],
          'treatment': treatments[index % treatments.length],
          'density': index % 3 == 0 ? 'spacious' : 'balanced',
        },
    ],
  };
}
