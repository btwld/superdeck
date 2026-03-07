import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  group('SlideTemplate', () {
    group('construction', () {
      test('default constructor produces expected field values', () {
        const template = SlideTemplate();

        expect(template.frame, isA<SlideFrame>());
        expect(template.baseStyle, isNull);
        expect(template.styles, isEmpty);
      });

      test('all-parameter constructor stores supplied values', () {
        final frame = SlideFrame();
        final baseStyle = SlideStyle();
        final variants = <String, SlideStyle>{'dark': SlideStyle()};

        final template = SlideTemplate(
          frame: frame,
          baseStyle: baseStyle,
          styles: variants,
        );

        expect(template.frame, same(frame));
        expect(template.baseStyle, same(baseStyle));
        expect(template.styles, equals(variants));
      });
    });

    group('copyWith', () {
      test('copies frame field when supplied', () {
        const original = SlideTemplate();
        final newFrame = SlideFrame();

        final copy = original.copyWith(frame: newFrame);

        expect(copy.frame, same(newFrame));
        expect(copy.baseStyle, isNull);
        expect(copy.styles, isEmpty);
      });

      test('copies baseStyle field when supplied', () {
        const original = SlideTemplate();
        final newStyle = SlideStyle();

        final copy = original.copyWith(baseStyle: newStyle);

        expect(copy.baseStyle, same(newStyle));
        expect(copy.frame, isA<SlideFrame>());
        expect(copy.styles, isEmpty);
      });

      test('copies styles field when supplied', () {
        const original = SlideTemplate();
        final newStyles = <String, SlideStyle>{'light': SlideStyle()};

        final copy = original.copyWith(styles: newStyles);

        expect(copy.styles, equals(newStyles));
        expect(copy.baseStyle, isNull);
      });

      test('preserves frame when not specified', () {
        final frame = SlideFrame();
        final original = SlideTemplate(frame: frame);

        final copy = original.copyWith(baseStyle: SlideStyle());

        expect(copy.frame, same(frame));
      });

      test('preserves baseStyle when not specified', () {
        final baseStyle = SlideStyle();
        final original = SlideTemplate(baseStyle: baseStyle);

        final copy = original.copyWith(styles: {'x': SlideStyle()});

        expect(copy.baseStyle, same(baseStyle));
      });

      test('preserves styles when not specified', () {
        final styles = <String, SlideStyle>{'a': SlideStyle()};
        final original = SlideTemplate(styles: styles);

        final copy = original.copyWith(baseStyle: SlideStyle());

        expect(copy.styles, same(styles));
      });
    });

    group('equality', () {
      test('two templates with the same shared frame instance are equal', () {
        final frame = SlideFrame();
        final a = SlideTemplate(frame: frame);
        final b = SlideTemplate(frame: frame);

        expect(a, equals(b));
      });

      test('identical template is equal to itself', () {
        const template = SlideTemplate();

        expect(template, equals(template));
      });

      test('templates with different frame instances are not equal', () {
        // SlideFrame does not override ==, so distinct instances differ.
        final a = SlideTemplate(frame: SlideFrame());
        final b = SlideTemplate(frame: SlideFrame());

        expect(a, isNot(equals(b)));
      });

      test('templates with different baseStyles are not equal', () {
        final frame = SlideFrame();
        final a = SlideTemplate(frame: frame, baseStyle: SlideStyle());
        final b = SlideTemplate(frame: frame);

        expect(a, isNot(equals(b)));
      });

      test('templates with equal baseStyles are equal', () {
        // SlideStyle uses Equatable, so two instances with same args are equal.
        final frame = SlideFrame();
        final a = SlideTemplate(frame: frame, baseStyle: SlideStyle());
        final b = SlideTemplate(frame: frame, baseStyle: SlideStyle());

        expect(a, equals(b));
      });

      test('templates with different styles maps are not equal', () {
        final frame = SlideFrame();
        final a = SlideTemplate(frame: frame, styles: {'dark': SlideStyle()});
        final b = SlideTemplate(frame: frame, styles: {});

        expect(a, isNot(equals(b)));
      });

      test('templates with equivalent styles maps are equal', () {
        final frame = SlideFrame();
        final a = SlideTemplate(frame: frame, styles: {'dark': SlideStyle()});
        final b = SlideTemplate(frame: frame, styles: {'dark': SlideStyle()});

        expect(a, equals(b));
      });
    });

    group('hashCode', () {
      test('equal templates have the same hashCode', () {
        final frame = SlideFrame();
        final baseStyle = SlideStyle();
        final styles = <String, SlideStyle>{'x': SlideStyle()};

        final a = SlideTemplate(
          frame: frame,
          baseStyle: baseStyle,
          styles: styles,
        );
        final b = SlideTemplate(
          frame: frame,
          baseStyle: baseStyle,
          styles: styles,
        );

        expect(a.hashCode, equals(b.hashCode));
      });

      test('hashCode is consistent across multiple calls on same instance', () {
        const template = SlideTemplate();

        expect(template.hashCode, equals(template.hashCode));
      });

      test('templates that differ in frame have different hashCodes', () {
        // Different SlideFrame instances have different identity-based hashCodes.
        final a = SlideTemplate(frame: SlideFrame());
        final b = SlideTemplate(frame: SlideFrame());

        // Distinct SlideFrame instances will produce distinct hash values
        // in virtually all cases because Object.hashCode is identity-based.
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });
  });
}
