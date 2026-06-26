import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/schemas/wizard_context_keys.dart';
import 'package:playground/features/ai/core/ai/wizard_context.dart';

void main() {
  group('WizardContext.fromMap slideCount parsing', () {
    int? parseSlideCount(Object? raw) {
      final context = WizardContext.fromMap({
        WizardContextKeys.slideCount: raw,
      });
      return context.slideCount;
    }

    test('rejects zero as double', () {
      expect(parseSlideCount(0.0), isNull);
    });

    test('rejects negative double', () {
      expect(parseSlideCount(-3.0), isNull);
    });

    test('truncates and accepts positive double', () {
      expect(parseSlideCount(5.7), 5);
    });

    test('accepts positive int', () {
      expect(parseSlideCount(5), 5);
    });

    test('rejects zero as int', () {
      expect(parseSlideCount(0), isNull);
    });
  });
}
