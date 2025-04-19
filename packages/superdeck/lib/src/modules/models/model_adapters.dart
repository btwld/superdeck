import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Base class for slide elements
sealed class SlideElement {
  final String type;
  final ContentAlignment? align;
  final int? flex;
  final bool? scrollable;

  SlideElement({
    required this.type,
    this.align,
    this.flex,
    this.scrollable,
  });

  /// Create a SlideElement from a BaseBlock
  factory SlideElement.fromBlock(BaseBlock block) {
    if (block is SectionBlock) {
      return SlideSection.fromBlock(block);
    } else if (block is MarkdownBlock) {
      return MarkdownElement.fromBlock(block);
    } else if (block is ImageBlock) {
      return ImageElement.fromBlock(block);
    } else if (block is DartPadBlock) {
      return DartPadElement.fromBlock(block);
    } else if (block is WidgetBlock) {
      return CustomElement.fromBlock(block);
    } else {
      return CustomElement(
        id: 'unknown',
        type: block.type,
        align: block.align,
        flex: block.flex,
        scrollable: block.scrollable,
      );
    }
  }
}

/// A section that contains child elements
class SlideSection extends SlideElement {
  final List<SlideElement> blocks;

  SlideSection({
    required super.type,
    required this.blocks,
    super.align,
    super.flex,
    super.scrollable,
  });

  /// Create a SlideSection from a SectionBlock
  factory SlideSection.fromBlock(SectionBlock block) {
    return SlideSection(
      type: block.type,
      blocks: block.blocks.map((b) => SlideElement.fromBlock(b)).toList(),
      align: block.align,
      flex: block.flex,
      scrollable: block.scrollable,
    );
  }
}

/// A markdown content element
class MarkdownElement extends SlideElement {
  final String content;

  MarkdownElement({
    required super.type,
    required this.content,
    super.align,
    super.flex,
    super.scrollable,
  });

  /// Create a MarkdownElement from a MarkdownBlock
  factory MarkdownElement.fromBlock(MarkdownBlock block) {
    return MarkdownElement(
      type: block.type,
      content: block.content,
      align: block.align,
      flex: block.flex,
      scrollable: block.scrollable,
    );
  }
}

/// An image element
class ImageElement extends SlideElement {
  final Asset asset;
  final ImageFit? fit;
  final double? width;
  final double? height;

  ImageElement({
    required super.type,
    required this.asset,
    this.fit,
    this.width,
    this.height,
    super.align,
    super.flex,
    super.scrollable,
  });

  /// Create an ImageElement from an ImageBlock
  factory ImageElement.fromBlock(ImageBlock block) {
    return ImageElement(
      type: block.type,
      asset: block.asset,
      fit: block.fit,
      width: block.width,
      height: block.height,
      align: block.align,
      flex: block.flex,
      scrollable: block.scrollable,
    );
  }
}

/// A custom widget element
class CustomElement extends SlideElement {
  final String id;
  final Map<String, dynamic>? props;

  CustomElement({
    required this.id,
    required super.type,
    this.props,
    super.align,
    super.flex,
    super.scrollable,
  });

  /// Create a CustomElement from a WidgetBlock
  factory CustomElement.fromBlock(WidgetBlock block) {
    return CustomElement(
      id: block.id,
      type: block.type,
      props: block.props,
      align: block.align,
      flex: block.flex,
      scrollable: block.scrollable,
    );
  }
}

/// A DartPad element
class DartPadElement extends SlideElement {
  final String id;
  final DartPadTheme? theme;
  final bool? embed;
  final bool? run;

  DartPadElement({
    required super.type,
    required this.id,
    this.theme,
    this.embed,
    this.run,
    super.align,
    super.flex,
    super.scrollable,
  });

  /// Create a DartPadElement from a DartPadBlock
  factory DartPadElement.fromBlock(DartPadBlock block) {
    return DartPadElement(
      type: block.type,
      id: block.id,
      theme: block.theme,
      embed: block.embed,
      run: block.run,
      align: block.align,
      flex: block.flex,
      scrollable: block.scrollable,
    );
  }

  /// Get the DartPad URL
  String getDartPadUrl() {
    return 'https://dartpad.dev/?id=$id&theme=$theme&embed=$embed&run=$run';
  }
}

/// Type for widget block builders
typedef WidgetBlockBuilder = Widget Function(Map<String, dynamic>? props);
