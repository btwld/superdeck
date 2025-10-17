import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

import 'package:superdeck_core/src/hero_tag_helpers.dart';
import 'package:superdeck_core/src/markdown_syntaxes.dart';

void main() {
  // ============================================================================
  // Unit Tests - Hero tag helpers
  // ============================================================================

  group('stripTrailingHeroMarker', () {
    test('extracts hero from simple text', () {
      final result = stripTrailingHeroMarker('Hello World {.hero}');
      expect(result.text, 'Hello World');
      expect(result.hero, 'hero');
    });

    test('handles multiple classes, takes first valid', () {
      final result = stripTrailingHeroMarker('Text {.hero .accent .theme}');
      expect(result.text, 'Text');
      expect(result.hero, 'hero');
    });

    test('strips whitespace correctly', () {
      final result = stripTrailingHeroMarker('Text   {  .hero  }  ');
      expect(result.text, 'Text');
      expect(result.hero, 'hero');
    });

    test('returns null hero when no valid tag found', () {
      final result = stripTrailingHeroMarker('Text {.123invalid}');
      expect(result.text, 'Text');
      expect(result.hero, isNull);
    });

    test('returns original text when no marker present', () {
      final result = stripTrailingHeroMarker('Just plain text');
      expect(result.text, 'Just plain text');
      expect(result.hero, isNull);
    });

    test('rejects CSS custom property syntax', () {
      final result = stripTrailingHeroMarker('Text {.--custom}');
      expect(result.hero, isNull);
    });

    test('accepts hyphenated identifiers', () {
      final result = stripTrailingHeroMarker('Text {.my-hero}');
      expect(result.hero, 'my-hero');
    });

    test('accepts underscored identifiers', () {
      final result = stripTrailingHeroMarker('Text {._private}');
      expect(result.hero, '_private');
    });

    test('accepts identifiers starting with single hyphen', () {
      final result = stripTrailingHeroMarker('Text {.-webkit-custom}');
      expect(result.hero, '-webkit-custom');
    });

    test('handles empty content', () {
      final result = stripTrailingHeroMarker('');
      expect(result.text, '');
      expect(result.hero, isNull);
    });

    test('skips invalid classes and finds first valid one', () {
      final result = stripTrailingHeroMarker('Text {.123bad .--bad .hero}');
      expect(result.hero, 'hero');
    });
  });

  group('extractHeroFromFenceInfo', () {
    test('extracts from language with hero', () {
      final hero = extractHeroFromFenceInfo('```dart {.hero}');
      expect(hero, 'hero');
    });

    test('handles tildes instead of backticks', () {
      final hero = extractHeroFromFenceInfo('~~~python {.hero}');
      expect(hero, 'hero');
    });

    test('returns null when no braces', () {
      final hero = extractHeroFromFenceInfo('```dart');
      expect(hero, isNull);
    });

    test('handles multiple classes in braces', () {
      final hero = extractHeroFromFenceInfo('```js {.hero .accent}');
      expect(hero, 'hero');
    });

    test('handles indented fences (up to 3 spaces)', () {
      final hero = extractHeroFromFenceInfo('   ```dart {.hero}');
      expect(hero, 'hero');
    });

    test('handles four or more backticks', () {
      final hero = extractHeroFromFenceInfo('````dart {.hero}');
      expect(hero, 'hero');
    });

    test('handles fence without language', () {
      final hero = extractHeroFromFenceInfo('``` {.hero}');
      expect(hero, 'hero');
    });

    test('skips invalid identifiers in fence', () {
      final hero = extractHeroFromFenceInfo('```dart {.123 .hero}');
      expect(hero, 'hero');
    });

    test('returns null for empty braces', () {
      final hero = extractHeroFromFenceInfo('```dart {}');
      expect(hero, isNull);
    });
  });

  // ============================================================================
  // Syntax Tests - HeaderTagSyntax
  // ============================================================================

  group('HeaderTagSyntax', () {
    test('parses h1 header with hero tag', () {
      final html = md.markdownToHtml(
        '# Hello World {.hero}',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('<h1 hero="hero">Hello World</h1>'));
    });

    test('parses header without hero tag', () {
      final html = md.markdownToHtml(
        '# Plain Header',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('<h1>Plain Header</h1>'));
      expect(html, isNot(contains('hero=')));
    });

    test('preserves emphasis within header', () {
      final html = md.markdownToHtml(
        '# Hello *World* {.hero}',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('<h1 hero="hero">Hello <em>World</em></h1>'));
    });

    test('preserves strong within header', () {
      final html = md.markdownToHtml(
        '## **Bold** Header {.hero}',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(
        html,
        contains('<h2 hero="hero"><strong>Bold</strong> Header</h2>'),
      );
    });

    test('preserves inline code within header', () {
      final html = md.markdownToHtml(
        '### Header with `code` {.hero}',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(
        html,
        contains('<h3 hero="hero">Header with <code>code</code></h3>'),
      );
    });

    test('handles all heading levels (h1-h6)', () {
      final markdown = '''
# H1 {.hero1}
## H2 {.hero2}
### H3 {.hero3}
#### H4 {.hero4}
##### H5 {.hero5}
###### H6 {.hero6}
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: createHeroBlockSyntaxes(),
      );

      expect(html, contains('<h1 hero="hero1">H1</h1>'));
      expect(html, contains('<h2 hero="hero2">H2</h2>'));
      expect(html, contains('<h3 hero="hero3">H3</h3>'));
      expect(html, contains('<h4 hero="hero4">H4</h4>'));
      expect(html, contains('<h5 hero="hero5">H5</h5>'));
      expect(html, contains('<h6 hero="hero6">H6</h6>'));
    });

    test('ignores invalid hero tags', () {
      final html = md.markdownToHtml(
        '# Header {.123bad}',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('<h1>Header</h1>'));
      expect(html, isNot(contains('hero=')));
    });

    test('handles hero tag with closing hashes', () {
      final html = md.markdownToHtml(
        '# Header {.hero} ###',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('<h1 hero="hero">Header</h1>'));
    });

    test('handles header that is just hashes', () {
      final html = md.markdownToHtml(
        '### {.hero}',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('<h3 hero="hero"></h3>'));
    });

    test('falls back to base parser for invalid headers after strip', () {
      final html = md.markdownToHtml(
        'Not a # header {.hero}',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('<p>Not a # header {.hero}</p>'));
      expect(html, isNot(contains('hero=')));
    });

    test('handles whitespace variations around hero tag', () {
      final tests = [
        '# Header{.hero}',
        '# Header {.hero}',
        '# Header  {.hero}',
        '# Header   {  .hero  }',
      ];

      for (final test in tests) {
        final html = md.markdownToHtml(
          test,
          blockSyntaxes: createHeroBlockSyntaxes(),
        );
        expect(html, contains('hero="hero"'), reason: 'Failed for: $test');
      }
    });
  });

  // ============================================================================
  // Syntax Tests - ImageHeroSyntax
  // ============================================================================

  group('ImageHeroSyntax', () {
    test('parses image with hero tag', () {
      final html = md.markdownToHtml(
        '![alt text](image.png) {.hero}',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
      expect(html, contains('alt="alt text"'));
      expect(html, contains('src="image.png"'));
    });

    test('parses image without whitespace before hero tag', () {
      final html = md.markdownToHtml(
        '![alt text](image.png){.hero}',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
    });

    test('parses image without hero tag', () {
      final html = md.markdownToHtml(
        '![alt text](image.png)',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );
      expect(html, contains('alt="alt text"'));
      expect(html, isNot(contains('hero=')));
    });

    test('handles whitespace around hero tag', () {
      final html = md.markdownToHtml(
        '![alt](img.png)   {  .hero  }',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
    });

    test('ignores invalid hero tags', () {
      final html = md.markdownToHtml(
        '![alt](img.png) {.999}',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );
      expect(html, isNot(contains('hero=')));
    });

    test('handles multiple classes, uses first valid', () {
      final html = md.markdownToHtml(
        '![alt](img.png) {.hero .accent}',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
    });

    test('handles image with title', () {
      final html = md.markdownToHtml(
        '![alt](img.png "title") {.hero}',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
      expect(html, contains('title="title"'));
    });

    test('handles nested parentheses in URL', () {
      final html = md.markdownToHtml(
        '![alt](https://example.com/img_(v1).png "title") {.hero}',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );

      expect(html, contains('hero="hero"'));
      expect(html, contains('img_(v1).png'));
    });

    test('does not apply hero to non-image elements', () {
      final html = md.markdownToHtml(
        'Regular [link](url) {.hero}',
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );
      // Hero marker should remain as text since not after image
      expect(html, contains('{.hero}'));
    });
  });

  // ============================================================================
  // Syntax Tests - HeroFencedCodeBlockSyntax
  // ============================================================================

  group('HeroFencedCodeBlockSyntax', () {
    test('parses code block with hero tag', () {
      final markdown = '''
```dart {.hero}
void main() {}
```
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
      expect(html, contains('class="language-dart"'));
      expect(html, contains('void main() {}'));
    });

    test('parses code block without hero tag', () {
      final markdown = '''
```dart
void main() {}
```
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('class="language-dart"'));
      expect(html, isNot(contains('hero=')));
    });

    test('handles tilde fences', () {
      final markdown = '''
~~~python {.hero}
print("hello")
~~~
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
    });

    test('handles multiple classes in fence info', () {
      final markdown = '''
```js {.hero .special}
console.log("test");
```
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
    });

    test('handles code block without language', () {
      final markdown = '''
``` {.hero}
plain text
```
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
    });

    test('handles indented fences', () {
      final markdown = '''
   ```dart {.hero}
   code
   ```
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
    });

    test('preserves code content exactly', () {
      final markdown = '''
```dart {.hero}
// Special chars: <>&"'
String test = "hello {.world}";
```
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('hero="hero"'));
      expect(html, contains('&lt;'));
      expect(html, contains('&gt;'));
    });
  });

  // ============================================================================
  // Integration Tests
  // ============================================================================

  group('Integration with ExtensionSet', () {
    test('works with gitHubFlavored extension set', () {
      final markdown = '''
# Header {.hero}

Some **bold** text.

![image](test.png) {.img-hero}

```dart {.code-hero}
void main() {}
```
''';
      final html = md.markdownToHtml(
        markdown,
        extensionSet: md.ExtensionSet.gitHubFlavored,
        blockSyntaxes: [
          ...createHeroBlockSyntaxes(),
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        ],
        inlineSyntaxes: [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ...createHeroInlineSyntaxes(),
        ],
      );

      expect(html, contains('<h1 hero="hero">Header</h1>'));
      expect(html, contains('hero="img-hero"'));
      expect(html, contains('hero="code-hero"'));
      expect(html, contains('<strong>bold</strong>'));
    });

    test('combines all three syntax types', () {
      final markdown = '''
# Page Title {.title-hero}

![Logo](logo.svg) {.logo-hero}

```dart {.snippet-hero}
print('Hello');
```
''';
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: [
          ...createHeroBlockSyntaxes(),
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        ],
        inlineSyntaxes: createHeroInlineSyntaxes(),
      );

      expect(html, contains('hero="title-hero"'));
      expect(html, contains('hero="logo-hero"'));
      expect(html, contains('hero="snippet-hero"'));
    });
  });

  // ============================================================================
  // Edge Cases
  // ============================================================================

  group('Edge Cases', () {
    test('handles empty hero tag brackets', () {
      final result = stripTrailingHeroMarker('Text {}');
      expect(result.text, 'Text');
      expect(result.hero, isNull);
    });

    test('empty braces do not create hero attribute in HTML', () {
      final html = md.markdownToHtml(
        '# Header {}',
        blockSyntaxes: createHeroBlockSyntaxes(),
      );
      expect(html, contains('<h1>Header</h1>'));
      expect(html, isNot(contains('hero=')));
      expect(html, isNot(contains('hero=""')));
    });

    test('handles malformed brackets', () {
      final result = stripTrailingHeroMarker('Text {.hero');
      expect(result.text, 'Text {.hero');
      expect(result.hero, isNull);
    });

    test('handles unicode in hero tags (should reject)', () {
      final result = stripTrailingHeroMarker('Text {.héro}');
      expect(result.hero, isNull);
    });

    test('handles very long class lists', () {
      final longList = List.generate(100, (i) => '.class$i').join(' ');
      final result = stripTrailingHeroMarker('Text {$longList}');
      expect(result.hero, 'class0');
    });

    test('handles consecutive hero markers', () {
      final result = stripTrailingHeroMarker('Text {.a} {.b} {.c}');
      expect(result.hero, 'c');
    });

    test('handles whitespace-only between braces', () {
      final result = stripTrailingHeroMarker('Text {   }');
      expect(result.hero, isNull);
    });

    test('handles mixed valid and invalid in same braces', () {
      final result = stripTrailingHeroMarker('Text {.--bad .123 .hero}');
      expect(result.hero, 'hero');
    });
  });

  // ============================================================================
  // Pattern Validation Tests
  // ============================================================================

  group('Pattern Validation', () {
    test('validId accepts valid CSS identifiers', () {
      expect(heroValidIdentifierPattern.hasMatch('hero'), isTrue);
      expect(heroValidIdentifierPattern.hasMatch('_private'), isTrue);
      expect(heroValidIdentifierPattern.hasMatch('my-hero'), isTrue);
      expect(heroValidIdentifierPattern.hasMatch('Hero123'), isTrue);
      expect(heroValidIdentifierPattern.hasMatch('-webkit-custom'), isTrue);
    });

    test('validId rejects invalid CSS identifiers', () {
      expect(heroValidIdentifierPattern.hasMatch('123'), isFalse);
      expect(heroValidIdentifierPattern.hasMatch('-123'), isFalse);
      expect(heroValidIdentifierPattern.hasMatch('--custom'), isFalse);
      expect(heroValidIdentifierPattern.hasMatch('hero space'), isFalse);
      expect(heroValidIdentifierPattern.hasMatch(''), isFalse);
    });

    test('multiple documents can reuse syntax instances', () {
      final syntaxes = createHeroBlockSyntaxes();

      final doc1 = md.markdownToHtml(
        '# Doc 1 {.hero1}',
        blockSyntaxes: syntaxes,
      );
      final doc2 = md.markdownToHtml(
        '# Doc 2 {.hero2}',
        blockSyntaxes: syntaxes,
      );

      expect(doc1, contains('hero="hero1"'));
      expect(doc2, contains('hero="hero2"'));
    });
  });
}
