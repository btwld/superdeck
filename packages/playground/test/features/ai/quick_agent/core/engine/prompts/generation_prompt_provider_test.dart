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
    expect(prompt, contains('`image`: A supplied image asset, file, or URL.'));
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
