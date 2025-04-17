import 'package:superdeck_core/src/blocks/base_block.dart';
import 'package:superdeck_core/src/blocks/dartpad_block.dart' as dartpad;
import 'package:superdeck_core/src/blocks/image_block.dart' as image;
import 'package:superdeck_core/src/blocks/markdown_block.dart' as markdown;
import 'package:superdeck_core/src/blocks/section_block.dart' as section;
import 'package:superdeck_core/src/blocks/widget_block.dart' as widget;

/// Extensions for BaseBlock
extension BaseBlockExt on BaseBlock {
  /// Type check helpers
  bool get isMarkdownBlock => this is markdown.MarkdownBlock;
  bool get isSectionBlock => this is section.SectionBlock;
  bool get isImageBlock => this is image.ImageBlock;
  bool get isDartPadBlock => this is dartpad.DartPadBlock;
  bool get isWidgetBlock => this is widget.WidgetBlock;

  /// Type cast helpers
  markdown.MarkdownBlock? get asMarkdownBlock =>
      this is markdown.MarkdownBlock ? this as markdown.MarkdownBlock : null;
  section.SectionBlock? get asSectionBlock =>
      this is section.SectionBlock ? this as section.SectionBlock : null;
  image.ImageBlock? get asImageBlock =>
      this is image.ImageBlock ? this as image.ImageBlock : null;
  dartpad.DartPadBlock? get asDartPadBlock =>
      this is dartpad.DartPadBlock ? this as dartpad.DartPadBlock : null;
  widget.WidgetBlock? get asWidgetBlock =>
      this is widget.WidgetBlock ? this as widget.WidgetBlock : null;

  /// Convert to a JSON compatible map
  Map<String, dynamic> toJson() => toMap();

  /// Alignment helper methods
  BaseBlock align(ContentAlignment alignment) => copyWith(align: alignment);
  BaseBlock alignTopLeft() => align(ContentAlignment.topLeft);
  BaseBlock alignTopCenter() => align(ContentAlignment.topCenter);
  BaseBlock alignTopRight() => align(ContentAlignment.topRight);
  BaseBlock alignCenterLeft() => align(ContentAlignment.centerLeft);
  BaseBlock alignCenter() => align(ContentAlignment.center);
  BaseBlock alignCenterRight() => align(ContentAlignment.centerRight);
  BaseBlock alignBottomLeft() => align(ContentAlignment.bottomLeft);
  BaseBlock alignBottomCenter() => align(ContentAlignment.bottomCenter);
  BaseBlock alignBottomRight() => align(ContentAlignment.bottomRight);

  /// Make block scrollable
  BaseBlock makeScrollable() => copyWith(scrollable: true);

  /// Set flex value
  BaseBlock withFlex(int value) => copyWith(flex: value);
}

/// Extension for creating MarkdownBlock from String
extension StringMarkdownExt on String {
  /// Create a MarkdownBlock from a string
  markdown.MarkdownBlock toMarkdownBlock({
    ContentAlignment? align,
    int? flex,
    bool? scrollable,
  }) {
    return markdown.MarkdownBlock(
      this,
      align: align,
      flex: flex,
      scrollable: scrollable,
    );
  }
}
