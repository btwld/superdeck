import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/wizard/core/ai/services/prompt_builder.dart';
import 'package:playground/features/ai/wizard/core/ai/wizard_context.dart';

void main() {
  test('serializes exact generation constraints as structured model input', () {
    const request = DeckGenerationRequest(
      userIntent: 'Explain the reliability operating model.',
      slideCount: 14,
      audience: 'Engineering leaders',
      approach: 'Decision-oriented narrative',
      emphasis: ['evidence', 'first 30 days'],
      themeId: 'editorial-midnight',
      designDirection: 'Editorial',
      density: 'spacious',
      colors: ['#101828', '#F9FAFB', '#D0D5DD'],
      headlineFont: 'Fraunces',
      bodyFont: 'Inter',
      imageStyleId: 'minimalist',
      imageStyleVersion: 1,
      groundedElements: [
        GroundedGenerationElement(
          type: 'image',
          source: 'assets/reliability-team.jpg',
          purpose: 'Show the team operating together',
        ),
      ],
    );

    final input = request.toModelInput();
    final payload = jsonDecode(input) as Map<String, Object?>;

    expect(payload['slideCount'], 14);
    expect(payload['themeId'], 'editorial-midnight');
    expect(payload['density'], 'spacious');
    expect(payload['headlineFont'], 'Fraunces');
    expect(payload['bodyFont'], 'Inter');
    expect(payload['imageStyleId'], 'minimalist');
    expect(payload['imageStyleVersion'], 1);
    expect(payload['colors'], ['#101828', '#F9FAFB', '#D0D5DD']);
    expect(
      payload['groundedElements'],
      contains(containsPair('source', 'assets/reliability-team.jpg')),
    );

    final replayed = DeckGenerationRequest.fromMap(payload);
    expect(replayed.toMap(), payload);
  });

  test('wizard creates the typed request without legacy layout conflicts', () {
    const context = WizardContext(
      topic: 'A reliable release system',
      audience: 'Product and engineering leaders',
      approach: 'Persuasive',
      emphasis: ['metrics', 'operating model'],
      slideCount: 12,
      themeId: 'bold-product',
      style: 'Bold editorial',
      colors: ['#101828', '#F9FAFB', '#D0D5DD'],
      headlineFont: 'Playfair Display',
      bodyFont: 'Inter',
      imageStyleId: 'watercolor',
      imageStyleVersion: 1,
    );

    final request = buildPromptFromWizardContext(context);
    final input = request.toModelInput();

    expect(request.slideCount, 12);
    expect(request.themeId, 'bold-product');
    expect(request.headlineFont, 'Playfair Display');
    expect(request.bodyFont, 'Inter');
    expect(request.imageStyleId, 'watercolor');
    expect(request.imageStyleVersion, 1);
    expect(input, isNot(contains('Do not use widget blocks')));
    expect(input, isNot(contains('two sections (title + body) for most')));
  });

  test('surfaces immutable numeric fact snippets to the model', () {
    const request = DeckGenerationRequest(
      userIntent:
          'The beta connected 38 sources. Teams spent 42% less weekly '
          'synthesis time. No change was required to source systems.',
      slideCount: 3,
    );

    final payload = jsonDecode(request.toModelInput()) as Map<String, Object?>;

    expect(payload['groundedNumericFacts'], [
      'The beta connected 38 sources.',
      'Teams spent 42% less weekly synthesis time.',
      'No change was required to source systems.',
    ]);
  });

  test('preserves wrapped facts and omits narrative structure counts', () {
    const request = DeckGenerationRequest(
      userIntent:
          'Turn evidence into one workspace. Tell the story across four acts.\n'
          'Use these beta facts: six design partners, 38 connected sources,\n'
          '42% less weekly synthesis time, 19% faster decisions, and no change\n'
          'to source-of-truth systems.',
      slideCount: 20,
    );

    final payload = jsonDecode(request.toModelInput()) as Map<String, Object?>;

    expect(payload['groundedNumericFacts'], [
      'Use these beta facts: six design partners, 38 connected sources, '
          '42% less weekly synthesis time, 19% faster decisions, and no change '
          'to source-of-truth systems.',
    ]);
  });

  test('keeps decimal and currency facts in their source sentence', () {
    const request = DeckGenerationRequest(
      userIntent:
          'The business serves 4.8 million members on \$3.2 billion annual '
          'revenue. Digital conversion is 2.1% with a target of 3.4% within '
          '18 months.',
      slideCount: 2,
    );

    final payload = jsonDecode(request.toModelInput()) as Map<String, Object?>;

    expect(payload['groundedNumericFacts'], [
      'The business serves 4.8 million members on \$3.2 billion annual revenue.',
      'Digital conversion is 2.1% with a target of 3.4% within 18 months.',
    ]);
  });
}
