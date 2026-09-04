import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import 'package:superdeck_builder/src/parsers/section_parser.dart';

void main() {
  final sectionParser = SectionParser();

  group('Basic Parsing', () {
    test('Empty markdown returns no sections', () {
      final sections = sectionParser.parse('');
      expect(sections[0].blocks.length, 1);
    });

    test('Markdown with no tags returns one section with all lines', () {
      const markdown = '''
      # Just some heading
      Some regular text.
      ''';
      final sections = sectionParser.parse(markdown);
      expect(
        sections.length,
        1,
        reason: 'Should create a single default section for plain text.',
      );
      expect(
        sections[0].blocks.length,
        1,
        reason: 'All lines should be in a single block.',
      );
      expect(sections[0].blocks[0].content, markdown);
    });
  });

  group('Section Structure', () {
    test('Section with columns', () {
      const markdown = '''
@section
# Title

@block
content column 1.

@block
content column 2.

''';

      final sections = sectionParser.parse(markdown);
      expect(sections[0].blocks.length, equals(3));
      expect(
        sections[0].blocks[0].content.trim(),
        '# Title',
        reason: 'First block is a title.',
      );
      expect(
        sections[0].blocks[1].content.trim(),
        'content column 1.',
        reason: 'Second block should contain first column content.',
      );
      expect(
        sections[0].blocks[2].content.trim(),
        'content column 2.',
        reason: 'Third block should contain second column content.',
      );
    });

    test('Only columns without sections', () {
      const markdown = '''
@block
Content column 1.

@block
Content column 2.

''';

      final sections = sectionParser.parse(markdown);
      expect(sections[0].blocks.length, equals(2));
      expect(sections[0].blocks[0].content.trim(), 'Content column 1.');
      expect(sections[0].blocks[1].content.trim(), 'Content column 2.');
    });

    test('Legacy @column directives fail loudly', () {
      const markdown = '''
@column
Legacy content.
''';

      expect(
        () => sectionParser.parse(markdown),
        throwsA(
          isA<DeckFormatException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported @column directive'),
          ),
        ),
      );
    });

    test('Columns then sections', () {
      const markdown = '''
# Regular Markdown

This is some regular markdown content.

@section
## Header Title

@block
Content inside the header.
''';

      final sections = sectionParser.parse(markdown);
      expect(sections[0].blocks.length, equals(1));
      expect(sections[1].blocks.length, equals(2));

      expect(
        sections[0].blocks[0].content.trim(),
        '# Regular Markdown\n\nThis is some regular markdown content.',
        reason: 'First section should contain the initial markdown content.',
      );

      expect(sections[1].blocks[0].content.trim(), '## Header Title');
      expect(
        sections[1].blocks[1].content.trim(),
        'Content inside the header.',
      );
    });

    test('Header, body, and footer with columns', () {
      const markdown = '''
@section
# Header Title

@block
Header content column.

@section
@block
Body content column 1.

@block
Body content column 2.

@section
@block
Footer content column.

''';

      final sections = sectionParser.parse(markdown);

      expect(sections[0].blocks.length, equals(2));
      expect(sections[1].blocks.length, equals(2));
      expect(sections[2].blocks.length, equals(1));
      expect(sections[0].blocks[0].content.trim(), '# Header Title');
      expect(sections[0].blocks[1].content.trim(), 'Header content column.');
      expect(sections[1].blocks[0].content.trim(), 'Body content column 1.');
      expect(sections[1].blocks[1].content.trim(), 'Body content column 2.');
      expect(sections[2].blocks[0].content.trim(), 'Footer content column.');
    });
  });

  // 4. Attribute Tests
  group('Attributes', () {
    test('Section spacing is parsed', () {
      const markdown = '''
@section { spacing: 40 }
@block
Left
@block
Right
''';

      final sections = sectionParser.parse(markdown);

      expect(sections.single.toJson()['spacing'], 40);
    });

    group('Column Attributes', () {
      test('Header with columns and flex attribute', () {
        const markdown = '''
@section
@block{
  flex: 1
}
Header content column 1.

@block{
  flex: 2
}
Header content column 2.
''';

        final sections = sectionParser.parse(markdown);
        expect(sections[0].blocks.length, equals(2));
        expect(
          sections[0].blocks[0].content.trim(),
          'Header content column 1.',
        );
        expect(
          sections[0].blocks[1].content.trim(),
          'Header content column 2.',
        );

        expect(
          sections[0].blocks[0].flex,
          equals(1),
          reason: 'First column should have flex=1',
        );
        expect(
          sections[0].blocks[1].flex,
          equals(2),
          reason: 'Second column should have flex=2',
        );
      });

      test('Section with columns and alignment attribute', () {
        const markdown = '''
@section
@block{
      align: center
}
Body content column 1.

@block{
      align: bottomRight
}
Body content column 2.
''';

        final sections = sectionParser.parse(markdown);
        expect(sections[0].blocks.length, equals(2));
        expect(sections[0].blocks[0].content.trim(), 'Body content column 1.');
        expect(sections[0].blocks[1].content.trim(), 'Body content column 2.');

        expect(sections[0].blocks[0].align, equals(ContentAlignment.center));
        expect(
          sections[0].blocks[1].align,
          equals(ContentAlignment.bottomRight),
        );
      });

      test('Section with columns, flex, and alignment attributes', () {
        const markdown = '''
@section
@block{
  flex: 3 
  align: topLeft
}
Footer content column 1.
@block{
  flex: 1
  align: centerRight
}
Footer content column 2.
''';

        final sections = sectionParser.parse(markdown);
        expect(sections[0].blocks.length, equals(2));

        expect(
          sections[0].blocks[0].content.trim(),
          'Footer content column 1.',
        );
        expect(
          sections[0].blocks[1].content.trim(),
          'Footer content column 2.',
        );

        expect(sections[0].blocks[0].flex, equals(3));
        expect(sections[0].blocks[0].align, equals(ContentAlignment.topLeft));

        expect(sections[0].blocks[1].flex, equals(1));
        expect(
          sections[0].blocks[1].align,
          equals(ContentAlignment.centerRight),
        );
      });

      test('Sections with columns and attributes', () {
        const markdown = '''
@section
@block{
    flex: 1
    align: center
}
Header content.

@section
@block{
    flex: 2
    align: centerLeft
}
Body content column 1.

@block{
    flex: 1
    align: centerRight
}
Body content column 2.

@section
@block{
    flex: 1
    align: bottomCenter
}
Footer content.

''';

        final sections = sectionParser.parse(markdown);

        expect(sections[0].blocks.length, equals(1));
        expect(sections[1].blocks.length, equals(2));
        expect(sections[2].blocks.length, equals(1));

        expect(sections[0].blocks[0].content.trim(), 'Header content.');
        expect(sections[0].blocks[0].flex, equals(1));
        expect(sections[0].blocks[0].align, equals(ContentAlignment.center));

        expect(sections[1].blocks[0].content.trim(), 'Body content column 1.');
        expect(sections[1].blocks[0].flex, equals(2));
        expect(
          sections[1].blocks[0].align,
          equals(ContentAlignment.centerLeft),
        );

        expect(sections[1].blocks[1].content.trim(), 'Body content column 2.');
        expect(sections[1].blocks[1].flex, equals(1));
        expect(
          sections[1].blocks[1].align,
          equals(ContentAlignment.centerRight),
        );

        expect(sections[2].blocks[0].content.trim(), 'Footer content.');
        expect(sections[2].blocks[0].flex, equals(1));
        expect(
          sections[2].blocks[0].align,
          equals(ContentAlignment.bottomCenter),
        );
      });
    });

    group('Inheritance', () {
      test('Columns inherit options from the parent', () {
        const markdown = '''
@section {align: center}
@block
Header content.

@section{
  align: topLeft
  flex: 2
}
@block{
  flex: 3
}
Body content.

@section{
  align: bottomRight
  flex: 1
}
@block{ align: bottomRight}
Footer content.

''';

        final sections = sectionParser.parse(markdown);

        expect(sections.length, equals(3));

        expect(
          sections[0].blocks.length,
          equals(1),
          reason: 'First section should have one block.',
        );
        expect(
          sections[1].blocks.length,
          equals(1),
          reason: 'Second section should have one block.',
        );
        expect(
          sections[2].blocks.length,
          equals(1),
          reason: 'Third section should have one block.',
        );

        expect(sections[0].blocks[0].content.trim(), 'Header content.');
        expect(
          sections[0].align,
          equals(ContentAlignment.center),
          reason: 'Should inherit center alignment from parent.',
        );

        expect(sections[1].blocks[0].content.trim(), 'Body content.');
        expect(sections[1].align, equals(ContentAlignment.topLeft));
        expect(
          sections[1].blocks[0].flex,
          equals(3),
          reason:
              'Column should have its own flex overriding or complementing parent.',
        );

        expect(sections[2].blocks[0].content.trim(), 'Footer content.');
        expect(sections[2].align, equals(ContentAlignment.bottomRight));
        expect(sections[2].flex, equals(1));
      });
    });

    group('Failure Cases', () {
      for (final flex in [0, -1]) {
        test('Non-positive block flex $flex is rejected', () {
          expect(
            () => sectionParser.parse(
              '@section\n@block { flex: $flex }\nContent',
            ),
            throwsA(anything),
          );
        });

        test('Non-positive section flex $flex is rejected', () {
          expect(
            () => sectionParser.parse(
              '@section { flex: $flex }\n@block\nContent',
            ),
            throwsA(anything),
          );
        });
      }

      test('Invalid flex attribute format', () {
        const markdown = '''
@section
@block{ flex: invalid}
Header content.

''';
        expect(
          () => sectionParser.parse(markdown),
          throwsA(isA<Exception>()),
          reason: 'Invalid flex value should throw an exception.',
        );
      });

      test('Invalid alignment attribute value', () {
        const markdown = '''
@section
@block{
  align: invalid_alignment
}
Header content.

''';

        expect(
          () => sectionParser.parse(markdown),
          throwsA(isA<Exception>()),
          reason: 'Invalid alignment value should throw an exception.',
        );
      });

      test('Section-level scrollable is rejected', () {
        const markdown = '''
@section { scrollable: true }
@block
Header content.

''';

        expect(
          () => sectionParser.parse(markdown),
          throwsA(isA<Exception>()),
          reason: 'Scrollable should be set on child blocks, not sections.',
        );
      });
    });
  });
}

extension on Block {
  String get content => (this as ContentBlock).content;
}
