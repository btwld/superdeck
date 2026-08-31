import 'package:ack/ack.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_checkbox.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_radio.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_slider.dart';

const _action = <String, Object?>{
  'name': 'submit_answer',
  'context': <Object?>[],
};

void main() {
  group('AskUserRadio schema', () {
    test('accepts one option', () {
      final model = AskUserRadio.parse({
        'question': 'Choose one',
        'options': [
          {'title': 'Only choice'},
        ],
        'action': _action,
      });

      expect(model.options, hasLength(1));
    });

    test('rejects an empty options list', () {
      expect(
        () => AskUserRadio.parse({
          'question': 'Choose one',
          'options': <Object?>[],
          'action': _action,
        }),
        throwsA(isA<AckException>()),
      );
    });
  });

  group('AskUserCheckbox schema', () {
    test('accepts zero bounds and an empty initial selection', () {
      final model = AskUserCheckbox.parse(
        _checkboxData(
          items: ['One'],
          selectedItems: const [],
          minSelections: 0,
          maxSelections: 0,
        ),
      );

      expect(model.minSelections, 0);
      expect(model.maxSelections, 0);
      expect(model.selectedItems, isEmpty);
    });

    test('accepts bounds equal to the item count', () {
      final model = AskUserCheckbox.parse(
        _checkboxData(
          items: ['One', 'Two'],
          selectedItems: const ['One', 'Two'],
          minSelections: 2,
          maxSelections: 2,
        ),
      );

      expect(model.selectedItems, ['One', 'Two']);
    });

    test('allows an initial selection below the minimum', () {
      final model = AskUserCheckbox.parse(
        _checkboxData(
          items: ['One', 'Two', 'Three'],
          selectedItems: const ['One'],
          minSelections: 2,
          maxSelections: 3,
        ),
      );

      expect(model.selectedItems, ['One']);
    });

    test('accepts an initial selection at the maximum', () {
      final model = AskUserCheckbox.parse(
        _checkboxData(
          items: ['One', 'Two', 'Three'],
          selectedItems: const ['One', 'Two'],
          maxSelections: 2,
        ),
      );

      expect(model.selectedItems, ['One', 'Two']);
    });

    for (final (description, data) in <(String, Map<String, Object?>)>[
      ('empty items', _checkboxData(items: const [])),
      ('empty item labels', _checkboxData(items: const ['One', ''])),
      ('duplicate items', _checkboxData(items: const ['One', 'One'])),
      (
        'duplicate selected items',
        _checkboxData(
          items: const ['One', 'Two'],
          selectedItems: const ['One', 'One'],
        ),
      ),
      (
        'selected items absent from items',
        _checkboxData(
          items: const ['One', 'Two'],
          selectedItems: const ['Three'],
        ),
      ),
      (
        'negative minimum',
        _checkboxData(items: const ['One'], minSelections: -1),
      ),
      (
        'negative maximum',
        _checkboxData(items: const ['One'], maxSelections: -1),
      ),
      (
        'minimum above the item count',
        _checkboxData(items: const ['One'], minSelections: 2),
      ),
      (
        'maximum above the item count',
        _checkboxData(items: const ['One'], maxSelections: 2),
      ),
      (
        'minimum above the maximum',
        _checkboxData(
          items: const ['One', 'Two'],
          minSelections: 2,
          maxSelections: 1,
        ),
      ),
      (
        'initial selection above the maximum',
        _checkboxData(
          items: const ['One', 'Two'],
          selectedItems: const ['One', 'Two'],
          maxSelections: 1,
        ),
      ),
    ]) {
      test('rejects $description', () {
        expect(() => AskUserCheckbox.parse(data), throwsA(isA<AckException>()));
      });
    }
  });

  group('AskUserSlider schema', () {
    for (final (description, min, max, value) in const [
      ('a default at the lower boundary', 1, 5, 1),
      ('a default at the upper boundary', 1, 5, 5),
      ('equal bounds and matching default', 3, 3, 3),
    ]) {
      test('accepts $description', () {
        final model = AskUserSlider.parse(
          _sliderData(min: min, max: max, value: value),
        );

        expect(model.defaultValue, value);
      });
    }

    for (final (description, min, max, value) in const [
      ('minimum above maximum', 5, 4, 5),
      ('default below minimum', 2, 5, 1),
      ('default above maximum', 2, 5, 6),
    ]) {
      test('rejects $description', () {
        expect(
          () => AskUserSlider.parse(
            _sliderData(min: min, max: max, value: value),
          ),
          throwsA(isA<AckException>()),
        );
      });
    }
  });
}

Map<String, Object?> _checkboxData({
  required List<String> items,
  List<String>? selectedItems,
  int? minSelections,
  int? maxSelections,
}) => {
  'question': 'Choose any',
  'items': items,
  'selectedItems': ?selectedItems,
  'minSelections': ?minSelections,
  'maxSelections': ?maxSelections,
  'action': _action,
};

Map<String, Object?> _sliderData({
  required int min,
  required int max,
  required int value,
}) => {
  'question': 'Choose a number',
  'minValue': min,
  'maxValue': max,
  'defaultValue': value,
  'action': _action,
};
