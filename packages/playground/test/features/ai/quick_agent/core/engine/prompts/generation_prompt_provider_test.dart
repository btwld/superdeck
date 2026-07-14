import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/prompts/generation_prompt_provider.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_element_catalog.dart';

void main() {
  test('assembles bounded single-slide context deterministically', () {
    final plan = DeckPlanType.parse({
      'topic': 'Reliable systems',
      'story': 'Move from uncertainty to a reliable operating rhythm.',
      'style': {
        'name': 'midnight',
        'direction': 'editorial',
        'density': 'balanced',
        'typeScale': 'dramatic',
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
      },
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
      validationErrors: const ['Slide key must be exactly "evidence".'],
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
        'style': {
          'name': 'midnight',
          'direction': 'editorial',
          'density': 'balanced',
          'typeScale': 'dramatic',
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
        },
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
        validationErrors: const [
          'Visible content changes the supplied meaning of numeric claim(s) 12.',
          'Speaker comments change the supplied meaning of numeric claim(s) 12.',
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
