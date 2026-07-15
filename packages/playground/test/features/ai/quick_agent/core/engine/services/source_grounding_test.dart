import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/source_grounding.dart';

void main() {
  const businessCase =
      'The business serves 220 stores and 4.8 million loyalty members on '
      r'$3.2 billion annual revenue. Digital coupon conversion is 2.1% with a '
      'target of 3.4% within 18 months.';

  test('preserves decimal claims as complete numeric tokens', () {
    expect(extractGroundedNumericClaims([businessCase]), {
      '220',
      '4.8',
      '3.2',
      '2.1%',
      '3.4%',
      '18',
    });
  });

  test('accepts exact decimal facts without fragmented mismatches', () {
    final mismatches = findNumericContextMismatches(
      values: const [
        '4.8 million loyalty members',
        r'$3.2 billion annual revenue',
        '2.1% digital coupon conversion',
        'Target: 3.4% within 18 months',
      ],
      userIntent: businessCase,
    );

    expect(mismatches, isEmpty);
  });

  test('accepts a grounded duration with one editorial anchor paraphrased', () {
    final mismatches = findNumericContextMismatches(
      values: const ['The 90-day operational path'],
      userIntent: 'Build a practical 90-day adoption path.',
    );

    expect(mismatches, isEmpty);
  });

  test('accepts an adoption horizon restated as a transition plan', () {
    final mismatches = findNumericContextMismatches(
      values: const ['Authorize the 90-day transition plan'],
      userIntent: 'Build a practical 90-day adoption path.',
    );

    expect(mismatches, isEmpty);
  });

  test('rejects a grounded duration reused for an unrelated subject', () {
    final mismatches = findNumericContextMismatches(
      values: const ['A 90-day payment window'],
      userIntent: 'Build a practical 90-day adoption path.',
    );

    expect(mismatches, {'90'});
  });

  test('treats pilot and phase counts as structural plan details', () {
    const intent =
        'Use six product teams, roughly 180 engineers, and only 31% of shipped '
        'features reaching their adoption target. Build a practical 90-day '
        'adoption path. Include one useful comparison and an executive close.';
    final mismatches = findNumericContextMismatches(
      values: const [
        'Phase 1: Launch with one pilot product team.',
        'Describe the 90-day rollout, beginning with one pilot team before '
            'transitioning all six product teams and 180 engineers.',
      ],
      userIntent: intent,
      allowSlideContextFallback: true,
    );

    expect(mismatches, isEmpty);
  });

  test('does not reuse a requested comparison count as a pilot fact', () {
    const intent =
        'Create a realistic strategy presentation about replacing quarterly '
        'roadmap theater with a continuous product operating system. The deck '
        'should help senior product and engineering leaders see why annual '
        'commitments become stale, how small outcome teams can work from '
        'evidence, and what changes in planning, funding, discovery, delivery, '
        'and review. Use a credible fictional company with concrete details: '
        'six product teams, roughly 180 engineers, a twelve-month roadmap with '
        '43 promised initiatives, and only 31% of shipped features reaching '
        'their adoption target. Build a clear three-act narrative: the cost '
        'of the old model, the operating-system shift, and a practical 90-day '
        'adoption path. Include a few memorable metrics, one useful comparison, '
        'and an executive close with a specific decision.';
    final mismatches = findNumericContextMismatches(
      values: const [
        'The 90-Day Transition',
        'We will transition our six product teams and 180 engineers in three '
            'managed phases over ninety days.',
        'Phase 1: Launch continuous discovery and outcome metrics with one '
            'pilot product team to build our internal blueprint.',
        'Phase 2: Standardize planning and prepare the remaining teams.',
        'Phase 3: Onboard all six product teams and 180 engineers.',
      ],
      userIntent: intent,
      allowSlideContextFallback: true,
    );

    expect(mismatches, isEmpty);
  });

  test('treats requested comparison and decision counts as structural', () {
    expect(
      extractGroundedNumericClaims([
        'Include one useful comparison and one specific decision.',
      ]),
      isEmpty,
    );
  });

  test('rejects rounded values that were not supplied', () {
    final unsupported = findUnsupportedNumericClaims(
      values: const ['4 million loyalty members and 3% conversion'],
      groundedClaims: extractGroundedNumericClaims([businessCase]),
    );

    expect(unsupported, {'4', '3%'});
  });

  test('ignores ordered-list markers when checking numeric meaning', () {
    final mismatches = findNumericContextMismatches(
      values: const [
        '1. Generate a hypothesis.\n'
            '2. Test it with evidence.\n'
            '3. Decide what changes.',
      ],
      userIntent: 'Describe an evidence loop.',
    );

    expect(mismatches, isEmpty);
  });

  test('does not mistake a hyphenated team adjective for a pricing tier', () {
    final unsupported = findUnsupportedCommitmentPhrases(
      values: const [
        '| Traditional | Continuous |\n'
            '| --- | --- |\n'
            '| Project Funding | Team-based Funding |',
      ],
      userIntent: 'Compare funding models.',
    );

    expect(unsupported, isNot(contains('pricing tier "team"')));
  });

  test('does not mistake roadmap compliance for a compliance claim', () {
    final unsupported = findUnsupportedCommitmentPhrases(
      values: const ['Roadmap compliance can hide weak product adoption.'],
      userIntent: 'Compare roadmap output with product adoption.',
    );

    expect(unsupported, isNot(contains('compliance')));
  });

  test('matches short commitment phrases as tokens, not substrings', () {
    final unsupported = findUnsupportedCommitmentPhrases(
      values: const [
        'A neighborhood association can coordinate shared garden plots.',
      ],
      userIntent: 'Explain community coordination for urban gardens.',
    );

    expect(unsupported, isNot(contains('sso')));
  });

  test('allows ordinary policy language outside product commitment claims', () {
    final unsupported = findUnsupportedCommitmentPhrases(
      values: const [
        'Permanent tree canopy protections and land-use classification can '
            'support long-term neighborhood resilience.',
      ],
      userIntent: 'Create an urban policy presentation.',
    );

    expect(unsupported, isEmpty);
  });
}
