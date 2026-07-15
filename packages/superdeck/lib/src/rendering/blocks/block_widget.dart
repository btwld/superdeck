import 'dart:math' as math;

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
import '../layout_debug_overlay.dart';
import 'block_provider.dart';
import 'markdown_viewer.dart';

/// Private container widget that provides shared block infrastructure.
///
/// Handles sizing, styling, scrolling, alignment, and debug borders for all block types.
class _BlockContainer extends StatefulWidget {
  const _BlockContainer({
    required this.block,
    required this.align,
    required this.configuration,
    required this.runtimeKey,
    required this.child,
  });

  final Block block;
  final ContentAlignment align;
  final SlideConfiguration configuration;
  final String runtimeKey;
  final Widget child;

  @override
  State<_BlockContainer> createState() => _BlockContainerState();
}

class _BlockContainerState extends State<_BlockContainer> {
  /// Removes geometry that the framework-owned block frame does not delegate
  /// to styles.
  ///
  /// `BlockStyler` makes these properties unavailable through the public
  /// authoring API. This render-boundary guard also covers low-level
  /// [SlideStyler.create] and direct [SlideSpec] construction.
  SlideSpec _sanitizeBlockContainer(SlideSpec spec) {
    final container = spec.blockContainer;
    final box = container.spec;
    final isAlreadySafe =
        box.alignment == null &&
        box.constraints == null &&
        box.transform == null &&
        box.transformAlignment == null &&
        container.widgetModifiers == null;
    if (isAlreadySafe) return spec;

    return spec.copyWith(
      blockContainer: StyleSpec(
        spec: BoxSpec(
          padding: box.padding,
          margin: box.margin,
          decoration: box.decoration,
          foregroundDecoration: box.foregroundDecoration,
          clipBehavior: box.clipBehavior,
        ),
        animation: container.animation,
      ),
    );
  }

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
    final spec = _applyBlockInsets(
      _sanitizeBlockContainer(resolvedSpec),
      widget.block,
    );

    Widget content = Box(
      styleSpec: spec.blockContainer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final blockData = BlockConfiguration(
            align: widget.align,
            spec: spec,
            size: constraints.biggest,
            runtimeKey: widget.runtimeKey,
          );

          Widget innerContent = widget.child;
          final diagnosticsEnabled =
              widget.configuration.debug &&
              !widget.configuration.isStaticRendering &&
              !widget.block.scrollable;
          if (diagnosticsEnabled) {
            innerContent = OverflowDiagnosticProbe(
              slideKey: widget.configuration.key,
              runtimeKey: widget.runtimeKey,
              availableSize: blockData.size,
              child: innerContent,
            );
          }

          innerContent = _BlockContentFrame(
            align: widget.align,
            size: blockData.size,
            scrollable: widget.block.scrollable,
            isStaticRendering: widget.configuration.isStaticRendering,
            child: innerContent,
          );

          return InheritedData(data: blockData, child: innerContent);
        },
      ),
    );

    final debugLayoutEnabled = widget.configuration.debug;
    if (debugLayoutEnabled) {
      content = BlockLayoutDebugOverlay(
        margin: spec.blockContainer.spec.margin,
        padding: spec.blockContainer.spec.padding,
        child: content,
      );
    }

    return content;
  }
}

class _BlockContentFrame extends StatelessWidget {
  const _BlockContentFrame({
    required this.align,
    required this.size,
    required this.scrollable,
    required this.isStaticRendering,
    required this.child,
  });

  final ContentAlignment align;
  final Size size;
  final bool scrollable;
  final bool isStaticRendering;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final alignment = align.toAlignment;

    if (scrollable && !isStaticRendering) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Align(alignment: alignment, child: child),
        ),
      );
    }

    return ClipRect(
      child: Align(alignment: alignment, child: child),
    );
  }
}

/// Helper widget for content block children to access BlockConfiguration context.
class _ContentBlockChild extends StatelessWidget {
  const _ContentBlockChild({
    required this.content,
    required this.allowVerticalOverflow,
  });

  final String content;
  final bool allowVerticalOverflow;

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

    if (!allowVerticalOverflow) return markdown;
    return OverflowBox(
      alignment: data.align.toAlignment,
      minWidth: 0,
      maxWidth: data.size.width,
      minHeight: 0,
      maxHeight: double.infinity,
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
    final factory = slide.getWidgetFactory(block.name);

    if (factory == null) {
      return ErrorWidgets.simple('Widget not found: ${block.name}');
    }

    try {
      final child = factory(block.args);
      if (!block.scrollable || !slide.isStaticRendering) return child;

      final data = BlockConfiguration.of(context);
      return OverflowBox(
        alignment: Alignment.topCenter,
        minWidth: data.size.width,
        maxWidth: data.size.width,
        minHeight: data.size.height,
        maxHeight: double.infinity,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: data.size.height),
          child: Align(alignment: data.align.toAlignment, child: child),
        ),
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
    required this.align,
    required this.configuration,
    required this.runtimeKey,
  });

  final ContentBlock block;
  final ContentAlignment align;
  final SlideConfiguration configuration;
  final String runtimeKey;

  @override
  Widget build(BuildContext context) {
    return _BlockContainer(
      block: block,
      align: align,
      configuration: configuration,
      runtimeKey: runtimeKey,
      child: _ContentBlockChild(
        content: block.content,
        allowVerticalOverflow:
            configuration.isStaticRendering || !block.scrollable,
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
    required this.configuration,
    required this.runtimeKey,
  });

  final WidgetBlock block;
  final ContentAlignment align;
  final SlideConfiguration configuration;
  final String runtimeKey;

  @override
  Widget build(BuildContext context) {
    return BlockVariantScope(
      name: block.name,
      child: _BlockContainer(
        block: block,
        align: align,
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
    required this.sectionIndex,
  });

  final SectionBlock section;
  final int sectionIndex;

  Positioned _renderDebugInfo(Block block, int blockIndex, Size size) {
    return Positioned(
      top: 0,
      right: 0,
      child: LayoutDebugLabel(
        color: debugBlockColor,
        text:
            'BLOCK ${blockIndex + 1}  @${block.type}\n'
            '${size.width.toStringAsFixed(0)} × ${size.height.toStringAsFixed(0)}',
      ),
    );
  }

  @override
  Widget build(context) {
    final configuration = SlideConfiguration.of(context);
    final gapCount = math.max(0, section.blocks.length - 1);
    if (section.blocks.isEmpty) return const SizedBox.expand();

    return LayoutBuilder(
      builder: (context, constraints) {
        final actualSpacing = gapCount == 0
            ? 0.0
            : math.min(section.spacing, constraints.maxWidth / gapCount);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (
              var blockIndex = 0;
              blockIndex < section.blocks.length;
              blockIndex++
            ) ...[
              Expanded(
                flex: section.blocks[blockIndex].flex,
                child: Builder(
                  builder: (context) {
                    final block = section.blocks[blockIndex];
                    final align = section.resolveBlockAlign(block);
                    final runtimeKey = buildBlockRuntimeKey(
                      configuration.key,
                      sectionIndex,
                      blockIndex,
                    );

                    Widget blockWidget = switch (block) {
                      WidgetBlock b => CustomBlockWidget(
                        block: b,
                        align: align,
                        configuration: configuration,
                        runtimeKey: runtimeKey,
                      ),
                      ContentBlock b => BlockWidget(
                        block: b,
                        align: align,
                        configuration: configuration,
                        runtimeKey: runtimeKey,
                      ),
                    };

                    final debugLayoutEnabled = configuration.debug;
                    if (!debugLayoutEnabled) return blockWidget;
                    return LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        fit: StackFit.expand,
                        children: [
                          blockWidget,
                          _renderDebugInfo(
                            block,
                            blockIndex,
                            constraints.biggest,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (blockIndex < section.blocks.length - 1)
                SizedBox(width: actualSpacing),
            ],
          ],
        );
      },
    );
  }
}
