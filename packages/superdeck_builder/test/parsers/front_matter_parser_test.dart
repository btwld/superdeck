import 'package:superdeck_builder/src/parsers/front_matter_parser.dart';
import 'package:test/test.dart';

void main() {
  group('FrontmatterParser Tests', () {
    final parser = FrontmatterParser();

    test('Parses frontmatter and markdown correctly', () {
      const input = '''
---
title: Test Title
description: A simple test
---

# Heading

Some markdown content.
''';
      final result = parser.parse(input);

      expect(
          result.frontmatter,
          equals({
            'title': 'Test Title',
            'description': 'A simple test',
          }));

      expect(result.contents, equals('# Heading\n\nSome markdown content.'));
    });

    test('Handles input without frontmatter correctly', () {
      const input = '# Just markdown\n\nNo frontmatter here.';
      final result = parser.parse(input);

      expect(result.frontmatter, isEmpty);
      expect(
          result.contents, equals('# Just markdown\n\nNo frontmatter here.'));
    });

    test('Handles empty frontmatter block correctly', () {
      const input = '''
---
---

Content after empty frontmatter.
''';
      final result = parser.parse(input);

      expect(result.frontmatter, isEmpty);
      expect(result.contents, equals('Content after empty frontmatter.'));
    });

    test('Handles malformed YAML gracefully', () {
      const input = '''
---
title Test Title: malformed YAML
---

Content after malformed YAML.
''';

      final result = parser.parse(input);

      // The YamlUtils.convertYamlToMap function actually parses this as valid YAML
      // with a key of "title Test Title" and value of "malformed YAML"
      expect(result.frontmatter, isNotEmpty);
      expect(result.frontmatter['title Test Title'], equals('malformed YAML'));
      expect(result.contents, equals('Content after malformed YAML.'));
    });

    test('Handles missing closing delimiter', () {
      const input = '''
---
title: Missing delimiter

Content without proper closing delimiter.
''';

      final result = parser.parse(input);

      // With our current implementation, we handle missing delimiters gracefully
      // instead of throwing an exception
      expect(result.frontmatter, isEmpty);
      expect(result.contents,
          contains('Content without proper closing delimiter'));
    });

    test('Handles YAML lists and nested structures', () {
      const input = '''
---
tags:
  - dart
  - parsing
author:
  name: John Doe
  email: john@example.com
---

Content after complex YAML.
''';

      final result = parser.parse(input);

      expect(
          result.frontmatter,
          equals({
            'tags': ['dart', 'parsing'],
            'author': {
              'name': 'John Doe',
              'email': 'john@example.com',
            }
          }));

      expect(result.contents, equals('Content after complex YAML.'));
    });

    test('Handles whitespace correctly', () {
      const input = '''
---
   title:    Whitespace test    
---

   Markdown with leading and trailing whitespace.   
''';

      final result = parser.parse(input);

      expect(
          result.frontmatter,
          equals({
            'title': 'Whitespace test',
          }));

      expect(result.contents,
          equals('Markdown with leading and trailing whitespace.'));
    });
  });

  group('parseFrontMatter Tests', () {
    test('parses frontmatter', () {
      const content = '''---
title: "Sample Document"
author: "John Doe"
tags:
  - example
  - test
---
# Heading
Content goes here.
''';
      final result = parseFrontMatter(content);
      expect(result.yaml, '''title: "Sample Document"
author: "John Doe"
tags:
  - example
  - test''');
      expect(result.markdown, '# Heading\nContent goes here.');
    });

    test('parses frontmatter with no content', () {
      const content = '''---
title: "Empty Document"
author: "Jane Smith"
tags:
  - empty
  - test
---
''';
      final result = parseFrontMatter(content);
      expect(result.yaml, '''title: "Empty Document"
author: "Jane Smith"
tags:
  - empty
  - test''');
      expect(result.markdown, '');
    });

    test('parses frontmatter with single delimiter', () {
      const content = '---';
      final result = parseFrontMatter(content);
      expect(result.yaml, '');
      expect(result.markdown, '');
    });

    test('parses frontmatter with single delimiter and content', () {
      const content = '''
---
# Heading
Content goes here.
''';
      final result = parseFrontMatter(content);
      expect(result.yaml, '');
      expect(result.markdown, '# Heading\nContent goes here.');
    });
  });
}
