import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../helpers/slide_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlideSpec markdown spacing', () {
    test('disables flutter_markdown_plus implicit block spacing', () {
      expect(const SlideSpec().toStyle().blockSpacing, 0);
    });

    testWidgets('default slide style owns the block spacing', (tester) async {
      await SlideTestHarness.pumpSlide(
        tester,
        Slide(
          key: 'markdown-spacing',
          sections: [
            SectionBlock([ContentBlock('## Heading\n\nParagraph')]),
          ],
        ),
      );

      final markdown = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      final heading = tester.getRect(find.text('Heading'));
      final paragraph = tester.getRect(find.text('Paragraph'));

      expect(markdown.styleSheet!.blockSpacing, 12);
      expect(paragraph.top - heading.bottom, closeTo(24, 0.1));
    });

    testWidgets('deck styles can override the default spacing', (tester) async {
      await SlideTestHarness.pumpSlide(
        tester,
        Slide(
          key: 'custom-markdown-spacing',
          sections: [
            SectionBlock([ContentBlock('## Heading\n\nParagraph')]),
          ],
        ),
        style: defaultSlideStyle.merge(SlideStyler(blockSpacing: 20)),
      );

      final markdown = tester.widget<MarkdownBody>(find.byType(MarkdownBody));

      expect(markdown.styleSheet!.blockSpacing, 20);
    });
  });
}
