import 'dart:math' as math;

import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../deck/slide_configuration.dart';
import '../../styling/block_variant.dart';
import '../../styling/components/slide.dart';
import '../../ui/widgets/error_widgets.dart';
import '../../ui/widgets/overflow_clip.dart';
import '../../ui/widgets/provider.dart';
import '../../utils/converters.dart';
import 'block_provider.dart';
import 'markdown_viewer.dart';

/// Private container widget that provides shared block infrastructure.
///
/// Handles sizing, styling, scrolling, alignment, and debug borders for all block types.
class _BlockContainer extends StatefulWidget {
  const _BlockContainer({
    required this.block,
    required this.align,
    required this.size,
    required this.configuration,
    required this.runtimeKey,
    required this.child,
  });

  final Block block;
  final ContentAlignment align;
  final Size size;
  final SlideConfiguration configuration;
  final String runtimeKey;
  final Widget child;

  @override
  State<_BlockContainer> createState() => _BlockContainerState();
}

class _BlockContainerState extends State<_BlockContainer> {
  /// Applies per-block `margin`/`padding` overrides onto the resolved block
  /// container after variants resolve.
  ///
  /// An absent override retains the resolved style inset; an explicit zero
  /// removes it. Only the matching inset is replaced — decoration, foreground
  /// decoration, clipping, and animation are preserved.
  SlideSpec _applyBlockInsets(SlideSpec spec, Block block) {
    if (block.margin == null && block.padding == null) return spec;

    final container = spec.blockContainer;

    return spec.copyWith(
      blockContainer: container.copyWith(
        spec: container.spec.copyWith(
          margin: block.margin?.toEdgeInsets,
          padding: block.padding?.toEdgeInsets,
        ),
      ),
    );
  }

  @override
  Widget build(context) {
    // Widget blocks resolve their style inside [BlockVariantScope] so a named
    // block variant affects both the rendered container and its child size.
    final resolvedSpec = switch (widget.block) {
      WidgetBlock() => widget.configuration.style.resolve(context).spec,
      ContentBlock() => SlideSpec.of(context),
    };
    final spec = _applyBlockInsets(resolvedSpec, widget.block);

    final blockOffset = spec.blockContainer.spec.calculateBlockOffset;

    final blockData = BlockConfiguration(
      align: widget.align,
      spec: spec,
      size: Size(
        math.max(0.0, widget.size.width - blockOffset.dx),
        math.max(0.0, widget.size.height - blockOffset.dy),
      ),
      runtimeKey: widget.runtimeKey,
    );

    Widget content = InheritedData(
      data: blockData,
      child: Box(styleSpec: spec.blockContainer, child: widget.child),
    );

    content = OverflowClip(
      scrollable:
          widget.block.scrollable && !widget.configuration.isStaticRendering,
      child: content,
    );

    content = Align(alignment: widget.align.toAlignment, child: content);

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

/// Helper widget for content block children to access BlockConfiguration context.
class _ContentBlockChild extends StatelessWidget {
  const _ContentBlockChild({
    required this.content,
    required this.diagnosticsEnabled,
  });

  final String content;
  final bool diagnosticsEnabled;

  @override
  Widget build(BuildContext context) {
    final data = BlockConfiguration.of(context);
    final slide = SlideConfiguration.of(context);
    final markdown = MarkdownViewer(
      content: content,
      spec: data.spec,
      duration: slide.isStaticRendering
          ? Duration.zero
          : const Duration(milliseconds: 250),
    );
    if (!diagnosticsEnabled) return markdown;

    return OverflowDiagnosticProbe(
      slideKey: slide.key,
      runtimeKey: data.runtimeKey,
      availableSize: data.size,
      child: markdown,
    );
  }
}

/// Helper widget for custom block children to access BlockConfiguration context.
class _CustomBlockChild extends StatelessWidget {
  const _CustomBlockChild({required this.block});

  final WidgetBlock block;

  @override
  Widget build(BuildContext context) {
    final slide = SlideConfiguration.of(context);
    final data = BlockConfiguration.of(context);
    final factory = slide.getWidgetFactory(block.name);

    if (factory == null) {
      return ErrorWidgets.simple('Widget not found: ${block.name}');
    }

    try {
      final child = factory(block.args);
      if (block.scrollable && !slide.isStaticRendering) {
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: data.size.height),
          child: child,
        );
      }

      if (block.scrollable && slide.isStaticRendering) {
        return SizedBox(
          height: data.size.height,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: data.size.height,
              maxHeight: double.infinity,
              child: child,
            ),
          ),
        );
      }

      return SizedBox(height: data.size.height, child: child);
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
    required this.align,
    required this.size,
    required this.configuration,
    required this.runtimeKey,
  });

  final ContentBlock block;
  final ContentAlignment align;
  final Size size;
  final SlideConfiguration configuration;
  final String runtimeKey;

  @override
  Widget build(BuildContext context) {
    return _BlockContainer(
      block: block,
      align: align,
      size: size,
      configuration: configuration,
      runtimeKey: runtimeKey,
      child: _ContentBlockChild(
        content: block.content,
        diagnosticsEnabled:
            configuration.debug &&
            !configuration.isStaticRendering &&
            !block.scrollable,
      ),
    );
  }
}

/// Custom widget block that renders user-defined widgets.
class CustomBlockWidget extends StatelessWidget {
  const CustomBlockWidget({
    super.key,
    required this.block,
    required this.align,
    required this.size,
    required this.configuration,
    required this.runtimeKey,
  });

  final WidgetBlock block;
  final ContentAlignment align;
  final Size size;
  final SlideConfiguration configuration;
  final String runtimeKey;

  @override
  Widget build(BuildContext context) {
    return BlockVariantScope(
      name: block.name,
      child: _BlockContainer(
        block: block,
        align: align,
        size: size,
        configuration: configuration,
        runtimeKey: runtimeKey,
        child: _CustomBlockChild(block: block),
      ),
    );
  }
}

/// Section widget that layouts child blocks horizontally.
class SectionWidget extends StatelessWidget {
  const SectionWidget({
    super.key,
    required this.section,
    required this.size,
    required this.sectionIndex,
  });

  final SectionBlock section;
  final Size size;
  final int sectionIndex;

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
    final gapCount = math.max(0, section.blocks.length - 1);
    final actualSpacing = gapCount == 0
        ? 0.0
        : math.min(section.spacing, size.width / gapCount);
    final availableWidth = math.max(0.0, size.width - actualSpacing * gapCount);
    final totalFlex = section.totalBlockFlex;
    final flexUnit = totalFlex == 0 ? 0.0 : availableWidth / totalFlex;

    double leftOffset = 0;
    final children = <Widget>[];

    for (var blockIndex = 0; blockIndex < section.blocks.length; blockIndex++) {
      final block = section.blocks[blockIndex];
      final align = section.resolveBlockAlign(block);
      final blockWidth = flexUnit * block.flex;
      final blockSize = Size(blockWidth, size.height);
      final runtimeKey = buildBlockRuntimeKey(
        configuration.key,
        sectionIndex,
        blockIndex,
      );

      Widget blockWidget = switch (block) {
        WidgetBlock b => CustomBlockWidget(
          block: b,
          align: align,
          size: blockSize,
          configuration: configuration,
          runtimeKey: runtimeKey,
        ),
        ContentBlock b => BlockWidget(
          block: b,
          align: align,
          size: blockSize,
          configuration: configuration,
          runtimeKey: runtimeKey,
        ),
      };

      // Add debug info overlay if needed
      if (configuration.debug) {
        blockWidget = Stack(
          children: [blockWidget, _renderDebugInfo(block, blockSize)],
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
      if (blockIndex < section.blocks.length - 1) {
        leftOffset += actualSpacing;
      }
    }

    return Stack(children: children);
  }
}
