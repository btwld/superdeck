import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/syntax_highlighter.dart';

void main() {
  testWidgets('SyntaxHighlight.render requires initialization', (tester) async {
    const source = 'void main() {}';

    final beforeInit = SyntaxHighlight.render(source, 'dart');
    expect(beforeInit.length, 1);
    expect(beforeInit[0].text, source);
    expect(beforeInit[0].children, isNull);

    await SyntaxHighlight.initialize();

    final afterInit = SyntaxHighlight.render(source, 'dart');
    expect(afterInit, isNotEmpty);
    expect(afterInit[0].children, isNotEmpty);
  });

  group('splitTextSpansByLines', () {
    test('returns empty TextSpan for empty input', () {
      final result = splitTextSpansByLines([]);

      expect(result.length, 1);
      expect(result[0].children, isEmpty);
    });

    test('handles single TextSpan without newlines', () {
      final spans = [const TextSpan(text: 'Hello World')];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 1);
      expect(result[0].children?.length, 1);
      expect((result[0].children![0] as TextSpan).text, 'Hello World');
    });

    test('splits single TextSpan by newlines', () {
      final spans = [const TextSpan(text: 'Line 1\nLine 2\nLine 3')];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 3);
      expect((result[0].children![0] as TextSpan).text, 'Line 1');
      expect((result[1].children![0] as TextSpan).text, 'Line 2');
      expect((result[2].children![0] as TextSpan).text, 'Line 3');
    });

    test('preserves TextStyle through split', () {
      const style = TextStyle(color: Color(0xFFFF0000));
      final spans = [const TextSpan(text: 'Red\nStill Red', style: style)];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 2);
      expect((result[0].children![0] as TextSpan).style, style);
      expect((result[1].children![0] as TextSpan).style, style);
    });

    test('handles multiple TextSpans', () {
      final spans = [
        const TextSpan(text: 'First'),
        const TextSpan(text: ' Second'),
      ];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 1);
      expect(result[0].children?.length, 2);
    });

    test('handles TextSpan with children', () {
      final spans = [
        const TextSpan(
          style: TextStyle(fontWeight: FontWeight.bold),
          children: [
            TextSpan(text: 'Child 1'),
            TextSpan(text: '\n'),
            TextSpan(text: 'Child 2'),
          ],
        ),
      ];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 2);
    });

    test('handles empty string parts after split', () {
      final spans = [const TextSpan(text: '\n\n')];
      final result = splitTextSpansByLines(spans);

      // Three newlines create 3 empty parts
      expect(result.length, 3);
    });

    test('handles trailing newline', () {
      final spans = [const TextSpan(text: 'Line 1\n')];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 2);
      expect((result[0].children![0] as TextSpan).text, 'Line 1');
      expect(result[1].children, isEmpty);
    });

    test('handles leading newline', () {
      final spans = [const TextSpan(text: '\nLine 2')];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 2);
      expect(result[0].children, isEmpty);
      expect((result[1].children![0] as TextSpan).text, 'Line 2');
    });

    test('handles mixed styled and unstyled spans', () {
      const redStyle = TextStyle(color: Color(0xFFFF0000));
      const blueStyle = TextStyle(color: Color(0xFF0000FF));
      final spans = [
        const TextSpan(text: 'Red', style: redStyle),
        const TextSpan(text: '\n'),
        const TextSpan(text: 'Blue', style: blueStyle),
      ];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 2);
      expect((result[0].children![0] as TextSpan).style, redStyle);
      expect((result[1].children![0] as TextSpan).style, blueStyle);
    });

    test('handles deeply nested children', () {
      final spans = [
        const TextSpan(
          children: [
            TextSpan(children: [TextSpan(text: 'Deep\nNesting')]),
          ],
        ),
      ];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 2);
    });

    test('handles TextSpan with null text', () {
      final spans = [const TextSpan(text: null)];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 1);
    });

    test('handles complex code-like content', () {
      final spans = [
        const TextSpan(text: 'void main() {\n'),
        const TextSpan(
          text: '  print("Hello");\n',
          style: TextStyle(color: Color(0xFF00FF00)),
        ),
        const TextSpan(text: '}'),
      ];
      final result = splitTextSpansByLines(spans);

      expect(result.length, 3);
    });
  });

  group('parseLineNumbers Tests', () {
    test('Single number', () {
      expect(parseLineNumbers('lang {1}'), equals([1]));
    });

    test('Multiple single numbers', () {
      expect(parseLineNumbers('lang {1, 2, 3, 4}'), equals([1, 2, 3, 4]));
    });

    test('Range of numbers', () {
      expect(parseLineNumbers('lang {3-6}'), equals([3, 4, 5, 6]));
    });

    test('Single number and range', () {
      expect(parseLineNumbers('lang {1, 3-6}'), equals([1, 3, 4, 5, 6]));
    });

    test('Multiple ranges', () {
      expect(parseLineNumbers('lang {1-2, 4-5}'), equals([1, 2, 4, 5]));
    });

    test('Combination of single numbers and ranges', () {
      expect(
        parseLineNumbers('lang {1, 3-6, 10, 21-23}'),
        equals([1, 3, 4, 5, 6, 10, 21, 22, 23]),
      );
    });

    test('No braces returns empty list', () {
      expect(parseLineNumbers('lang 1, 3-6, 10, 21-23'), equals([]));
    });

    test('Empty braces', () {
      expect(parseLineNumbers('lang {}'), equals([]));
    });

    test('Spaces within braces', () {
      expect(
        parseLineNumbers('lang { 1 , 2 , 3 - 5 }'),
        equals([1, 2, 3, 4, 5]),
      );
    });

    test('Invalid range (start > end)', () {
      // This test assumes the function does not correct for invalid ranges and simply does not include them.
      // Adjust based on your implementation behavior (e.g., throw an error, or include the start number only)
      expect(parseLineNumbers('lang {6-3}'), equals([]));
    });
  });
}
