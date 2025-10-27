import 'dart:math' as math;

import 'package:collection/collection.dart';
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

sealed class BlockWidget<T extends Block> extends StatefulWidget {
  /// Calculates the block offset from padding, margin, and border.
  ///
  /// This is used to determine the actual content size available within a block
  /// after accounting for the box decoration spacing.
  static Offset calculateBlockOffset(BoxSpec spec) {
    final padding = spec.padding ?? EdgeInsets.zero;
    final margin = spec.margin ?? EdgeInsets.zero;

    double horizontalBorder = 0.0;
    double verticalBorder = 0.0;

    if (spec.decoration is BoxDecoration) {
      final border = (spec.decoration as BoxDecoration).border;
      if (border != null) {
        horizontalBorder = border.dimensions.horizontal;
        verticalBorder = border.dimensions.vertical;
      }
    }

    return Offset(
      padding.horizontal + margin.horizontal + horizontalBorder,
      padding.vertical + margin.vertical + verticalBorder,
    );
  }

  const BlockWidget({
    super.key,
    required this.block,
    required this.size,
    required this.configuration,
  });

  Widget build(BuildContext context, BlockData data);

  final T block;
  final Size size;
  final SlideConfiguration configuration;
  @override
  State<BlockWidget<T>> createState() => _BlockWidgetState<T>();
}

class _BlockWidgetState<T extends Block> extends State<BlockWidget<T>> {
  @override
  Widget build(context) {
    // Get the resolved SlideSpec (provided by SlideView)
    final spec = SlideSpec.of(context);

    final blockOffset = BlockWidget.calculateBlockOffset(
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

    Widget current = InheritedData(
      data: blockData,
      child: Box(
        styleSpec: spec.blockContainer,
        child: widget.build(context, blockData),
      ),
    );

    final shouldScroll = widget.block.scrollable && !widget.configuration.isExporting;
    current = shouldScroll
        ? SingleChildScrollView(child: current)
        : Wrap(clipBehavior: Clip.hardEdge, children: [current]);

    final decoration = widget.configuration.debug
        ? BoxDecoration(border: Border.all(color: Colors.cyan, width: 2))
        : null;

    return Container(
      decoration: decoration,
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(widget.size),
        child: Stack(
          children: [
            Align(
              alignment: ConverterHelper.toAlignment(widget.block.align),
              child: current,
            ),
          ],
        ),
      ),
    );
  }
}

class ColumnBlockWidget extends BlockWidget<ColumnBlock> {
  const ColumnBlockWidget({
    super.key,
    required super.block,
    required super.size,
    required super.configuration,
  });

  @override
  Widget build(context, data) {
    final block = data.block as ColumnBlock;
    return MarkdownViewer(content: block.content, spec: data.spec);
  }
}

/// Renders an ImageBlock from YAML configuration.
///
class WidgetBlockWidget extends BlockWidget<WidgetBlock> {
  const WidgetBlockWidget({
    super.key,
    required super.block,
    required super.size,
    required super.configuration,
  });

  @override
  Widget build(context, data) {
    final slide = SlideConfiguration.of(context);
    final block = data.block as WidgetBlock;

    final widgetDef = slide.getWidgetDefinition(block.name);

    if (widgetDef == null) {
      return ErrorWidgets.simple('Widget not found: ${block.name}');
    }

    return Builder(
      builder: (context) {
        try {
          // Parse arguments to typed, validated args object
          final typedArgs = widgetDef.parse(block.args);

          return SizedBox(
            height: data.size.height,
            child: widgetDef.build(context, typedArgs),
          );
        } catch (e, stackTrace) {
          // Catch validation errors and build errors
          return ErrorWidgets.detailed(
            'Error building widget: ${block.name}',
            '$e\n\n$stackTrace',
          );
        }
      },
    );
  }
}

class SectionBlockWidget extends StatelessWidget {
  const SectionBlockWidget({
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
    final blockLeftOffset = List.filled(section.blocks.length, 0.0);
    double cumulativeLeftOffset = 0;
    final widthPerFlex = size.width / section.totalBlockFlex;
    // get index
    for (var index = 0; index < section.blocks.length; index++) {
      final block = section.blocks[index];
      final blockWidth = widthPerFlex * block.flex;
      blockLeftOffset[index] = cumulativeLeftOffset;
      cumulativeLeftOffset = cumulativeLeftOffset + blockWidth;
    }

    final configuration = SlideConfiguration.of(context);

    return Stack(
      children: section.blocks.mapIndexed((index, block) {
        final widthPercentage = block.flex / section.totalBlockFlex;

        final blockSize = Size(size.width * widthPercentage, size.height);

        return Positioned(
          left: blockLeftOffset[index],
          top: 0,
          width: blockSize.width,
          height: blockSize.height,
          child: Stack(
            children: [
              switch (block) {
                WidgetBlock b => WidgetBlockWidget(
                  block: b,
                  size: blockSize,
                  configuration: configuration,
                ),
                ColumnBlock b => ColumnBlockWidget(
                  block: b,
                  size: blockSize,
                  configuration: configuration,
                ),
                _ => const SizedBox.shrink(),
              },
              if (configuration.debug) _renderDebugInfo(block, blockSize),
            ],
          ),
        );
      }).toList(),
    );
  }
}
