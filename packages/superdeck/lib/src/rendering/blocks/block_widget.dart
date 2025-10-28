import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../deck/slide_configuration.dart';
import '../../styling/styles.dart';
import '../../ui/widgets/error_widgets.dart';
import '../../ui/widgets/provider.dart';
import '../../utils/converters.dart';
import 'markdown_viewer.dart';

/// Private container widget that provides shared block infrastructure.
///
/// Handles sizing, styling, scrolling, alignment, and debug borders for all block types.
class _BlockContainer extends StatefulWidget {
  const _BlockContainer({
    required this.block,
    required this.size,
    required this.configuration,
    required this.child,
  });

  final Block block;
  final Size size;
  final SlideConfiguration configuration;
  final Widget child;

  @override
  State<_BlockContainer> createState() => _BlockContainerState();
}

class _BlockContainerState extends State<_BlockContainer> {
  @override
  Widget build(context) {
    // Get the resolved SlideSpec (provided by SlideView)
    final spec = SlideSpec.of(context);

    final blockOffset = ConverterHelper.calculateBlockOffset(
      spec.blockContainer.spec,
    );

    final blockData = BlockData(
      block: widget.block,
      spec: spec,
      size: Size(
        math.max(0.0, widget.size.width - blockOffset.dx),
        math.max(0.0, widget.size.height - blockOffset.dy),
      ),
    );

    Widget content = InheritedData(
      data: blockData,
      child: Box(
        styleSpec: spec.blockContainer,
        child: widget.child,
      ),
    );

    // Apply scrolling or wrap (for clipping non-scrollable content)
    final shouldScroll = widget.block.scrollable && !widget.configuration.isExporting;
    content = shouldScroll
        ? SingleChildScrollView(child: content)
        : Wrap(clipBehavior: Clip.hardEdge, children: [content]);

    // Apply alignment
    content = Align(
      alignment: ConverterHelper.toAlignment(widget.block.align),
      child: content,
    );

    // Apply size constraints
    content = ConstrainedBox(
      constraints: BoxConstraints.loose(widget.size),
      child: content,
    );

    // Add debug border if needed
    if (widget.configuration.debug) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.cyan, width: 2),
        ),
        child: content,
      );
    }

    return content;
  }
}

/// Helper widget for content block children to access BlockData context.
class _ContentBlockChild extends StatelessWidget {
  const _ContentBlockChild({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final data = BlockData.of(context);
    return MarkdownViewer(content: content, spec: data.spec);
  }
}

/// Helper widget for custom block children to access BlockData context.
class _CustomBlockChild extends StatelessWidget {
  const _CustomBlockChild({required this.block});

  final WidgetBlock block;

  @override
  Widget build(BuildContext context) {
    final slide = SlideConfiguration.of(context);
    final data = BlockData.of(context);
    final widgetDef = slide.getWidgetDefinition(block.name);

    if (widgetDef == null) {
      return ErrorWidgets.simple('Widget not found: ${block.name}');
    }

    try {
      final typedArgs = widgetDef.parse(block.args);
      return SizedBox(
        height: data.size.height,
        child: widgetDef.build(context, typedArgs),
      );
    } catch (e, stackTrace) {
      return ErrorWidgets.detailed(
        'Error building widget: ${block.name}',
        '$e\n\n$stackTrace',
      );
    }
  }
}

/// Default block widget that renders markdown content.
class BlockWidget extends StatelessWidget {
  const BlockWidget({
    super.key,
    required this.block,
    required this.size,
    required this.configuration,
  });

  final ContentBlock block;
  final Size size;
  final SlideConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    return _BlockContainer(
      block: block,
      size: size,
      configuration: configuration,
      child: _ContentBlockChild(content: block.content),
    );
  }
}

/// Custom widget block that renders user-defined widgets.
class CustomBlockWidget extends StatelessWidget {
  const CustomBlockWidget({
    super.key,
    required this.block,
    required this.size,
    required this.configuration,
  });

  final WidgetBlock block;
  final Size size;
  final SlideConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    return _BlockContainer(
      block: block,
      size: size,
      configuration: configuration,
      child: _CustomBlockChild(block: block),
    );
  }
}

/// Section widget that layouts child blocks horizontally.
class SectionWidget extends StatelessWidget {
  const SectionWidget({
    super.key,
    required this.section,
    required this.size,
  });

  final SectionBlock section;
  final Size size;

  Positioned _renderDebugInfo(Block block, Size size) {
    const textStyle = TextStyle(color: Colors.black, fontSize: 12);
    final label =
        '''
@${block.type}
${size.width.toStringAsFixed(2)} x ${size.height.toStringAsFixed(2)}''';

    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        color: Colors.cyan,
        padding: const EdgeInsets.all(8),
        child: Text(label, style: textStyle),
      ),
    );
  }

  @override
  Widget build(context) {
    final configuration = SlideConfiguration.of(context);
    final flexUnit = size.width / section.totalBlockFlex;

    double leftOffset = 0;
    final children = <Widget>[];

    for (final block in section.blocks) {
      final blockWidth = flexUnit * block.flex;
      final blockSize = Size(blockWidth, size.height);

      Widget blockWidget = switch (block) {
        WidgetBlock b => CustomBlockWidget(
          block: b,
          size: blockSize,
          configuration: configuration,
        ),
        ContentBlock b => BlockWidget(
          block: b,
          size: blockSize,
          configuration: configuration,
        ),
        _ => const SizedBox.shrink(),
      };

      // Add debug info overlay if needed
      if (configuration.debug) {
        blockWidget = Stack(
          children: [
            blockWidget,
            _renderDebugInfo(block, blockSize),
          ],
        );
      }

      children.add(
        Positioned(
          left: leftOffset,
          top: 0,
          width: blockSize.width,
          height: blockSize.height,
          child: blockWidget,
        ),
      );

      leftOffset += blockWidth;
    }

    return Stack(children: children);
  }
}
