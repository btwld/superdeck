import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  group('DeckOptions', () {
    group('equality', () {
      test('two instances with same-content maps are equal', () {
        final style = SlideStyler();
        final a = DeckOptions(
          styles: {'s': style},
          widgets: {},
          templates: {'t': const SlideTemplate()},
        );
        final b = DeckOptions(
          styles: {'s': style},
          widgets: {},
          templates: {'t': const SlideTemplate()},
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('unmodifiable collections', () {
      test(
        'modifying original map after construction does not affect stored map',
        () {
          final styles = <String, SlideStyler>{'a': SlideStyler()};
          final options = DeckOptions(styles: styles);

          styles['b'] = SlideStyler();

          expect(options.styles.length, 1);
          expect(options.styles.containsKey('b'), isFalse);
        },
      );

      test('mutation attempt on styles throws UnsupportedError', () {
        final options = DeckOptions(styles: {'a': SlideStyler()});

        expect(
          () => options.styles['b'] = SlideStyler(),
          throwsUnsupportedError,
        );
      });

      test('mutation attempt on widgets throws UnsupportedError', () {
        final options = DeckOptions();

        expect(
          () => options.widgets['x'] = (_) => const SizedBox(),
          throwsUnsupportedError,
        );
      });

      test('mutation attempt on templates throws UnsupportedError', () {
        final options = DeckOptions();

        expect(
          () => options.templates['x'] = const SlideTemplate(),
          throwsUnsupportedError,
        );
      });
    });

    group('copyWith sentinel', () {
      test('copyWith() with no args preserves existing baseStyle', () {
        final style = SlideStyler();
        final options = DeckOptions(baseStyle: style);
        final copy = options.copyWith();

        expect(copy.baseStyle, same(style));
      });

      test('copyWith(baseStyle: null) clears a previously set baseStyle', () {
        final style = SlideStyler();
        final options = DeckOptions(baseStyle: style);
        final copy = options.copyWith(baseStyle: null);

        expect(copy.baseStyle, isNull);
      });

      test('copyWith() with no args preserves existing defaultTemplate', () {
        const template = SlideTemplate();
        final options = DeckOptions(defaultTemplate: template);
        final copy = options.copyWith();

        expect(copy.defaultTemplate, same(template));
      });

      test(
        'copyWith(defaultTemplate: null) clears the current defaultTemplate',
        () {
          const template = SlideTemplate();
          final options = DeckOptions(defaultTemplate: template);
          final copy = options.copyWith(defaultTemplate: null);

          expect(copy.defaultTemplate, isNull);
        },
      );
    });
  });
}
