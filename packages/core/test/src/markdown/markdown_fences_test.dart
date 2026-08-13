import 'package:superdeck_core/superdeck_core.dart';
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
}
