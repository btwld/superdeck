import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  group('SlideTemplate', () {
    group('construction', () {
      test('default constructor produces expected field values', () {
        const template = SlideTemplate();

        expect(template.parts, isA<SlideParts>());
        expect(template.baseStyle, isNull);
        expect(template.styles, isEmpty);
      });

      test('all-parameter constructor stores supplied values', () {
        final parts = SlideParts();
        final baseStyle = SlideStyler();
        final variants = <String, SlideStyler>{'dark': SlideStyler()};

        final template = SlideTemplate(
          parts: parts,
          baseStyle: baseStyle,
          styles: variants,
        );

        expect(template.parts, same(parts));
        expect(template.baseStyle, same(baseStyle));
        expect(template.styles, equals(variants));
      });
    });

    group('copyWith', () {
      test('copies parts field when supplied', () {
        const original = SlideTemplate();
        final newParts = SlideParts();

        final copy = original.copyWith(parts: newParts);

        expect(copy.parts, same(newParts));
        expect(copy.baseStyle, isNull);
        expect(copy.styles, isEmpty);
      });

      test('copies baseStyle field when supplied', () {
        const original = SlideTemplate();
        final newStyle = SlideStyler();

        final copy = original.copyWith(baseStyle: newStyle);

        expect(copy.baseStyle, same(newStyle));
        expect(copy.parts, isA<SlideParts>());
        expect(copy.styles, isEmpty);
      });

      test('copies styles field when supplied', () {
        const original = SlideTemplate();
        final newStyles = <String, SlideStyler>{'light': SlideStyler()};

        final copy = original.copyWith(styles: newStyles);

        expect(copy.styles, equals(newStyles));
        expect(copy.baseStyle, isNull);
      });

      test('preserves parts when not specified', () {
        final parts = SlideParts();
        final original = SlideTemplate(parts: parts);

        final copy = original.copyWith(baseStyle: SlideStyler());

        expect(copy.parts, same(parts));
      });

      test('preserves baseStyle when not specified', () {
        final baseStyle = SlideStyler();
        final original = SlideTemplate(baseStyle: baseStyle);

        final copy = original.copyWith(styles: {'x': SlideStyler()});

        expect(copy.baseStyle, same(baseStyle));
      });

      test('null retains the existing nullable baseStyle', () {
        final baseStyle = SlideStyler();
        final original = SlideTemplate(baseStyle: baseStyle);

        final copy = original.copyWith(baseStyle: null);

        expect(copy.baseStyle, same(baseStyle));
      });

      test('preserves styles when not specified', () {
        final styles = <String, SlideStyler>{'a': SlideStyler()};
        final original = SlideTemplate(styles: styles);

        final copy = original.copyWith(baseStyle: SlideStyler());

        expect(copy.styles, same(styles));
      });
    });

    group('equality', () {
      test('two templates with the same shared parts instance are equal', () {
        final parts = SlideParts();
        final a = SlideTemplate(parts: parts);
        final b = SlideTemplate(parts: parts);

        expect(a, equals(b));
      });

      test('identical template is equal to itself', () {
        const template = SlideTemplate();

        expect(template, equals(template));
      });

      test('templates with different parts instances are not equal', () {
        // SlideParts does not override ==, so distinct instances differ.
        final a = SlideTemplate(parts: SlideParts());
        final b = SlideTemplate(parts: SlideParts());

        expect(a, isNot(equals(b)));
      });

      test('templates with different baseStyles are not equal', () {
        final parts = SlideParts();
        final a = SlideTemplate(parts: parts, baseStyle: SlideStyler());
        final b = SlideTemplate(parts: parts);

        expect(a, isNot(equals(b)));
      });

      test('templates with equal baseStyles are equal', () {
        // SlideStyler uses Equatable, so two instances with same args are equal.
        final parts = SlideParts();
        final a = SlideTemplate(parts: parts, baseStyle: SlideStyler());
        final b = SlideTemplate(parts: parts, baseStyle: SlideStyler());

        expect(a, equals(b));
      });

      test('templates with different styles maps are not equal', () {
        final parts = SlideParts();
        final a = SlideTemplate(parts: parts, styles: {'dark': SlideStyler()});
        final b = SlideTemplate(parts: parts, styles: {});

        expect(a, isNot(equals(b)));
      });

      test('templates sharing the same styles map instance are equal', () {
        final parts = SlideParts();
        final styles = <String, SlideStyler>{'dark': SlideStyler()};
        final a = SlideTemplate(parts: parts, styles: styles);
        final b = SlideTemplate(parts: parts, styles: styles);

        expect(a, equals(b));
      });

      test('templates with same-content styles maps are not equal', () {
        final parts = SlideParts();
        final a = SlideTemplate(parts: parts, styles: {'dark': SlideStyler()});
        final b = SlideTemplate(parts: parts, styles: {'dark': SlideStyler()});

        expect(a, isNot(equals(b)));
      });
    });

    group('hashCode', () {
      test('equal templates have the same hashCode', () {
        final parts = SlideParts();
        final baseStyle = SlideStyler();
        final styles = <String, SlideStyler>{'x': SlideStyler()};

        final a = SlideTemplate(
          parts: parts,
          baseStyle: baseStyle,
          styles: styles,
        );
        final b = SlideTemplate(
          parts: parts,
          baseStyle: baseStyle,
          styles: styles,
        );

        expect(a.hashCode, equals(b.hashCode));
      });

      test('hashCode is consistent across multiple calls on same instance', () {
        const template = SlideTemplate();

        expect(template.hashCode, equals(template.hashCode));
      });

      test('templates that differ in parts have different hashCodes', () {
        // Different SlideParts instances have different identity-based hashCodes.
        final a = SlideTemplate(parts: SlideParts());
        final b = SlideTemplate(parts: SlideParts());

        // Distinct SlideParts instances will produce distinct hash values
        // in virtually all cases because Object.hashCode is identity-based.
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });
  });
}
