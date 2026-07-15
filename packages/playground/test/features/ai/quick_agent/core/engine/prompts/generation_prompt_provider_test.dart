import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/prompts/generation_prompt_provider.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_element_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_validation_issue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'outline prompt exposes only compact eligible theme candidates',
    () async {
      final catalog = PresentationThemeCatalog.withDefaults();
      final provider = AssetGenerationPromptProvider();
      await provider.load();

      final prompt = provider.buildOutlinePrompt(
        themeCandidates: catalog.shortlist(
          const PresentationThemeSelectionCriteria(
            userIntent: 'Create a clear presentation.',
          ),
        ),
      );

      expect(prompt, contains('editorial-midnight'));
      expect(prompt, contains('technical-paper'));
      expect(prompt, contains('bold-product'));
      expect(prompt, contains('Dark cinematic editorial system'));
      expect(prompt, isNot(contains('#0D1626')));
      expect(prompt, isNot(contains('Playfair Display')));
      expect(prompt, isNot(contains('Open Sans')));
      expect(prompt, isNot(contains('accentContrast')));
    },
  );

  test('uses a dedicated compact outline repair prompt', () async {
    final catalog = PresentationThemeCatalog.withDefaults();
    final provider = AssetGenerationPromptProvider();
    await provider.load();
    final candidates = catalog.shortlist(
      const PresentationThemeSelectionCriteria(
        userIntent: 'Create a clear presentation.',
      ),
    );
    final invalidPlan = <String, Object?>{
      'topic': 'Reliable systems',
      'story': 'Move from uncertainty to a reliable operating rhythm.',
      'theme': {'id': 'technical-paper'},
      'slides': [_planSlide('opening', 'Frame the problem')],
    };

    final prompt = provider.buildOutlinePrompt(
      themeCandidates: candidates,
      validationIssues: const [
        GenerationValidationIssue(
          code: GenerationValidationCode.slideCount,
          category: GenerationValidationCategory.structure,
          severity: GenerationValidationSeverity.blocking,
          location: GenerationValidationLocation.deck,
          message: 'Deck plan has 1 slides; expected exactly 2.',
        ),
      ],
      invalidPlan: invalidPlan,
    );
    final encodedPlan = const JsonEncoder.withIndent(' ').convert(invalidPlan);

    expect(prompt, startsWith('You repair one SuperDeck deck plan.'));
    expect(prompt, contains('Deck plan has 1 slides; expected exactly 2.'));
    expect(prompt, contains(encodedPlan));
    expect(prompt, contains('technical-paper'));
    expect(prompt, isNot(contains('Dark cinematic editorial system')));
    expect(prompt.length - encodedPlan.length, lessThanOrEqualTo(4000));
  });

  test('assembles bounded single-slide context deterministically', () {
    final plan = DeckPlanType.parse({
      'topic': 'Reliable systems',
      'story': 'Move from uncertainty to a reliable operating rhythm.',
      'theme': _themeReference,
      'sections': [
        {
          'key': 'main',
          'title': 'Main story',
          'purpose': 'Advance the narrative.',
          'transition': 'Carry the story to the close.',
          'slideKeys': ['opening', 'evidence', 'closing'],
        },
      ],
      'slides': [
        _planSlide('opening', 'Frame the problem'),
        _planSlide('evidence', 'Show the proof'),
        _planSlide('closing', 'Make the ask'),
      ],
    });
    final previous = <String, Object?>{
      'key': 'opening',
      'options': {'title': 'Reliability starts here', 'style': 'hero'},
      'comments': ['Private speaker note that should not be repeated.'],
      'sections': [
        {
          'type': 'section',
          'blocks': [
            {'type': 'block', 'content': '# Reliability starts here'},
          ],
        },
      ],
    };

    final prompt = buildSingleSlidePrompt(
      basePrompt: 'BASE',
      fieldGuidance: 'GUIDANCE',
      plan: plan,
      current: plan.slides[1],
      previousSlide: previous,
      next: plan.slides[2],
      elementCatalog: GenerationElementCatalog.builtIn(),
      compositionExample: const {
        'key': 'evidence',
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {'type': 'block', 'content': '## One evidence pattern'},
            ],
          },
        ],
      },
      validationIssues: const [
        GenerationValidationIssue(
          code: GenerationValidationCode.slideIdentity,
          category: GenerationValidationCategory.structure,
          severity: GenerationValidationSeverity.blocking,
          location: GenerationValidationLocation.visibleContent,
          slideKey: 'evidence',
          message: 'Slide key must be exactly "evidence".',
        ),
      ],
      invalidSlide: const {
        'key': 'wrong-key',
        'options': {'title': 'Keep this title', 'style': 'content'},
      },
    );

    expect(prompt, startsWith('BASE\n\nGUIDANCE\n'));
    expect(prompt, contains('The slide key must be exactly `evidence`.'));
    expect(prompt, contains('"key": "opening"'));
    expect(prompt, contains('"key": "closing"'));
    expect(prompt, contains('None planned for this slide.'));
    expect(
      prompt,
      isNot(contains('`image`: A supplied image asset, file, or URL.')),
    );
    expect(
      prompt,
      isNot(contains('Private speaker note that should not be repeated.')),
    );
    expect(prompt, contains('# Reliability starts here'));
    expect(prompt, contains('## Current narrative section'));
    expect(prompt, contains('## Recent design ledger'));
    expect(prompt, contains('"key": "opening"'));
    expect(prompt, contains('## Relevant composition example'));
    expect(prompt, contains('One evidence pattern'));
    expect(prompt, contains('## Current and prior validation constraints'));
    expect(prompt, contains('## Invalid slide draft to repair'));
    expect(prompt, contains('"key": "wrong-key"'));
    expect(prompt, contains('every other valid planned field'));
    expect(prompt, contains('- Slide key must be exactly "evidence".'));
    expect(prompt, contains('no more than 70 visible words'));
    expect(prompt, contains('a list of at most three short bullets'));
    expect(prompt, endsWith('generate future slides.\n'));
  });

  test(
    'repairs metric identity from original grounded facts, not plan labels',
    () {
      final plan = DeckPlanType.parse({
        'topic': 'Planning',
        'story': 'Replace roadmap theater with continuous planning.',
        'theme': _themeReference,
        'sections': [
          {
            'key': 'main',
            'title': 'Main story',
            'purpose': 'Advance the narrative.',
            'transition': 'Move to the operating model.',
            'slideKeys': ['roadmap-trap'],
          },
        ],
        'slides': [
          {
            ..._planSlide('roadmap-trap', 'The roadmap trap'),
            'contentUnits': ['Twelve-month roadmap constraints'],
          },
        ],
      });

      final prompt = buildSingleSlidePrompt(
        basePrompt: 'BASE',
        fieldGuidance: 'GUIDANCE',
        plan: plan,
        current: plan.slides.single,
        previousSlide: null,
        next: null,
        elementCatalog: GenerationElementCatalog.builtIn(),
        compositionExample: const {},
        validationIssues: const [
          GenerationValidationIssue(
            code: GenerationValidationCode.numericMeaning,
            category: GenerationValidationCategory.factual,
            severity: GenerationValidationSeverity.blocking,
            location: GenerationValidationLocation.visibleContent,
            message: 'Metric meaning needs repair.',
          ),
          GenerationValidationIssue(
            code: GenerationValidationCode.numericMeaning,
            category: GenerationValidationCategory.factual,
            severity: GenerationValidationSeverity.blocking,
            location: GenerationValidationLocation.speakerComments,
            message: 'Comment metric needs repair.',
          ),
        ],
        invalidSlide: const {'key': 'roadmap-trap'},
      );

      expect(
        prompt,
        contains('original user request\'s `groundedNumericFacts`'),
      );
      expect(prompt, contains('not a shortened plan field'));
      expect(prompt, contains('Delete any second shorthand occurrence'));
      expect(prompt, contains('delete the comment'));
    },
  );

  test(
    'surfaces exact grounded and hypothetical numeric copy contracts',
    () async {
      final provider = AssetGenerationPromptProvider();
      await provider.load();
      final plan = DeckPlanType.parse({
        'topic': 'Adoption',
        'story': 'Move from output to adoption.',
        'theme': _themeReference,
        'sections': [
          {
            'key': 'main',
            'title': 'Main story',
            'purpose': 'Advance the narrative.',
            'transition': 'Move to the decision.',
            'slideKeys': ['evidence'],
          },
        ],
        'slides': [
          {
            ..._planSlide('evidence', 'Adoption evidence'),
            'contentUnits': [
              'Only 31% of shipped features reach their adoption target.',
              'Planned target: 60% adoption after the proposed pilot.',
            ],
          },
        ],
      });

      final prompt = provider.buildSlidePrompt(
        plan: plan,
        current: plan.slides.single,
        previousSlide: null,
        next: null,
        elementCatalog: GenerationElementCatalog.builtIn(),
      );

      expect(prompt, contains('## Numeric copy contract'));
      expect(
        prompt,
        contains('Only 31% of shipped features reach their adoption target.'),
      );
      expect(
        prompt,
        contains('Planned target: 60% adoption after the proposed pilot.'),
      );
      expect(prompt, contains('copy the complete unit verbatim'));
      expect(prompt, contains('preserve its explicit hypothetical label'));
    },
  );

  test('builds one compact ordered prompt for a narrative section', () async {
    final provider = AssetGenerationPromptProvider();
    await provider.load();
    final plan = DeckPlanType.parse({
      'topic': 'Adoption',
      'story': 'Move from evidence to a practical decision.',
      'theme': _themeReference,
      'sections': [
        {
          'key': 'evidence-act',
          'title': 'Evidence',
          'purpose': 'Establish the adoption gap.',
          'transition': 'Turn evidence into action.',
          'slideKeys': ['signal', 'target'],
        },
      ],
      'slides': [
        {
          ..._planSlide('signal', 'Show the grounded signal'),
          'sectionKey': 'evidence-act',
          'contentUnits': [
            'Only 31% of shipped features reach their adoption target.',
          ],
        },
        {
          ..._planSlide('target', 'Set the proposed direction'),
          'sectionKey': 'evidence-act',
          'contentUnits': [
            'Planned target: 60% adoption after the proposed pilot.',
          ],
        },
      ],
    });

    final prompt = provider.buildSectionPrompt(
      plan: plan,
      section: plan.sections.single,
      slides: plan.slides,
      previous: null,
      next: null,
      elementCatalog: GenerationElementCatalog.builtIn(),
    );

    expect(prompt, contains('Return one `slides` array'));
    expect(
      prompt.indexOf('"key": "signal"'),
      lessThan(prompt.indexOf('"key": "target"')),
    );
    expect(
      prompt,
      contains('Only 31% of shipped features reach their adoption target.'),
    );
    expect(
      prompt,
      contains('Planned target: 60% adoption after the proposed pilot.'),
    );
    expect(prompt, contains('copy each complete unit verbatim'));
    expect(prompt, contains('## Canonical shape examples'));
    expect(prompt, contains('"key": "example-content"'));
    expect(RegExp('"key": "example-content"').allMatches(prompt), hasLength(1));
    expect(prompt, isNot(contains('"key": "example-table"')));
    expect(prompt, contains('No elements are planned in this section.'));
    expect(prompt, isNot(contains('`image`: A supplied image asset')));
  });

  test(
    'keeps initial context bounded and repairs smaller than generation',
    () async {
      final catalog = PresentationThemeCatalog.withDefaults();
      final provider = AssetGenerationPromptProvider();
      await provider.load();
      final plan = DeckPlanType.parse({
        'topic': 'Reliable systems',
        'story': 'Move from uncertainty to a reliable operating rhythm.',
        'theme': _themeReference,
        'sections': [
          {
            'key': 'main',
            'title': 'Main story',
            'purpose': 'Advance the narrative.',
            'transition': 'Carry the story to the close.',
            'slideKeys': ['opening', 'evidence', 'closing'],
          },
        ],
        'slides': [
          _planSlide('opening', 'Frame the problem'),
          _planSlide('evidence', 'Show the proof'),
          _planSlide('closing', 'Make the ask'),
        ],
      });
      final outlinePrompt = provider.buildOutlinePrompt(
        themeCandidates: catalog.shortlist(
          const PresentationThemeSelectionCriteria(
            userIntent: 'Create a clear presentation.',
          ),
        ),
      );
      final initialSlidePrompt = provider.buildSlidePrompt(
        plan: plan,
        current: plan.slides[1],
        previousSlide: const {
          'key': 'opening',
          'sections': [
            {
              'type': 'section',
              'blocks': [
                {'type': 'block', 'content': '# Reliability starts here'},
              ],
            },
          ],
        },
        next: plan.slides[2],
        elementCatalog: GenerationElementCatalog.builtIn(),
      );
      final repairPrompt = provider.buildSlidePrompt(
        plan: plan,
        current: plan.slides[1],
        previousSlide: const {
          'key': 'opening',
          'sections': [
            {
              'type': 'section',
              'blocks': [
                {'type': 'block', 'content': '# Reliability starts here'},
              ],
            },
          ],
        },
        next: plan.slides[2],
        elementCatalog: GenerationElementCatalog.builtIn(),
        validationIssues: const [
          GenerationValidationIssue(
            code: GenerationValidationCode.contentDensity,
            category: GenerationValidationCategory.quality,
            severity: GenerationValidationSeverity.blocking,
            location: GenerationValidationLocation.visibleContent,
            slideKey: 'evidence',
            message: 'Slide exceeds the balanced content budget.',
          ),
        ],
        invalidSlide: const {
          'key': 'evidence',
          'sections': [
            {
              'type': 'section',
              'blocks': [
                {'type': 'block', 'content': '## Too much copy'},
              ],
            },
          ],
        },
      );

      expect(outlinePrompt.length, lessThanOrEqualTo(10000));
      expect(initialSlidePrompt.length, lessThanOrEqualTo(11000));
      expect(repairPrompt.length, lessThan(initialSlidePrompt.length));
    },
  );
}

const _themeReference = <String, Object?>{
  'id': 'editorial-midnight',
  'version': 1,
  'density': 'balanced',
};

Map<String, Object?> _planSlide(String key, String title) => {
  'key': key,
  'title': title,
  'purpose': 'Advance the narrative.',
  'sectionKey': 'main',
  'assertion': 'A concrete assertion for $key.',
  'contentUnits': ['One concrete idea'],
  'narrativeRole': key == 'opening'
      ? 'opening'
      : key == 'closing'
      ? 'closing'
      : 'evidence',
  'contentBrief': 'Use one concrete idea.',
  'continuity': 'Connect to the surrounding slide.',
  'composition': 'content',
  'treatment': key == 'opening'
      ? 'hero'
      : key == 'closing'
      ? 'closing'
      : 'content',
  'density': 'balanced',
  'elements': <Object?>[],
};
