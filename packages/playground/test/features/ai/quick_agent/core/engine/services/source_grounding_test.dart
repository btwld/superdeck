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

  test('rejects rounded values that were not supplied', () {
    final unsupported = findUnsupportedNumericClaims(
      values: const ['4 million loyalty members and 3% conversion'],
      groundedClaims: extractGroundedNumericClaims([businessCase]),
    );

    expect(unsupported, {'4', '3%'});
  });
}
