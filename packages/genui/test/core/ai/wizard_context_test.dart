import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_genui/src/ai/schemas/wizard_context_keys.dart';
import 'package:superdeck_genui/src/ai/wizard_context.dart';

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

  group('WizardContext mapping', () {
    test('toMap omits null fields and preserves populated values', () {
      const context = WizardContext(
        topic: 'Launch plan',
        slideCount: 12,
        colors: ['#111111', '#eeeeee'],
      );

      expect(context.toMap(), {
        WizardContextKeys.topic: 'Launch plan',
        WizardContextKeys.slideCount: 12,
        WizardContextKeys.colors: ['#111111', '#eeeeee'],
      });
    });

    test('fromMap normalizes values before materializing the model', () {
      final context = WizardContext.fromMap({
        WizardContextKeys.topic: '  Demo  ',
        WizardContextKeys.slideCount: '8',
        WizardContextKeys.emphasis: 'clarity',
      });

      expect(context.topic, 'Demo');
      expect(context.slideCount, 8);
      expect(context.emphasis, ['clarity']);
    });
  });
}
