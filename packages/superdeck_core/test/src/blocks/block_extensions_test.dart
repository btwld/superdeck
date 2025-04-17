import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('BaseBlockExt', () {
    test('type check helpers should work correctly', () {
      final markdownBlock = MarkdownBlock('Test content');
      final sectionBlock = SectionBlock([]);
      final imageBlock = ImageBlock(
        asset: Asset(
          id: 'test',
          extension: AssetExtension.png,
          type: AssetType.image,
        ),
      );
      final dartpadBlock = DartPadBlock(id: 'test_id');
      final widgetBlock = WidgetBlock(id: 'test_widget');

      // Markdown block checks
      expect(markdownBlock.isMarkdownBlock, true);
      expect(markdownBlock.isSectionBlock, false);
      expect(markdownBlock.isImageBlock, false);
      expect(markdownBlock.isDartPadBlock, false);
      expect(markdownBlock.isWidgetBlock, false);

      // Section block checks
      expect(sectionBlock.isMarkdownBlock, false);
      expect(sectionBlock.isSectionBlock, true);
      expect(sectionBlock.isImageBlock, false);
      expect(sectionBlock.isDartPadBlock, false);
      expect(sectionBlock.isWidgetBlock, false);

      // Image block checks
      expect(imageBlock.isMarkdownBlock, false);
      expect(imageBlock.isSectionBlock, false);
      expect(imageBlock.isImageBlock, true);
      expect(imageBlock.isDartPadBlock, false);
      expect(imageBlock.isWidgetBlock, false);

      // DartPad block checks
      expect(dartpadBlock.isMarkdownBlock, false);
      expect(dartpadBlock.isSectionBlock, false);
      expect(dartpadBlock.isImageBlock, false);
      expect(dartpadBlock.isDartPadBlock, true);
      expect(dartpadBlock.isWidgetBlock, false);

      // Widget block checks
      expect(widgetBlock.isMarkdownBlock, false);
      expect(widgetBlock.isSectionBlock, false);
      expect(widgetBlock.isImageBlock, false);
      expect(widgetBlock.isDartPadBlock, false);
      expect(widgetBlock.isWidgetBlock, true);
    });

    test('type cast helpers should return correct blocks or null', () {
      final markdownBlock = MarkdownBlock('Test content');
      final sectionBlock = SectionBlock([]);

      expect(markdownBlock.asMarkdownBlock, equals(markdownBlock));
      expect(markdownBlock.asSectionBlock, isNull);
      expect(markdownBlock.asImageBlock, isNull);
      expect(markdownBlock.asDartPadBlock, isNull);
      expect(markdownBlock.asWidgetBlock, isNull);

      expect(sectionBlock.asMarkdownBlock, isNull);
      expect(sectionBlock.asSectionBlock, equals(sectionBlock));
      expect(sectionBlock.asImageBlock, isNull);
      expect(sectionBlock.asDartPadBlock, isNull);
      expect(sectionBlock.asWidgetBlock, isNull);
    });

    test('toJson should convert to JSON string', () {
      final block = MarkdownBlock('Test content');
      final json = block.toJson();

      expect(json, isA<String>());
      expect(json, contains('"type":"column"'));
      expect(json, contains('"content":"Test content"'));
    });

    test('alignment helpers should set correct alignments', () {
      final block = MarkdownBlock('Test');

      expect(block.alignTopLeft().align, ContentAlignment.topLeft);
      expect(block.alignTopCenter().align, ContentAlignment.topCenter);
      expect(block.alignTopRight().align, ContentAlignment.topRight);
      expect(block.alignCenterLeft().align, ContentAlignment.centerLeft);
      expect(block.alignCenter().align, ContentAlignment.center);
      expect(block.alignCenterRight().align, ContentAlignment.centerRight);
      expect(block.alignBottomLeft().align, ContentAlignment.bottomLeft);
      expect(block.alignBottomCenter().align, ContentAlignment.bottomCenter);
      expect(block.alignBottomRight().align, ContentAlignment.bottomRight);
    });

    test('makeScrollable() should set scrollable to true', () {
      final block = MarkdownBlock('Test');
      expect(block.scrollable, isNull);

      final blockWithScrolling = block.makeScrollable();
      expect(blockWithScrolling.scrollable, true);
    });

    test('withFlex() should set the flex value', () {
      final block = MarkdownBlock('Test');
      expect(block.flex, isNull);

      final flexBlock = block.withFlex(3);
      expect(flexBlock.flex, 3);
    });
  });

  group('StringMarkdownExt', () {
    test('toMarkdownBlock should create a markdown block from string', () {
      const markdownText = '# Hello world';
      final block = markdownText.toMarkdownBlock();

      expect(block, isA<MarkdownBlock>());
      expect(block.content, '# Hello world');
      expect(block.align, isNull);
      expect(block.flex, isNull);
      expect(block.scrollable, isNull);
    });

    test('toMarkdownBlock should honor optional parameters', () {
      const markdownText = '# Hello world';
      final block = markdownText.toMarkdownBlock(
        align: ContentAlignment.center,
        flex: 2,
        scrollable: true,
      );

      expect(block, isA<MarkdownBlock>());
      expect(block.content, '# Hello world');
      expect(block.align, ContentAlignment.center);
      expect(block.flex, 2);
      expect(block.scrollable, true);
    });
  });
}
