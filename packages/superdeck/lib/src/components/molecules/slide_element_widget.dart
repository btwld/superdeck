import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/components/molecules/element_provider.dart';
import 'package:superdeck/src/modules/common/helpers/utils.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../modules/common/helpers/converters.dart';
import '../../modules/common/helpers/provider.dart';
import '../../modules/common/styles/style_spec.dart';
import '../../modules/deck/slide_configuration.dart';
import '../atoms/cache_image_widget.dart';
import '../atoms/markdown_viewer.dart';
import '../organisms/webview_wrapper.dart';

sealed class SlideElementWidget<T extends SlideElement> extends StatefulWidget {
  const SlideElementWidget({
    super.key,
    required this.block,
    required this.size,
    required this.configuration,
  });

  Widget build(BuildContext context, ElementData<T> data);

  final T block;
  final Size size;
  final SlideConfiguration configuration;
  @override
  State<SlideElementWidget<T>> createState() => _SlideElementWidgetState<T>();
}

class _SlideElementWidgetState<T extends SlideElement>
    extends State<SlideElementWidget<T>> {
  @override
  Widget build(context) {
    final style = widget.configuration.style.applyVariant(
      Variant(widget.block.type),
    );

    return SpecBuilder(
        style: style,
        builder: (context) {
          final spec = SlideSpec.of(context);

          final blockOffset = calculateBlockOffset(spec.blockContainer);

          final blockData = ElementData(
            block: widget.block,
            spec: spec,
            size: Size(
              widget.size.width - blockOffset.dx,
              widget.size.height - blockOffset.dy,
            ),
          );

          Widget current = InheritedData(
            data: blockData,
            child: spec.blockContainer(
              child: widget.build(context, blockData),
            ),
          );

          if (widget.block.scrollable == true &&
              !widget.configuration.isExporting) {
            current = SingleChildScrollView(
              child: current,
            );
          } else {
            current = Wrap(
              clipBehavior: Clip.hardEdge,
              children: [current],
            );
          }

          final decoration = widget.configuration.debug
              ? BoxDecoration(
                  border: Border.all(
                    color: Colors.cyan,
                    width: 2,
                  ),
                )
              : null;

          return Container(
            decoration: decoration,
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(widget.size),
              child: Stack(
                children: [
                  Align(
                    alignment: ConverterHelper.toAlignment(
                      blockData.block.align,
                    ),
                    child: current,
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class MarkdownElementWidget extends SlideElementWidget<MarkdownElement> {
  const MarkdownElementWidget({
    super.key,
    required super.block,
    required super.size,
    required super.configuration,
  });

  @override
  Widget build(context, data) {
    return MarkdownViewer(
      content: data.block.content,
      spec: data.spec,
    );
  }
}

class ImageElementWidget extends SlideElementWidget<ImageElement> {
  const ImageElementWidget({
    super.key,
    required super.block,
    required super.size,
    required super.configuration,
  });

  @override
  Widget build(context, data) {
    final alignment = data.block.align ?? ContentAlignment.center;
    final imageFit = data.block.fit ?? ImageFit.cover;
    final spec = data.spec;

    return CachedImage(
      uri: Uri.parse(data.block.asset.fileName),
      spec: spec.image.copyWith(
        fit: ConverterHelper.toBoxFit(imageFit),
        alignment: ConverterHelper.toAlignment(alignment),
      ),
    );
  }
}

class CustomElementWidget extends SlideElementWidget<CustomElement> {
  const CustomElementWidget({
    super.key,
    required super.block,
    required super.size,
    required super.configuration,
  });

  @override
  Widget build(context, data) {
    final slide = SlideConfiguration.of(context);

    final widgetBuilder = slide.getWidget(data.block.id);

    if (widgetBuilder == null) {
      return Container(
        color: Colors.red,
        child: Center(
          child: Text('Widget not found: ${data.block.id}'),
        ),
      );
    }

    return Builder(
      builder: (context) {
        try {
          return SizedBox(
            height: data.size.height,
            child: widgetBuilder(data.block.props ?? {}),
          );
        } catch (e) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red,
              border: Border.all(
                color: Colors.red,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('''
Error building widget: ${data.block.id}

${e.toString()}'''),
            ),
          );
        }
      },
    );
  }
}

class DartPadBlockWidget extends SlideElementWidget<DartPadBlock> {
  const DartPadBlockWidget({
    super.key,
    required super.block,
    required super.size,
    required super.configuration,
  });

  @override
  Widget build(context, data) {
    if (kDebugMode) {
      return SizedBox(
        height: data.size.height,
        width: data.size.width,
        child: Container(
          color: Colors.blue,
          child: const Center(
            child: Text('DartPad not available in debug mode'),
          ),
        ),
      );
    }

    return WebViewWrapper(
      size: data.size,
      url: data.block.getDartPadUrl(),
    );
  }
}

class SlideSectionWidget extends StatelessWidget {
  const SlideSectionWidget({
    super.key,
    required this.section,
    required this.size,
  });

  final SlideSection section;
  final Size size;

  Positioned _renderDebugInfo(SlideElement block, Size size) {
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );
    final label = '''
@${block.type}
${size.width.toStringAsFixed(2)} x ${size.height.toStringAsFixed(2)}''';

    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        color: Colors.cyan.withAlpha((255 * 0.7).round()),
        child: Text(
          label,
          style: textStyle,
        ),
      ),
    );
  }

  @override
  Widget build(context) {
    final configuration = SlideConfiguration.of(context);
    final totalFlex = section.totalBlockFlex;

    final availableSize = Size(
      size.width,
      size.height,
    );

    final children = section.blocks.map((block) {
      final flex = block.flex ?? 1;
      final blockRatio = flex / totalFlex;
      final childSize = Size(
        availableSize.width * blockRatio,
        availableSize.height,
      );

      Widget childWidget;

      switch (block.type) {
        case SlideSection.key:
          childWidget = SlideSectionWidget(
            section: block as SlideSection,
            size: childSize,
          );
          break;
        case MarkdownElement.key:
          childWidget = MarkdownElementWidget(
            block: block as MarkdownElement,
            size: childSize,
            configuration: configuration,
          );
          break;
        case ImageElement.key:
          childWidget = ImageElementWidget(
            block: block as ImageElement,
            size: childSize,
            configuration: configuration,
          );
          break;
        case CustomElement.key:
          childWidget = CustomElementWidget(
            block: block as CustomElement,
            size: childSize,
            configuration: configuration,
          );
          break;
        case DartPadBlock.key:
          childWidget = DartPadBlockWidget(
            block: block as DartPadBlock,
            size: childSize,
            configuration: configuration,
          );
          break;
        default:
          childWidget = Center(
            child: Text('Unknown block type: ${block.type}'),
          );
      }

      Widget positionedChild = SizedBox(
        width: childSize.width,
        height: childSize.height,
        child: childWidget,
      );

      if (configuration.debug) {
        positionedChild = Stack(
          children: [
            positionedChild,
            _renderDebugInfo(block, childSize),
          ],
        );
      }

      return positionedChild;
    }).toList();

    final decoration = configuration.debug
        ? BoxDecoration(
            border: Border.all(
              color: Colors.red,
              width: 2,
            ),
          )
        : null;

    return Container(
      decoration: decoration,
      width: availableSize.width,
      height: availableSize.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
