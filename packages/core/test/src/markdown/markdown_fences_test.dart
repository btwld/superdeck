import 'package:superdeck_core/src/markdown/markdown_fences.dart';
import 'package:test/test.dart';

void main() {
  group('fencedCodeRanges', () {
    test('covers a backtick fence including its closer', () {
      const text = '```\ncode\n```\nafter';
      final ranges = fencedCodeRanges(text);

      expect(ranges, hasLength(1));
      expect(isInsideFencedCode(0, ranges), isTrue);
      expect(isInsideFencedCode(text.indexOf('code'), ranges), isTrue);
      expect(isInsideFencedCode(text.indexOf('after'), ranges), isFalse);
    });

    test('covers a tilde fence', () {
      const text = '~~~\ncode\n~~~\nafter';
      final ranges = fencedCodeRanges(text);

      expect(ranges, hasLength(1));
      expect(isInsideFencedCode(text.indexOf('code'), ranges), isTrue);
      expect(isInsideFencedCode(text.indexOf('after'), ranges), isFalse);
    });

    test('opens on a language + {.hero} info string', () {
      const text = '```dart {.hero}\n---\n@override\n```\n@visible';
      final ranges = fencedCodeRanges(text);

      expect(isInsideFencedCode(text.indexOf('---'), ranges), isTrue);
      expect(isInsideFencedCode(text.indexOf('@override'), ranges), isTrue);
      expect(isInsideFencedCode(text.indexOf('@visible'), ranges), isFalse);
    });

    test('an unclosed fence extends to EOF', () {
      const text = '```\n---\nstill inside';
      final ranges = fencedCodeRanges(text);

      expect(ranges, hasLength(1));
      expect(ranges.single.end, text.length);
      expect(isInsideFencedCode(text.indexOf('still inside'), ranges), isTrue);
    });

    test('```{.code} closes an opening fence', () {
      const text = '```dart\ncode\n```{.code}\nafter';
      final ranges = fencedCodeRanges(text);

      expect(isInsideFencedCode(text.indexOf('code'), ranges), isTrue);
      expect(isInsideFencedCode(text.indexOf('after'), ranges), isFalse);
    });

    test('a tilde line does not close a backtick fence', () {
      const text = '```\ninside\n~~~\nstill\n```\noutside';
      final ranges = fencedCodeRanges(text);

      expect(isInsideFencedCode(text.indexOf('still'), ranges), isTrue);
      expect(isInsideFencedCode(text.indexOf('outside'), ranges), isFalse);
    });
  });

  group('fencedCodeLines', () {
    test('covers the fence lines and their body', () {
      // 0:before 1:``` 2:code 3:``` 4:after
      const text = 'before\n```\ncode\n```\nafter';

      expect(fencedCodeLines(text), {1, 2, 3});
    });

    test('an unclosed fence covers every line to the end', () {
      const text = 'before\n```\ncode\nmore';

      expect(fencedCodeLines(text), {1, 2, 3});
    });

    test('indices address text.split(chr(10)) for CRLF input', () {
      const text = 'before\r\n```\r\ncode\r\n```\r\nafter';
      final lines = text.split('\n');

      expect(fencedCodeLines(text), {1, 2, 3});
      expect(lines[2].trim(), 'code');
    });

    test('reports no lines when there is no fence', () {
      expect(fencedCodeLines('# Title\n\nBody text.'), isEmpty);
    });

    test('agrees with fencedCodeRanges on which lines are hidden', () {
      const text = 'a\n```dart {.hero}\n---\n@tag\n```{.code}\nb\n~~~\nc';
      final ranges = fencedCodeRanges(text);
      final lines = text.split('\n');
      final fromRanges = <int>{};
      var offset = 0;
      for (var i = 0; i < lines.length; i++) {
        if (isInsideFencedCode(offset, ranges)) fromRanges.add(i);
        offset += lines[i].length + 1;
      }

      expect(fencedCodeLines(text), fromRanges);
    });
  });
}
