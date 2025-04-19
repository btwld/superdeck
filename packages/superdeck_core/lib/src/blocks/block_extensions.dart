import 'package:superdeck_core/src/blocks/base_block.dart';
import 'package:superdeck_core/src/blocks/dartpad_block.dart' as dartpad;
import 'package:superdeck_core/src/blocks/image_block.dart' as image;
import 'package:superdeck_core/src/blocks/markdown_block.dart';
import 'package:superdeck_core/src/blocks/section_block.dart' as section;
import 'package:superdeck_core/src/blocks/widget_block.dart' as widget;

/// Extension methods for BaseBlock
extension BaseBlockExt on BaseBlock {
  // Type check helpers
  bool isMarkdownBlock() => this is MarkdownBlock;
  bool isSectionBlock() => this is section.SectionBlock;
  bool isImageBlock() => this is image.ImageBlock;
  bool isDartPadBlock() => this is dartpad.DartPadBlock;
  bool isWidgetBlock() => this is widget.WidgetBlock;

  // Type cast helpers
  MarkdownBlock asMarkdownBlock() => this as MarkdownBlock;
  section.SectionBlock asSectionBlock() => this as section.SectionBlock;
  image.ImageBlock asImageBlock() => this as image.ImageBlock;
  dartpad.DartPadBlock asDartPadBlock() => this as dartpad.DartPadBlock;
  widget.WidgetBlock asWidgetBlock() => this as widget.WidgetBlock;

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return toJson() as Map<String, dynamic>;
  }
}

/// Extension methods for String
extension StringMarkdownExt on String {
  /// Create a MarkdownBlock from a string
  MarkdownBlock toMarkdownBlock({
    ContentAlignment? align,
    int? flex,
    bool? scrollable,
  }) {
    return MarkdownBlock(
      this,
      align: align,
      flex: flex,
      scrollable: scrollable,
    );
  }
}
