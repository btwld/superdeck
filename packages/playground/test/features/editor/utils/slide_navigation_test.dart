import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/editor/utils/slide_navigation.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  /// Builds a document with one [ParagraphNode] per line, returning the doc
  /// alongside the generated node ids so tests can reference them by line.
  ({MutableDocument document, List<String> ids}) docFromLines(
    List<String> lines,
  ) {
    final nodes = [
      for (final line in lines)
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText(line)),
    ];
    return (
      document: MutableDocument(nodes: nodes),
      ids: nodes.map((n) => n.id).toList(),
    );
  }

  group('isSlideSeparator', () {
    test('recognizes bare and whitespace-padded ---', () {
      expect(isSlideSeparator('---'), isTrue);
      expect(isSlideSeparator('  ---  '), isTrue);
    });

    test('rejects non-separator lines', () {
      expect(isSlideSeparator('----'), isFalse);
      expect(isSlideSeparator('- - -'), isFalse);
      expect(isSlideSeparator('# Heading'), isFalse);
      expect(isSlideSeparator(''), isFalse);
    });
  });

  group('slideIndexForNode', () {
    test('maps content before the frontmatter separator to slide 0', () {
      // frontmatter, ---, slide 0 body, ---, slide 1 body
      final d = docFromLines(['title: x', '---', '# A', '---', '# B']);
      expect(slideIndexForNode(d.document, d.ids[0]), 0);
    });

    test('maps content after the first --- to slide 0', () {
      final d = docFromLines(['title: x', '---', '# A', '---', '# B']);
      expect(slideIndexForNode(d.document, d.ids[2]), 0);
    });

    test('maps content after the second --- to slide 1', () {
      final d = docFromLines(['title: x', '---', '# A', '---', '# B']);
      expect(slideIndexForNode(d.document, d.ids[4]), 1);
    });
  });

  group('firstNodeOfSlide', () {
    test('returns the first content node of a slide', () {
      final d = docFromLines(['title: x', '---', '# A', '---', '# B']);
      // Slide 0 begins just after the first separator (index 1) → node index 2.
      expect(firstNodeOfSlide(d.document, 0), d.ids[2]);
      // Slide 1 begins just after the second separator (index 3) → node index 4.
      expect(firstNodeOfSlide(d.document, 1), d.ids[4]);
    });

    test('returns the separator itself when the slide is empty', () {
      // Trailing separator with no content after it.
      final d = docFromLines(['title: x', '---', '# A', '---']);
      expect(firstNodeOfSlide(d.document, 1), d.ids[3]);
    });

    test('returns null when the slide separator does not exist', () {
      final d = docFromLines(['title: x', '---', '# A']);
      expect(firstNodeOfSlide(d.document, 5), isNull);
    });
  });
}
