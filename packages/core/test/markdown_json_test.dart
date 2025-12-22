import 'dart:convert';

import 'package:markdown/markdown.dart' as md;
import 'package:superdeck_core/src/markdown_json.dart';
import 'package:test/test.dart';

const _converter = MarkdownAstConverter();

void main() {
  group('MarkdownAstConverter', () {
    test('toMap respects instance defaults and per-call overrides', () {
      const markdown = '# Test converter';
      final converter = MarkdownAstConverter(
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final viaClass = converter.toMap(markdown);
      final viaOverride = _converter.toMap(
        markdown,
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      expect(viaClass, equals(viaOverride));
    });

    test('toJson respects prettyPrint and metadata flags', () {
      const markdown = '[link]: https://example.com\n\nSee [link].';
      final converter = MarkdownAstConverter();

      final compact = converter.toJson(markdown);
      final pretty = converter.toJson(markdown, prettyPrint: true);
      final withMetadata = converter.toJson(markdown, includeMetadata: true);

      expect(pretty.contains('\n'), isTrue);
      expect(compact.length, lessThan(pretty.length));
      expect(withMetadata.contains('linkReferences'), isTrue);
    });
  });

  group('MarkdownAstConverter.toJson', () {
    group('basic conversion', () {
      test('converts simple heading to JSON', () {
        final json = _converter.toJson('# Hello');
        expect(json, isNotEmpty);

        final parsed = jsonDecode(json) as Map<String, dynamic>;
        expect(parsed['type'], equals('document'));
        expect(parsed['children'], isList);
        expect(parsed['children'], isNotEmpty);
      });

      test('converts heading and paragraph', () {
        final json = _converter.toJson('# Hello\n\nWorld');
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['type'], equals('document'));
        final children = parsed['children'] as List;
        expect(children.length, equals(2));
      });

      test('handles empty document', () {
        final json = _converter.toJson('');
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['type'], equals('document'));
        expect(parsed['children'], isEmpty);
      });

      test('handles whitespace-only document', () {
        final json = _converter.toJson('   \n\n  ');
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['type'], equals('document'));
        // Whitespace-only content should result in empty children
        expect(parsed['children'], isEmpty);
      });
    });

    group('pretty print formatting', () {
      test('formats JSON with indentation when prettyPrint is true', () {
        final json = _converter.toJson('# Test', prettyPrint: true);

        expect(json, contains('\n'));
        expect(json, contains('  ')); // 2-space indent
      });

      test('formats JSON compactly when prettyPrint is false', () {
        final json = _converter.toJson('# Test', prettyPrint: false);

        // Compact JSON should not have newlines (except possibly in strings)
        final parsed = jsonDecode(json);
        expect(parsed, isNotNull);
      });

      test('uses compact format by default', () {
        final jsonDefault = _converter.toJson('# Test');
        final jsonExplicit = _converter.toJson('# Test', prettyPrint: false);

        expect(jsonDefault, equals(jsonExplicit));
      });
    });

    group('ExtensionSet support', () {
      test('handles default markdown without extensionSet', () {
        final json = _converter.toJson('# Test\n\n**bold**');
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        final children = parsed['children'] as List;
        expect(children.length, equals(2)); // h1 and p

        final heading = children[0] as Map;
        expect(heading['tag'], equals('h1'));

        final paragraph = children[1] as Map;
        expect(paragraph['tag'], equals('p'));
        // Verify bold is nested element
        expect(paragraph['children'], isNotEmpty);
      });

      test('supports ExtensionSet.none', () {
        final json = _converter.toJson(
          '# Test\n\n```dart\ncode\n```',
          extensionSet: md.ExtensionSet.none,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['children'], isNotEmpty);
      });

      test('supports ExtensionSet.commonMark', () {
        final json = _converter.toJson(
          '# Test\n\n```dart\ncode\n```',
          extensionSet: md.ExtensionSet.commonMark,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['children'], isNotEmpty);
      });

      test('supports ExtensionSet.gitHubWeb', () {
        final json = _converter.toJson(
          '# Test\n\n```dart\ncode\n```',
          extensionSet: md.ExtensionSet.gitHubWeb,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['children'], isNotEmpty);
      });

      test('supports ExtensionSet.gitHubFlavored', () {
        final json = _converter.toJson(
          '# Test\n\n```dart\ncode\n```',
          extensionSet: md.ExtensionSet.gitHubFlavored,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['children'], isNotEmpty);
      });
    });

    group('GitHub-flavored markdown features', () {
      test('converts tables', () {
        final markdown = '''
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
''';
        final json = _converter.toJson(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;
        final children = parsed['children'] as List;

        // Should contain a table element
        final hasTable = children.any(
          (child) => child['type'] == 'element' && child['tag'] == 'table',
        );
        expect(hasTable, isTrue);
      });

      test('validates complete table structure hierarchy', () {
        final markdown = '''
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final table = (map['children'] as List)[0] as Map;
        expect(table['type'], equals('element'));
        expect(table['tag'], equals('table'));

        final tableChildren = table['children'] as List;
        expect(tableChildren.length, equals(2)); // thead + tbody

        // Validate thead structure
        final thead = tableChildren[0] as Map;
        expect(thead['type'], equals('element'));
        expect(thead['tag'], equals('thead'));

        final theadTr = (thead['children'] as List)[0] as Map;
        expect(theadTr['tag'], equals('tr'));

        final th1 = (theadTr['children'] as List)[0] as Map;
        expect(th1['tag'], equals('th'));
        expect(th1['children'], isNotEmpty);

        // Validate tbody structure
        final tbody = tableChildren[1] as Map;
        expect(tbody['type'], equals('element'));
        expect(tbody['tag'], equals('tbody'));

        final tbodyTr = (tbody['children'] as List)[0] as Map;
        expect(tbodyTr['tag'], equals('tr'));

        final td1 = (tbodyTr['children'] as List)[0] as Map;
        expect(td1['tag'], equals('td'));
        expect(td1['children'], isNotEmpty);
      });

      test('validates table cell alignment attributes', () {
        final markdown = '''
| Left | Center | Right |
|:-----|:------:|------:|
| L1   | C1     | R1    |
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final table = (map['children'] as List)[0] as Map;
        final thead = (table['children'] as List)[0] as Map;
        final theadRow = (thead['children'] as List)[0] as Map;
        final headers = theadRow['children'] as List;

        // Check alignment attributes
        final th1 = headers[0] as Map;
        expect(th1['attributes']?['align'], equals('left'));

        final th2 = headers[1] as Map;
        expect(th2['attributes']?['align'], equals('center'));

        final th3 = headers[2] as Map;
        expect(th3['attributes']?['align'], equals('right'));

        // Verify alignment is preserved in body cells
        final tbody = (table['children'] as List)[1] as Map;
        final tbodyRow = (tbody['children'] as List)[0] as Map;
        final cells = tbodyRow['children'] as List;

        expect((cells[0] as Map)['attributes']?['align'], equals('left'));
        expect((cells[1] as Map)['attributes']?['align'], equals('center'));
        expect((cells[2] as Map)['attributes']?['align'], equals('right'));
      });

      test('validates table with empty cells', () {
        final markdown = '''
| H1 | H2 |
|----|---|
|    | X |
| Y  |   |
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final table = (map['children'] as List)[0] as Map;
        final tbody = (table['children'] as List)[1] as Map;
        final rows = tbody['children'] as List;

        // First row - empty first cell
        final row1 = rows[0] as Map;
        final row1Cells = row1['children'] as List;
        expect((row1Cells[0] as Map)['children'], isEmpty);

        // Second row - empty second cell
        final row2 = rows[1] as Map;
        final row2Cells = row2['children'] as List;
        expect((row2Cells[1] as Map)['children'], isEmpty);
      });

      test('converts task lists', () {
        final markdown = '''
- [ ] Unchecked task
- [x] Checked task
''';
        final json = _converter.toJson(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['children'], isNotEmpty);
      });

      test('validates task list basic structure', () {
        final markdown = '''
- [ ] Unchecked task
- [x] Checked task
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final ul = (map['children'] as List)[0] as Map;
        expect(ul['tag'], equals('ul'));

        final items = ul['children'] as List;
        expect(items.length, equals(2));

        // Both items should be li elements
        expect((items[0] as Map)['tag'], equals('li'));
        expect((items[1] as Map)['tag'], equals('li'));

        // Items should contain input checkboxes if supported by markdown package
        final li1 = items[0] as Map;
        final li1Children = li1['children'] as List;
        if (li1Children.isNotEmpty &&
            (li1Children[0] as Map)['tag'] == 'input') {
          final checkbox = li1Children[0] as Map;
          expect(checkbox['attributes']?['type'], equals('checkbox'));
        }
      });

      test('converts strikethrough text', () {
        final json = _converter.toJson(
          '~~strikethrough~~',
          extensionSet: md.ExtensionSet.gitHubWeb,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['children'], isNotEmpty);
      });

      test('validates strikethrough (del) element structure', () {
        final markdown = '~~deleted text~~';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final p = (map['children'] as List)[0] as Map;
        final del = (p['children'] as List)[0] as Map;

        expect(del['tag'], equals('del'));
        expect(del['children'], isNotEmpty);

        final text = (del['children'] as List)[0] as Map;
        expect(text['type'], equals('text'));
        expect(text['text'], equals('deleted text'));
      });

      test('validates horizontal rule (hr) element', () {
        final markdown = '---';
        final map = _converter.toMap(markdown);

        final hr = (map['children'] as List)[0] as Map;

        expect(hr['tag'], equals('hr'));
        expect(hr['isEmpty'], isTrue);
      });

      test('validates all heading levels (h1-h6)', () {
        final headings = ['#', '##', '###', '####', '#####', '######'];

        for (var i = 0; i < headings.length; i++) {
          final markdown = '${headings[i]} Heading ${i + 1}';
          final map = _converter.toMap(markdown);

          final heading = (map['children'] as List)[0] as Map;
          expect(heading['tag'], equals('h${i + 1}'));

          final text = (heading['children'] as List)[0] as Map;
          expect(text['type'], equals('text'));
          expect(text['text'], equals('Heading ${i + 1}'));
        }
      });

      test('converts alert blocks', () {
        final markdown = '''
> [!NOTE]
> This is a note
''';
        final json = _converter.toJson(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;

        expect(parsed['children'], isNotEmpty);
      });

      test('validates NOTE alert structure', () {
        final markdown = '''
> [!NOTE]
> This is a note alert
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final alertDiv = (map['children'] as List)[0] as Map;
        expect(alertDiv['tag'], equals('div'));
        expect(alertDiv['attributes']?['class'], contains('markdown-alert'));
        expect(
          alertDiv['attributes']?['class'],
          contains('markdown-alert-note'),
        );
      });

      test('validates TIP alert structure', () {
        final markdown = '''
> [!TIP]
> This is a tip alert
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final alertDiv = (map['children'] as List)[0] as Map;
        expect(alertDiv['tag'], equals('div'));
        expect(alertDiv['attributes']?['class'], contains('markdown-alert'));
        expect(
          alertDiv['attributes']?['class'],
          contains('markdown-alert-tip'),
        );
      });

      test('validates IMPORTANT alert structure', () {
        final markdown = '''
> [!IMPORTANT]
> This is important
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final alertDiv = (map['children'] as List)[0] as Map;
        expect(alertDiv['tag'], equals('div'));
        expect(alertDiv['attributes']?['class'], contains('markdown-alert'));
        expect(
          alertDiv['attributes']?['class'],
          contains('markdown-alert-important'),
        );
      });

      test('validates WARNING alert structure', () {
        final markdown = '''
> [!WARNING]
> This is a warning
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final alertDiv = (map['children'] as List)[0] as Map;
        expect(alertDiv['tag'], equals('div'));
        expect(alertDiv['attributes']?['class'], contains('markdown-alert'));
        expect(
          alertDiv['attributes']?['class'],
          contains('markdown-alert-warning'),
        );
      });

      test('validates CAUTION alert structure', () {
        final markdown = '''
> [!CAUTION]
> This is a caution alert
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final alertDiv = (map['children'] as List)[0] as Map;
        expect(alertDiv['tag'], equals('div'));
        expect(alertDiv['attributes']?['class'], contains('markdown-alert'));
        expect(
          alertDiv['attributes']?['class'],
          contains('markdown-alert-caution'),
        );
      });

      test('converts fenced code blocks', () {
        final markdown = '''
```dart
void main() {
  print('Hello');
}
```
''';
        final json = _converter.toJson(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;
        final children = parsed['children'] as List;

        // Should contain a code block element
        final hasCodeBlock = children.any(
          (child) => child['type'] == 'element' && child['tag'] == 'pre',
        );
        expect(hasCodeBlock, isTrue);
      });

      test('validates fenced code block with language class', () {
        final markdown = '''
```dart
void main() {}
```
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final pre = (map['children'] as List)[0] as Map;
        expect(pre['tag'], equals('pre'));

        final code = (pre['children'] as List)[0] as Map;
        expect(code['tag'], equals('code'));
        expect(code['attributes']?['class'], equals('language-dart'));
      });

      test('validates multiple programming language classes', () {
        final languages = {
          'python': 'language-python',
          'javascript': 'language-javascript',
          'rust': 'language-rust',
          'go': 'language-go',
        };

        for (final entry in languages.entries) {
          final markdown = '```${entry.key}\ncode\n```';
          final map = _converter.toMap(
            markdown,
            extensionSet: md.ExtensionSet.gitHubWeb,
          );

          final pre = (map['children'] as List)[0] as Map;
          final code = (pre['children'] as List)[0] as Map;

          expect(
            code['attributes']?['class'],
            equals(entry.value),
            reason: 'Language ${entry.key} should have class ${entry.value}',
          );
        }
      });

      test('validates code block without language specification', () {
        final markdown = '''
```
plain code
```
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final pre = (map['children'] as List)[0] as Map;
        expect(pre['tag'], equals('pre'));

        final code = (pre['children'] as List)[0] as Map;
        expect(code['tag'], equals('code'));
        // No language = no class attribute (or empty)
        expect(
          code['attributes']?.containsKey('class') != true ||
              code['attributes']?['class'] == '',
          isTrue,
        );
      });

      test('validates inline code elements', () {
        final markdown = 'Text with `inline code` here';
        final map = _converter.toMap(markdown);

        final p = (map['children'] as List)[0] as Map;
        final children = p['children'] as List;

        // Find the code element
        final code =
            children.firstWhere((child) => (child as Map)['tag'] == 'code')
                as Map;

        expect(code['tag'], equals('code'));
        expect(code['children'], isNotEmpty);

        final codeText = (code['children'] as List)[0] as Map;
        expect(codeText['type'], equals('text'));
        expect(codeText['text'], equals('inline code'));
      });

      test('validates footnote reference structure', () {
        final markdown = '''
Text with footnote[^1].

[^1]: Footnote content here
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final children = map['children'] as List;

        // First element is the paragraph with footnote ref
        final p = children[0] as Map;
        expect(p['tag'], equals('p'));

        // Find the sup element containing footnote reference
        final pChildren = p['children'] as List;
        final sup =
            pChildren.firstWhere((child) => (child as Map)['tag'] == 'sup')
                as Map;
        expect(sup['tag'], equals('sup'));

        // Last element should be footnotes section
        final section = children.last as Map;
        expect(section['tag'], equals('section'));
        expect(section['attributes']?['class'], equals('footnotes'));
      });

      test('validates footnote section structure', () {
        final markdown = '''
See footnote[^1] and another[^2].

[^1]: First note
[^2]: Second note
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final children = map['children'] as List;
        final section = children.last as Map;

        expect(section['tag'], equals('section'));
        expect(section['attributes']?['class'], equals('footnotes'));

        // Section should contain an ol
        final ol = (section['children'] as List)[0] as Map;
        expect(ol['tag'], equals('ol'));

        // ol should contain li elements for each footnote
        final items = ol['children'] as List;
        expect(items.length, equals(2));

        final li1 = items[0] as Map;
        expect(li1['tag'], equals('li'));

        final li2 = items[1] as Map;
        expect(li2['tag'], equals('li'));
      });
    });
  });

  group('MarkdownAstConverter.toMap', () {
    test('returns Map structure', () {
      final map = _converter.toMap('# Test');

      expect(map, isA<Map<String, Object?>>());
      expect(map['type'], equals('document'));
      expect(map['children'], isList);
    });

    test('supports extensionSet parameter', () {
      final map = _converter.toMap(
        '# Test',
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      expect(map['type'], equals('document'));
    });

    test('supports includeMetadata parameter', () {
      final markdown = '''
# Test

[link]: https://example.com
''';
      final map = _converter.toMap(markdown, includeMetadata: true);

      expect(map.containsKey('linkReferences'), isTrue);
      expect(map.containsKey('footnoteLabels'), isTrue);
      expect(map.containsKey('footnoteReferences'), isTrue);
    });

    test('excludes metadata by default', () {
      final map = _converter.toMap('# Test');

      expect(map.containsKey('linkReferences'), isFalse);
      expect(map.containsKey('footnoteLabels'), isFalse);
      expect(map.containsKey('footnoteReferences'), isFalse);
    });

    test('includes linkReferences when available', () {
      final markdown = '''
See [example].

[example]: https://example.com "Example Site"
''';
      final map = _converter.toMap(markdown, includeMetadata: true);

      final linkRefs = map['linkReferences'] as Map?;
      expect(linkRefs, isNotNull);
      expect(linkRefs!.containsKey('example'), isTrue);

      final exampleRef = linkRefs['example'] as Map;
      expect(exampleRef['destination'], equals('https://example.com'));
      expect(exampleRef['title'], equals('Example Site'));
    });
  });

  group('nodeToMap', () {
    group('Element nodes', () {
      test('converts basic element with tag', () {
        final element = md.Element('p', [md.Text('Hello')]);
        final json = nodeToMap(element);

        expect(json['type'], equals('element'));
        expect(json['tag'], equals('p'));
        expect(json['children'], isList);
      });

      test('converts element with attributes', () {
        final element = md.Element('a', [md.Text('Link')]);
        element.attributes['href'] = 'https://example.com';
        element.attributes['title'] = 'Example';

        final json = nodeToMap(element);

        expect(json['attributes'], isNotNull);
        final attrs = json['attributes'] as Map;
        expect(attrs['href'], equals('https://example.com'));
        expect(attrs['title'], equals('Example'));
      });

      test('returns defensive copy of attributes', () {
        final element = md.Element('a', [md.Text('Link')]);
        element.attributes['href'] = 'https://example.com';

        final json = nodeToMap(element);
        final attrs = json['attributes'] as Map;

        attrs.remove('href');

        expect(element.attributes['href'], equals('https://example.com'));
        expect(attrs.containsKey('href'), isFalse);
      });

      test('omits attributes when empty', () {
        final element = md.Element('p', [md.Text('Text')]);
        final json = nodeToMap(element);

        expect(json.containsKey('attributes'), isFalse);
      });

      test('validates image attributes from markdown', () {
        final markdown =
            '![Alt text](https://example.com/image.png "Image Title")';
        final map = _converter.toMap(markdown);

        final p = (map['children'] as List)[0] as Map;
        final img = (p['children'] as List)[0] as Map;

        expect(img['tag'], equals('img'));
        expect(
          img['attributes']?['src'],
          equals('https://example.com/image.png'),
        );
        expect(img['attributes']?['alt'], equals('Alt text'));
        expect(img['attributes']?['title'], equals('Image Title'));
      });

      test('validates image with special characters in alt text', () {
        final markdown =
            '![Image with "quotes" & symbols](https://example.com/img.png)';
        final map = _converter.toMap(markdown);

        final p = (map['children'] as List)[0] as Map;
        final img = (p['children'] as List)[0] as Map;

        expect(img['tag'], equals('img'));
        // Special chars are HTML-escaped in alt text
        expect(
          img['attributes']?['alt'],
          equals('Image with &quot;quotes&quot; &amp; symbols'),
        );
      });

      test('validates image without title', () {
        final markdown = '![Just alt](https://example.com/image.png)';
        final map = _converter.toMap(markdown);

        final p = (map['children'] as List)[0] as Map;
        final img = (p['children'] as List)[0] as Map;

        expect(img['tag'], equals('img'));
        expect(
          img['attributes']?['src'],
          equals('https://example.com/image.png'),
        );
        expect(img['attributes']?['alt'], equals('Just alt'));
        expect(img['attributes'], isNot(contains('title')));
      });

      test('validates link attributes from markdown', () {
        final markdown = '[Link text](https://example.com "Link Title")';
        final map = _converter.toMap(markdown);

        final p = (map['children'] as List)[0] as Map;
        final a = (p['children'] as List)[0] as Map;

        expect(a['tag'], equals('a'));
        expect(a['attributes']?['href'], equals('https://example.com'));
        expect(a['attributes']?['title'], equals('Link Title'));

        // Check link text content
        final linkText = (a['children'] as List)[0] as Map;
        expect(linkText['type'], equals('text'));
        expect(linkText['text'], equals('Link text'));
      });

      test('validates link with URL encoding', () {
        final markdown = '[Search](https://example.com?q=test&lang=en)';
        final map = _converter.toMap(markdown);

        final p = (map['children'] as List)[0] as Map;
        final a = (p['children'] as List)[0] as Map;

        expect(a['tag'], equals('a'));
        expect(
          a['attributes']?['href'],
          equals('https://example.com?q=test&lang=en'),
        );
      });

      test('validates link without title', () {
        final markdown = '[No title](https://example.com)';
        final map = _converter.toMap(markdown);

        final p = (map['children'] as List)[0] as Map;
        final a = (p['children'] as List)[0] as Map;

        expect(a['tag'], equals('a'));
        expect(a['attributes']?['href'], equals('https://example.com'));
        expect(a['attributes'], isNot(contains('title')));
      });

      test('validates reference-style link attributes', () {
        final markdown = '''
[Link text][ref]

[ref]: https://example.com "Reference Title"
''';
        final map = _converter.toMap(markdown);

        final p = (map['children'] as List)[0] as Map;
        final a = (p['children'] as List)[0] as Map;

        expect(a['tag'], equals('a'));
        expect(a['attributes']?['href'], equals('https://example.com'));
        expect(a['attributes']?['title'], equals('Reference Title'));
      });

      test('includes generatedId when present', () {
        final element = md.Element('h1', [md.Text('Heading')]);
        element.generatedId = 'heading-1';

        final json = nodeToMap(element);

        expect(json['generatedId'], equals('heading-1'));
      });

      test('omits generatedId when null', () {
        final element = md.Element('p', [md.Text('Text')]);
        final json = nodeToMap(element);

        expect(json.containsKey('generatedId'), isFalse);
      });

      test('validates generatedId from heading markdown with custom ID', () {
        final markdown = '# Heading {#custom-id}';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final h1 = (map['children'] as List)[0] as Map;
        expect(h1['tag'], equals('h1'));
        // The markdown package prepends "heading-" to custom IDs
        expect(h1['generatedId'], equals('heading-custom-id'));
      });

      test('validates generatedId auto-generation from heading text', () {
        final markdown = '## My Heading Title';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final h2 = (map['children'] as List)[0] as Map;
        expect(h2['tag'], equals('h2'));
        // Auto-generated IDs are typically lowercase and hyphenated
        expect(h2['generatedId'], isNotNull);
        expect(h2['generatedId'], equals('my-heading-title'));
      });

      test('validates generatedId for multiple heading levels', () {
        final markdown = '''
# Level 1
## Level 2
### Level 3
#### Level 4
##### Level 5
###### Level 6
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final headings = map['children'] as List;

        for (var i = 0; i < 6; i++) {
          final heading = headings[i] as Map;
          expect(heading['tag'], equals('h${i + 1}'));
          expect(heading['generatedId'], isNotNull);
          expect(heading['generatedId'], equals('level-${i + 1}'));
        }
      });

      test('validates generatedId handles special characters', () {
        final markdown = '# Hello, World! & More';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final h1 = (map['children'] as List)[0] as Map;
        expect(h1['tag'], equals('h1'));
        expect(h1['generatedId'], isNotNull);
        // Special chars are typically removed or converted
        expect(h1['generatedId'], matches(RegExp(r'^[a-z0-9-]+$')));
      });

      test('includes footnoteLabel when present', () {
        final element = md.Element('p', [md.Text('Note')]);
        element.footnoteLabel = '1';

        final json = nodeToMap(element);

        expect(json['footnoteLabel'], equals('1'));
      });

      test('omits footnoteLabel when null', () {
        final element = md.Element('p', [md.Text('Text')]);
        final json = nodeToMap(element);

        expect(json.containsKey('footnoteLabel'), isFalse);
      });

      test('validates footnoteLabel from markdown footnotes', () {
        final markdown = '''
Text with footnote[^1].

[^1]: Footnote content
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final children = map['children'] as List;
        final section = children.last as Map;

        // Section should have footnotes
        expect(section['tag'], equals('section'));

        final ol = (section['children'] as List)[0] as Map;
        final li = (ol['children'] as List)[0] as Map;

        // The li element should have footnoteLabel
        expect(li['footnoteLabel'], isNotNull);
        expect(li['footnoteLabel'], equals('1'));
      });

      test('validates footnoteLabel for multiple footnotes', () {
        final markdown = '''
First[^1] and second[^2] and third[^note].

[^1]: First note
[^2]: Second note
[^note]: Named note
''';
        final map = _converter.toMap(
          markdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        final children = map['children'] as List;
        final section = children.last as Map;
        final ol = (section['children'] as List)[0] as Map;
        final items = ol['children'] as List;

        // Check footnoteLabel for each footnote
        expect((items[0] as Map)['footnoteLabel'], equals('1'));
        expect((items[1] as Map)['footnoteLabel'], equals('2'));
        expect((items[2] as Map)['footnoteLabel'], equals('note'));
      });

      test('includes isEmpty when element is self-closing', () {
        final element = md.Element.empty('br');
        final json = nodeToMap(element);

        expect(json['isEmpty'], isTrue);
      });

      test('omits isEmpty when element has children', () {
        final element = md.Element('p', [md.Text('Text')]);
        final json = nodeToMap(element);

        expect(json.containsKey('isEmpty'), isFalse);
      });

      test('handles empty children list (not self-closing)', () {
        final element = md.Element.withTag('div');
        final json = nodeToMap(element);

        expect(json['children'], isEmpty);
        expect(json.containsKey('isEmpty'), isFalse);
      });

      test('handles nested elements', () {
        final inner = md.Element('em', [md.Text('italic')]);
        final outer = md.Element('strong', [inner]);

        final json = nodeToMap(outer);

        expect(json['tag'], equals('strong'));
        final children = json['children'] as List;
        expect(children.length, equals(1));

        final innerJson = children[0] as Map;
        expect(innerJson['tag'], equals('em'));
      });

      test('handles deeply nested structures', () {
        final text = md.Text('text');
        final em = md.Element('em', [text]);
        final strong = md.Element('strong', [em]);
        final p = md.Element('p', [strong]);

        final json = nodeToMap(p);

        expect(json['tag'], equals('p'));
        final level1 = (json['children'] as List)[0] as Map;
        expect(level1['tag'], equals('strong'));
        final level2 = (level1['children'] as List)[0] as Map;
        expect(level2['tag'], equals('em'));
        final level3 = (level2['children'] as List)[0] as Map;
        expect(level3['type'], equals('text'));
      });
    });

    group('Text nodes', () {
      test('converts text node', () {
        final text = md.Text('Hello World');
        final json = nodeToMap(text);

        expect(json['type'], equals('text'));
        expect(json['text'], equals('Hello World'));
      });

      test('handles empty text', () {
        final text = md.Text('');
        final json = nodeToMap(text);

        expect(json['type'], equals('text'));
        expect(json['text'], equals(''));
      });

      test('preserves special characters', () {
        final text = md.Text('Hello & "World" <test>');
        final json = nodeToMap(text);

        expect(json['text'], equals('Hello & "World" <test>'));
      });

      test('preserves unicode characters', () {
        final text = md.Text('Hello 👋 World 🌍');
        final json = nodeToMap(text);

        expect(json['text'], equals('Hello 👋 World 🌍'));
      });

      test('preserves newlines in text', () {
        final text = md.Text('Line 1\nLine 2');
        final json = nodeToMap(text);

        expect(json['text'], equals('Line 1\nLine 2'));
      });
    });

    group('UnparsedContent nodes', () {
      test('converts UnparsedContent node', () {
        final unparsed = md.UnparsedContent('raw content');
        final json = nodeToMap(unparsed);

        expect(json['type'], equals('unparsed'));
        expect(json['text'], equals('raw content'));
      });

      test('handles empty UnparsedContent', () {
        final unparsed = md.UnparsedContent('');
        final json = nodeToMap(unparsed);

        expect(json['type'], equals('unparsed'));
        expect(json['text'], equals(''));
      });
    });

    group('unknown node handling', () {
      test('throws UnimplementedError for unknown node type', () {
        // Create a mock unknown node type
        final unknownNode = _MockUnknownNode();

        expect(
          () => nodeToMap(unknownNode),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });
  });

  group('edge cases', () {
    test('handles CRLF line endings', () {
      final markdown = '# Heading\r\n\r\nParagraph\r\n';
      final json = _converter.toJson(markdown);
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['type'], equals('document'));
      expect(parsed['children'], isNotEmpty);
    });

    test('handles mixed line endings', () {
      final markdown = '# Heading\n\nParagraph\r\n\nAnother\r\n';
      final json = _converter.toJson(markdown);
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['type'], equals('document'));
      expect(parsed['children'], isNotEmpty);
    });

    test('handles very long text content', () {
      final longText = 'A' * 10000;
      final markdown = '# $longText';
      final json = _converter.toJson(markdown);

      expect(json, isNotEmpty);
    });

    test('handles special markdown characters in text', () {
      final markdown = r'Text with \* escaped \_ characters';
      final json = _converter.toJson(markdown);
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['children'], isNotEmpty);
    });

    test('handles inline code with backticks', () {
      final markdown = 'Text with `inline code` here';
      final json = _converter.toJson(markdown);
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['children'], isNotEmpty);
    });

    test('handles links with special characters', () {
      final markdown = '[Link](https://example.com?foo=bar&baz=qux)';
      final json = _converter.toJson(markdown);
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['children'], isNotEmpty);
    });
  });

  group('document structure', () {
    test('preserves multiple paragraphs', () {
      final markdown = 'Para 1\n\nPara 2\n\nPara 3';
      final map = _converter.toMap(markdown);
      final children = map['children'] as List;

      expect(children.length, equals(3));
    });

    test('preserves list structure', () {
      final markdown = '''
- Item 1
- Item 2
- Item 3
''';
      final map = _converter.toMap(markdown);
      final children = map['children'] as List;

      expect(children, isNotEmpty);
      final list = children[0] as Map;
      expect(list['tag'], equals('ul'));
    });

    test('preserves heading hierarchy', () {
      final markdown = '''
# H1
## H2
### H3
''';
      final map = _converter.toMap(markdown);
      final children = map['children'] as List;

      expect(children.length, equals(3));
      expect((children[0] as Map)['tag'], equals('h1'));
      expect((children[1] as Map)['tag'], equals('h2'));
      expect((children[2] as Map)['tag'], equals('h3'));
    });

    test('preserves blockquotes', () {
      final markdown = '''
> Quote line 1
> Quote line 2
''';
      final map = _converter.toMap(markdown);
      final children = map['children'] as List;

      expect(children, isNotEmpty);
      final blockquote = children[0] as Map;
      expect(blockquote['tag'], equals('blockquote'));
    });
  });

  group('integration tests', () {
    test('converts complex document with all features', () {
      final markdown = '''
# Main Heading {#custom-id}

This is a **bold** paragraph with *italic* and `code`.

## Subheading

- Task list item
- Another item

> [!NOTE]
> Important information

```dart
void main() {
  print('Hello');
}
```

| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |

[Link text][ref]

[ref]: https://example.com "Title"
''';

      final map = _converter.toMap(
        markdown,
        extensionSet: md.ExtensionSet.gitHubWeb,
        includeMetadata: true,
      );

      expect(map['type'], equals('document'));
      expect(map['children'], isNotEmpty);
      expect(map['linkReferences'], isNotNull);

      final json = _converter.toJson(
        markdown,
        extensionSet: md.ExtensionSet.gitHubWeb,
        prettyPrint: true,
      );

      expect(json, contains('\n'));
      final parsed = jsonDecode(json);
      expect(parsed, isNotNull);
    });

    test('toMap and toJson produce equivalent results', () {
      final markdown = '# Test\n\nParagraph';
      final map = _converter.toMap(markdown);
      final jsonString = _converter.toJson(markdown);
      final parsedMap = jsonDecode(jsonString);

      expect(map, equals(parsedMap));
    });

    test('extensionSet affects parsing behavior', () {
      final withExtensions = _converter.toMap(
        '~~strikethrough~~',
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final withoutExtensions = _converter.toMap(
        '~~strikethrough~~',
        extensionSet: md.ExtensionSet.none,
      );

      // Should parse differently - gitHubWeb parses strikethrough, none doesn't
      expect(withExtensions, isNot(equals(withoutExtensions)));
    });

    test('footnoteReferences has correct structure', () {
      final markdown = '''
Text with footnote[^1].

[^1]: Footnote content
''';

      final map = _converter.toMap(
        markdown,
        extensionSet: md.ExtensionSet.gitHubWeb,
        includeMetadata: true,
      );

      expect(map['footnoteReferences'], isA<Map>());
      expect(map['footnoteLabels'], isA<List>());
    });
  });
}

/// Mock class for testing unknown node types.
/// Used to verify that nodeToMap throws UnimplementedError for unsupported nodes.
class _MockUnknownNode implements md.Node {
  @override
  void accept(md.NodeVisitor visitor) {}

  @override
  String get textContent => '';
}
