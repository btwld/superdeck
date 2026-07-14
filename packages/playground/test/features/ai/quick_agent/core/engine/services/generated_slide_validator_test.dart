import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_element_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  test('normalizes generation args into canonical flattened arguments', () {
    final slide = _slideWithBlock({
      'type': 'widget',
      'name': 'image',
      'args': {'src': 'assets/system-map.png', 'fit': 'contain'},
      'flex': 2,
    });

    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: slide,
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(errors, isEmpty);
    final normalized = sanitizeGeneratedSlides([slide]).single;
    final parsed = Slide.parse(Map<String, Object?>.from(normalized));
    final widget = parsed.sections.single.blocks.single as WidgetBlock;
    expect(widget.args, containsPair('src', 'assets/system-map.png'));
    expect(widget.args, containsPair('fit', 'contain'));
  });

  test('reports widget arguments copied from another catalog entry', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'widget',
        'name': 'image',
        'args': {
          'src': 'assets/system-map.png',
          'text': 'Not an image argument',
          'url': 'https://example.com',
        },
      }),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(errors.single, contains('Remove unsupported arguments: text, url'));
    expect(errors.single, contains('Allowed arguments:'));
  });

  test('rejects unregistered widgets and invalid built-in arguments', () {
    expect(
      validateGeneratedSlide(
        expectedKey: 'test-slide',
        rawSlide: _slideWithBlock({'type': 'widget', 'name': 'unknown-chart'}),
        elementCatalog: GenerationElementCatalog.builtIn(),
      ),
      contains('Widget "unknown-chart" is not registered for generation.'),
    );
    expect(
      validateGeneratedSlide(
        expectedKey: 'test-slide',
        rawSlide: _slideWithBlock({'type': 'widget', 'name': 'webview'}),
        elementCatalog: GenerationElementCatalog.builtIn(),
      ).single,
      contains('invalid arguments'),
    );
  });

  test('allows an application-registered custom widget descriptor', () {
    final catalog = GenerationElementCatalog.builtIn(
      custom: [
        GenerationElementDescriptor(
          name: 'metric-card',
          description: 'A product metric.',
          arguments: 'value (required)',
          argumentSchema: Ack.object({'value': Ack.number()}),
        ),
      ],
    );

    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'widget',
        'name': 'metric-card',
        'value': 42,
      }),
      elementCatalog: catalog,
    );

    expect(errors, isEmpty);
    expect(catalog.formatForPrompt(), contains('metric-card'));
    expect(catalog.argumentProperties, contains('value'));
  });

  test('rejects inconsistent or overly dense Markdown tables', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '| A | B | C | D | E |\n'
            '|---|---|---|---|---|\n'
            '| one | two |\n',
      }),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains('Markdown table must use at most 4 columns for readability.'),
    );
    expect(
      errors,
      contains('Markdown table rows must have a consistent column count.'),
    );
  });

  test('rejects slide separators but allows them inside fenced code', () {
    final catalog = GenerationElementCatalog.builtIn();
    final unsafeErrors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': 'Before\n\n---\n\nAfter',
      }),
      elementCatalog: catalog,
    );
    final fencedErrors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '```text\n---\n```',
      }),
      elementCatalog: catalog,
    );

    expect(unsafeErrors.single, contains('reserved for slide boundaries'));
    expect(fencedErrors, isEmpty);
  });

  test('rejects raw content blocks that collapse during sanitization', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: {
        'key': 'test-slide',
        'options': {'title': 'Strategic comparison', 'style': 'data'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': '## Strategic comparison'},
            ],
          },
          {
            'type': 'section',
            'blocks': [
              {'type': 'block'},
            ],
          },
        ],
      },
      planSlide: _planSlide(composition: 'table'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Content block in section 2, block 1 must contain non-empty Markdown.',
      ),
    );
    expect(errors, contains('Composition "table" requires a Markdown table.'));
  });

  test('rejects duplicate and unplanned generated elements', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: {
        'key': 'test-slide',
        'options': {'title': 'Live portal', 'style': 'visual'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              for (var index = 0; index < 5; index++)
                {
                  'type': 'widget',
                  'name': 'webview',
                  'args': {'url': 'https://example.com'},
                },
            ],
          },
          {
            'type': 'section',
            'blocks': [
              {
                'type': 'widget',
                'name': 'qrcode',
                'args': {'text': 'https://example.com'},
              },
            ],
          },
        ],
      },
      planSlide: _planSlide(
        composition: 'webview',
        elements: [
          {
            'type': 'webview',
            'purpose': 'Show the supplied portal.',
            'source': 'https://example.com',
          },
        ],
      ),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(errors, contains('Expected exactly 1 "webview" widget; found 5.'));
    expect(errors, contains('Widget "qrcode" was not planned for this slide.'));
  });

  test('rejects a heading-only non-title composition', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## The right fit for our stage',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Composition "content" requires substantive content beyond a title.',
      ),
    );
  });

  test('rejects a slide that ignores its planned visual treatment', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: {
        'key': 'test-slide',
        'options': {'title': 'Test', 'style': 'data'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {
                'type': 'block',
                'content': '## The point\n\nOne concrete supporting idea.',
              },
            ],
          },
        ],
      },
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains('Slide style must be exactly the planned treatment "content".'),
    );
  });

  test('rejects content beyond the planned density budget', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '# Evidence\n\n${List.filled(120, 'specific').join(' ')}',
      }),
      planSlide: _planSlide(composition: 'content', density: 'spacious'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Slide exceeds the spacious content budget of 480 visible characters.',
      ),
    );
  });

  test('rejects a display heading that is too long for a title row', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## Planning twelve months ahead guarantees we build yesterday’s problems\n\n'
            'One concrete supporting idea.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Display heading "Planning twelve months ahead guarantees we build '
        'yesterday’s problems" has 9 words; use at most 8.',
      ),
    );
  });

  test('reserves H1 for display treatments and numeric metrics', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '# Content title\n\nOne concrete supporting idea.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'H1 is reserved for title and numeric metric compositions; use H2 '
        'for the content composition.',
      ),
    );
  });

  test('mechanically demotes forbidden H1 without rewriting its words', () {
    final raw = _slideWithBlock({
      'type': 'block',
      'content': '# Fund Outcomes Over Forecasts\n\n## Keep This Subtitle',
    });

    final normalized = normalizeGeneratedSlideForPlan(
      rawSlide: raw,
      planSlide: _planSlide(composition: 'titleLeft'),
    );
    final block =
        ((normalized['sections'] as List).single as Map)['blocks'] as List;

    expect(
      (block.single as Map)['content'],
      '## Fund Outcomes Over Forecasts\n\n## Keep This Subtitle',
    );
    expect(
      (((raw['sections'] as List).single as Map)['blocks'] as List).single,
      containsPair(
        'content',
        '# Fund Outcomes Over Forecasts\n\n## Keep This Subtitle',
      ),
      reason: 'Normalization must not mutate the traceable raw draft.',
    );
  });

  test('anchors implicit title and body rows in a vertical composition', () {
    final raw = {
      'key': 'test-slide',
      'options': {'title': 'Extensibility', 'style': 'content'},
      'sections': [
        {
          'type': 'section',
          'blocks': [
            {
              'type': 'block',
              'content':
                  '## Build custom signal flows with an API-first architecture',
            },
          ],
        },
        {
          'type': 'section',
          'blocks': [
            {'type': 'block', 'content': 'One concise supporting idea.'},
          ],
        },
      ],
    };

    final normalized = normalizeGeneratedSlideForPlan(
      rawSlide: raw,
      planSlide: _planSlide(composition: 'content'),
    );
    final sections = normalized['sections']! as List;
    final titleBlock =
        ((sections.first as Map)['blocks']! as List).single as Map;
    final bodyBlock = ((sections.last as Map)['blocks']! as List).single as Map;

    expect(titleBlock['align'], 'bottomLeft');
    expect(bodyBlock['align'], 'topLeft');
    expect(
      (((raw['sections']! as List).first as Map)['blocks']! as List).single,
      isNot(contains('align')),
      reason: 'Normalization must not mutate the traceable raw draft.',
    );
  });

  test('drops invalid optional comments while preserving visible content', () {
    final raw = _slideWithBlock({
      'type': 'block',
      'content': '## Exact visible evidence',
    });
    raw['comments'] = ['Nearly half the work vanished.'];

    final normalized = removeInvalidOptionalSpeakerComments(
      rawSlide: raw,
      validationErrors: const [
        'Speaker comments use numeric claim(s) 50% that are not present.',
      ],
    );
    final normalizedWithVisibleError = removeInvalidOptionalSpeakerComments(
      rawSlide: raw,
      validationErrors: const [
        'Visible content uses numeric claim(s) 50% that are not present.',
        'Speaker comments use numeric claim(s) 50% that are not present.',
      ],
    );

    expect(normalized['comments'], isEmpty);
    expect(normalizedWithVisibleError['comments'], isEmpty);
    expect(
      ((normalizedWithVisibleError['sections']! as List).single
          as Map)['blocks'],
      isNotEmpty,
    );
    expect(raw['comments'], ['Nearly half the work vanished.']);
  });

  test('rejects overpacked three-section composition hybrids', () {
    final raw = {
      'key': 'test-slide',
      'options': {'title': 'Operating rhythm', 'style': 'content'},
      'sections': [
        for (final content in [
          '## Operating Rhythm',
          'One concrete supporting idea.',
          '| Signal | Cadence |\n|---|---|\n| Evidence | Weekly |',
        ])
          {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': content},
            ],
          },
      ],
    };

    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: raw,
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Composition "content" supports at most 2 sections; found 3. '
        'Simplify the slide instead of stacking another content row.',
      ),
    );
  });

  test('keeps title compositions free of dense structured content', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Make the decision\n\n- First action\n- Second action',
      }),
      planSlide: _planSlide(composition: 'title'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Composition "title" must stay minimal: use display headings and at '
        'most one short supporting paragraph, without lists, tables, or quotes.',
      ),
    );
  });

  test('keeps title display type in one full-height section', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: {
        'key': 'test-slide',
        'options': {'title': 'Opening', 'style': 'content'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': '# Beyond Roadmap Theater'},
            ],
          },
          {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': 'A concise supporting sentence.'},
            ],
          },
        ],
      },
      planSlide: _planSlide(composition: 'title'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Composition "title" must use exactly 1 section so the display '
        'heading has enough vertical room; found 2. Put the H1 and optional '
        'short support copy in one content block.',
      ),
    );
  });

  test('requires the table composition for Markdown tables', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## Operating rhythm\n\n| Signal | Cadence |\n|---|---|\n| Evidence | Weekly |',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Markdown tables require composition "table"; the plan selected '
        '"content".',
      ),
    );
  });

  test('rejects a visible domain that was not supplied by the plan', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## Continue the work\n\nVisit signal-canvas.com/launch today.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(
      errors,
      contains(
        'Visible content uses ungrounded domain "signal-canvas.com". Use '
        'only a URL or domain supplied by the plan.',
      ),
    );
  });

  test('requires unsupported visible numeric claims to be qualified', () {
    const request = DeckGenerationRequest(
      userIntent: 'Explain the six-part beta with its supplied 42% result.',
      slideCount: 1,
    );
    final rejected = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Beta proof\n\n100% retention over 90 days.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: request,
    );
    final allowed = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## Beta scenario\n\nProjected 100% retention over an estimated 90 days.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: request,
    );

    expect(
      rejected,
      contains(
        'Visible content uses numeric claim(s) 100%, 90 that are not present '
        'in userIntent. Remove them or label the containing copy as a '
        'projection, estimate, assumption, calculation, or scenario.',
      ),
    );
    expect(
      allowed.where(
        (error) => error.contains('Visible content uses numeric claim(s)'),
      ),
      isEmpty,
    );

    final structuralCounts = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## 3 onboarding steps\n\nNo change to source systems.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Explain onboarding with no change to source systems.',
        slideCount: 1,
      ),
    );
    expect(
      structuralCounts.where(
        (error) => error.contains('Visible content uses numeric claim(s)'),
      ),
      isEmpty,
    );
    final inventedZero = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Integration\n\n0% disruption to source systems.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Explain onboarding with no change to source systems.',
        slideCount: 1,
      ),
    );
    expect(
      inventedZero.singleWhere(
        (error) => error.contains('Visible content uses numeric claim(s)'),
      ),
      contains('numeric claim(s) 0%'),
    );
    final enumeratedSteps = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## Steps\n\n### 1. Connect\n\n### 2. Invite\n\n### 3. Decide',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Explain the onboarding workflow.',
        slideCount: 1,
      ),
    );
    expect(
      enumeratedSteps.where(
        (error) => error.contains('Visible content uses numeric claim(s)'),
      ),
      isEmpty,
    );
    final inventedDuration = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Ready in one afternoon\n\nBring evidence together.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Bring evidence into one workspace.',
        slideCount: 1,
      ),
    );
    expect(
      inventedDuration.singleWhere(
        (error) => error.contains('uses numeric claim(s)'),
      ),
      contains('claim(s) 1'),
    );
  });

  test('rejects an unsupported visible commercial commitment', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Continue\n\nStart your free trial today.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Invite the audience to continue.',
        slideCount: 1,
      ),
    );

    final waitlistErrors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Continue\n\nJoin the priority access waitlist.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Invite the audience to continue.',
        slideCount: 1,
      ),
    );
    final complianceErrors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Governance\n\nSOC2 Compliant controls.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Describe a governance model.',
        slideCount: 1,
      ),
    );

    expect(
      errors,
      contains(
        'Visible content introduces unsupported commitment claim(s): free '
        'trial. Remove them unless userIntent supplied the exact claim.',
      ),
    );
    expect(
      waitlistErrors.singleWhere((error) => error.contains('waitlist')),
      contains('unsupported commitment claim(s): waitlist'),
    );
    expect(
      complianceErrors.singleWhere((error) => error.contains('soc2')),
      allOf(contains('unsupported commitment claim(s)'), contains('soc2')),
    );
  });

  test('grounds speaker comments as strictly as visible content', () {
    final rawSlide = _slideWithBlock({
      'type': 'block',
      'content': '## Beta evidence\n\nValidated with design partners.',
    });
    rawSlide['comments'] = ['Results came from a 12-week beta.'];

    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: rawSlide,
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Summarize the design-partner beta.',
        slideCount: 1,
      ),
    );

    expect(
      errors.singleWhere(
        (error) => error.contains('Speaker comments use numeric claim(s)'),
      ),
      contains('numeric claim(s) 12'),
    );
  });

  test('rejects invented demand and temporal claims in speaker comments', () {
    final rawSlide = _slideWithBlock({
      'type': 'block',
      'content': '## Roadmap\n\nA qualified product direction.',
    });
    rawSlide['comments'] = [
      'This was the most requested feature months later.',
      'Teams spend hours rebuilding context.',
    ];

    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: rawSlide,
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Describe a product roadmap direction.',
        slideCount: 1,
      ),
    );

    expect(
      errors.singleWhere(
        (error) => error.contains('unsupported commitment claim(s)'),
      ),
      allOf(
        contains('most requested'),
        contains('months later'),
        contains('spend hours'),
      ),
    );
  });

  test('rejects amplified evidence and invented causal explanations', () {
    final rawSlide = _slideWithBlock({
      'type': 'block',
      'content':
          '## Verified at scale\n\nTeams spent 42% less weekly synthesis time '
          'by eliminating evidence lag and reclaiming hours for rapid, '
          'high-value work. Every product signal maps back to permanent, '
          'immutable history from any existing data stack. Automated collection '
          'uses smart triage, tagging, and notifications.',
    });
    rawSlide['comments'] = [
      'Intensive software testing and feedback-driven development demonstrated '
          'that this workflow is essential in the real-world. Technical '
          'documentation and launch team access are available.',
    ];

    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: rawSlide,
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent:
            'Summarize the beta observation: teams spent 42% less weekly '
            'synthesis time.',
        slideCount: 1,
      ),
    );
    final visible = errors.singleWhere(
      (error) => error.startsWith('Visible content introduces'),
    );
    final comments = errors.singleWhere(
      (error) => error.startsWith('Speaker comments introduce'),
    );

    for (final phrase in [
      'verified',
      'at scale',
      'by eliminating',
      'hours',
      'rapid',
      'high-value',
      'every product signal',
      'permanent',
      'immutable',
      'any existing data stack',
      'automated',
      'smart triage',
      'tagging',
      'notifications',
    ]) {
      expect(visible, contains(phrase));
    }
    for (final phrase in [
      'intensive software testing',
      'feedback-driven development',
      'demonstrated',
      'essential',
      'real-world',
      'documentation',
      'launch team',
    ]) {
      expect(comments, contains(phrase));
    }
  });

  test('treats a dozen as an unsupported audience-facing number', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Fragmented evidence\n\nSignals span a dozen tools.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Show that evidence is fragmented across tools.',
        slideCount: 1,
      ),
    );

    expect(
      errors.singleWhere((error) => error.contains('uses numeric claim(s)')),
      contains('claim(s) 12'),
    );
  });

  test('rejects a supplied metric reused with a different meaning', () {
    const request = DeckGenerationRequest(
      userIntent: 'Teams spent 42% less weekly synthesis time.',
      slideCount: 1,
    );
    final changedMeaning = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Reclaiming 42% of the work week',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: request,
    );
    final inventedCausalMeaning = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## Teams lose 42% of their time just hunting for context',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: request,
    );
    final preservedMeaning = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## 42% less weekly synthesis time',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: request,
    );
    final broadenedFraction = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## 42% less weekly synthesis time\n\nTeams reclaimed nearly half '
            'their week.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: request,
    );

    expect(
      changedMeaning,
      contains(
        'Visible content changes the supplied meaning of numeric claim(s) '
        '42%. Preserve each claim\'s original unit, comparison, and subject.',
      ),
    );
    expect(
      inventedCausalMeaning,
      contains(
        'Visible content changes the supplied meaning of numeric claim(s) '
        '42%. Preserve each claim\'s original unit, comparison, and subject.',
      ),
    );
    expect(
      preservedMeaning.where(
        (error) => error.contains('changes the supplied meaning'),
      ),
      isEmpty,
    );
    expect(
      broadenedFraction.singleWhere(
        (error) => error.contains('Visible content uses numeric claim(s)'),
      ),
      contains('numeric claim(s) 50%'),
    );
  });

  test('identifies metric drift specifically in speaker comments', () {
    final rawSlide = _slideWithBlock({
      'type': 'block',
      'content': '# 19%\n\n## Faster experiment decisions',
    });
    rawSlide['comments'] = ['A 19% increase in general decision velocity.'];

    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: rawSlide,
      planSlide: _planSlide(composition: 'metric', treatment: 'data'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'The beta produced 19% faster experiment decisions.',
        slideCount: 1,
      ),
    );

    expect(
      errors,
      contains(
        'Speaker comments change the supplied meaning of numeric claim(s) '
        '19%. Preserve each claim\'s original unit, comparison, and subject.',
      ),
    );
    expect(
      errors.where((error) => error.startsWith('Visible content changes')),
      isEmpty,
    );
  });

  test('rejects open-ended metric inflation unless explicitly supplied', () {
    final exactOnly = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## 38+ design partners',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'The beta included 38 design partners.',
        slideCount: 1,
      ),
    );
    final explicitlyOpenEnded = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## 38+ design partners',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'The beta included 38+ design partners.',
        slideCount: 1,
      ),
    );

    expect(
      exactOnly,
      contains(
        'Visible content changes the supplied meaning of numeric claim(s) '
        '38. Preserve each claim\'s original unit, comparison, and subject.',
      ),
    );
    expect(
      explicitlyOpenEnded.where(
        (error) => error.contains('changes the supplied meaning'),
      ),
      isEmpty,
    );
  });

  test('rejects a metric detached from its experimental context', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content': '## 19% more final decisions',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'A controlled experiment produced 19% faster decisions.',
        slideCount: 1,
      ),
    );

    expect(
      errors,
      contains(
        'Visible content changes the supplied meaning of numeric claim(s) '
        '19%. Preserve each claim\'s original unit, comparison, and subject.',
      ),
    );
  });

  test('does not treat one collaborative inbox as a metric claim', () {
    final errors = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## One collaborative inbox\n\nA shared evidence workspace for '
            'product teams.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent:
            'Turn fragmented evidence into one evidence workspace for product '
            'teams.',
        slideCount: 1,
      ),
    );

    expect(
      errors.where((error) => error.contains('numeric claim(s) 1')),
      isEmpty,
    );
  });

  test('requires unsupported capability claims to remain hypothetical', () {
    final unqualified = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## Enterprise controls\n\nSSO, data residency, and automated '
            'workflows.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Explore possible enterprise governance directions.',
        slideCount: 1,
      ),
    );
    final qualified = validateGeneratedSlide(
      expectedKey: 'test-slide',
      rawSlide: _slideWithBlock({
        'type': 'block',
        'content':
            '## Illustrative option\n\nProposed SSO, data residency, and '
            'automated workflows.',
      }),
      planSlide: _planSlide(composition: 'content'),
      elementCatalog: GenerationElementCatalog.builtIn(),
      request: const DeckGenerationRequest(
        userIntent: 'Explore possible enterprise governance directions.',
        slideCount: 1,
      ),
    );

    final unsupportedError = unqualified.singleWhere(
      (error) => error.contains('unsupported commitment claim(s)'),
    );
    expect(unsupportedError, contains('sso'));
    expect(unsupportedError, contains('data residency'));
    expect(unsupportedError, contains('automated workflows'));
    expect(
      qualified.where(
        (error) => error.contains('unsupported commitment claim(s)'),
      ),
      isEmpty,
    );
  });

  test(
    'rejects unqualified implementation details and invented pricing tiers',
    () {
      final rejected = validateGeneratedSlide(
        expectedKey: 'test-slide',
        rawSlide: _slideWithBlock({
          'type': 'block',
          'content':
              '## Adoption\n\n'
              '* Auto-collects support tags through a REST API\n'
              '* Live-updating evidence with direct authentication\n'
              '* Free: Core inbox and triage\n'
              '* Pro: Advanced linked insights\n'
              '* Exclusive launch event access',
        }),
        planSlide: _planSlide(composition: 'content'),
        elementCatalog: GenerationElementCatalog.builtIn(),
        request: const DeckGenerationRequest(
          userIntent:
              'Cover API extensibility, onboarding, pricing shape, and roadmap '
              'for a fictional beta product.',
          slideCount: 1,
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

      final qualified = validateGeneratedSlide(
        expectedKey: 'test-slide',
        rawSlide: _slideWithBlock({
          'type': 'block',
          'content':
              '## Illustrative adoption options\n\n'
              '* Proposed option: auto-collect tags through a REST API\n'
              '* Illustrative option: live-updating evidence with direct auth\n'
              '* Proposed tier — Free: Core inbox and triage\n'
              '* Proposed tier — Pro: Advanced linked insights',
        }),
        planSlide: _planSlide(composition: 'content'),
        elementCatalog: GenerationElementCatalog.builtIn(),
        request: const DeckGenerationRequest(
          userIntent:
              'Cover API extensibility, onboarding, pricing shape, and roadmap '
              'for a fictional beta product.',
          slideCount: 1,
        ),
      );
      expect(
        qualified.where(
          (candidate) => candidate.contains('unsupported commitment claim(s)'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'preserves the supplied qrcode destination identity in visible copy',
    () {
      Map<String, dynamic> qrcodeSlide(String content) => {
        'key': 'test-slide',
        'options': {'title': 'Continue', 'style': 'closing'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': content},
              {
                'type': 'widget',
                'name': 'qrcode',
                'args': {'text': 'https://superdeck-dev.web.app'},
              },
            ],
          },
        ],
      };

      final plan = _planSlide(
        composition: 'qrcode',
        treatment: 'closing',
        elements: const [
          {
            'type': 'qrcode',
            'source': 'https://superdeck-dev.web.app',
            'purpose': 'Let the audience open the live SuperDeck experience',
          },
        ],
      );
      final rejected = validateGeneratedSlide(
        expectedKey: 'test-slide',
        rawSlide: qrcodeSlide(
          '## Continue\n\nScan to explore the live Signal Canvas experience.',
        ),
        planSlide: plan,
        elementCatalog: GenerationElementCatalog.builtIn(),
      );
      final preserved = validateGeneratedSlide(
        expectedKey: 'test-slide',
        rawSlide: qrcodeSlide(
          '## Continue\n\nScan to open the live SuperDeck experience.',
        ),
        planSlide: plan,
        elementCatalog: GenerationElementCatalog.builtIn(),
      );

      expect(
        rejected,
        contains(
          'Visible qrcode handoff omits grounded purpose term(s): superdeck. '
          'Preserve the supplied destination or experience identity.',
        ),
      );
      expect(
        preserved.where((candidate) => candidate.contains('handoff omits')),
        isEmpty,
      );
    },
  );
}

Map<String, dynamic> _slideWithBlock(Map<String, Object?> block) => {
  'key': 'test-slide',
  'options': {'title': 'Test'},
  'sections': [
    {
      'type': 'section',
      'blocks': [block],
    },
  ],
};

DeckPlanSlideType _planSlide({
  required String composition,
  String density = 'balanced',
  String? treatment,
  List<Map<String, Object?>> elements = const [],
}) => DeckPlanSlideType.parse({
  'key': 'test-slide',
  'title': 'Test slide',
  'purpose': 'Exercise the generated slide contract.',
  'sectionKey': 'main',
  'assertion': 'The planned assertion must be visible.',
  'contentUnits': ['One concrete supporting point'],
  'narrativeRole': composition == 'title' ? 'opening' : 'insight',
  'contentBrief': 'Include enough concrete content to fulfill the composition.',
  'continuity': 'Connect the previous and next ideas.',
  'composition': composition,
  'treatment':
      treatment ??
      switch (composition) {
        'title' => 'hero',
        'table' || 'metric' => 'data',
        'webview' ||
        'imageLeft' ||
        'imageRight' ||
        'imageFullBleed' => 'visual',
        _ => 'content',
      },
  'density': density,
  'elements': elements,
});
