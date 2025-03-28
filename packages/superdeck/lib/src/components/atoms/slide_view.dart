import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../modules/common/helpers/constants.dart';
import '../../modules/deck/slide_configuration.dart';
import '../molecules/block_widget.dart';

class SlideView extends StatelessWidget {
  final SlideConfiguration slide;
  const SlideView(
    this.slide, {
    super.key,
  });

  Widget _renderPreferredSize(PreferredSizeWidget? widget) {
    return widget != null
        ? SizedBox.fromSize(
            size: widget.preferredSize,
            child: widget,
          )
        : const SizedBox.shrink();
  }

  Positioned _renderDebugInfo(SectionBlock section, Size slideSize) {
    final label = '''
@section | blocks: ${section.blocks.length} | ${slideSize.width.toStringAsFixed(2)} x ${slideSize.height.toStringAsFixed(2)} | align: ${section.align} | flex: ${section.flex}''';

    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );
    return Positioned(
      bottom: 0,
      left: 0,
      child: Container(
        color: Colors.cyan,
        padding: const EdgeInsets.all(8),
        child: Text(label, style: textStyle),
      ),
    );
  }

  Widget _renderSections(SlideConfiguration configuration, Size slideSize) {
    final sections = configuration.sections;
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }
    final totalSectionsFlex =
        sections.fold(0, (previous, section) => previous + section.flex);

    final sectionSizes = <SectionBlock, Size>{};

    for (var section in sections) {
      final heightPercentage = section.flex / totalSectionsFlex;
      final sectionSize = Size(
        slideSize.width,
        slideSize.height * heightPercentage,
      );
      sectionSizes[section] = sectionSize;
    }

    Offset currentOffset = Offset.zero;

    Map<SectionBlock, Offset> sectionOffsets = {};

    for (var section in sectionSizes.entries) {
      final sectionOffset = Offset(0, currentOffset.dy);
      sectionOffsets[section.key] = sectionOffset;
      currentOffset = Offset(
        currentOffset.dx,
        currentOffset.dy + section.value.height,
      );
    }

    return Stack(
      children: sections.map((section) {
        final sectionOffset = sectionOffsets[section]!;
        final sectionSize = sectionSizes[section]!;
        return Positioned(
          left: sectionOffset.dx,
          top: sectionOffset.dy,
          width: sectionSize.width,
          height: sectionSize.height,
          child: Stack(
            children: [
              SectionBlockWidget(
                section: section,
                size: sectionSize,
              ),
              if (configuration.debug) _renderDebugInfo(section, sectionSize),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = slide.parts?.header?.preferredSize.height ?? 0;
    final footerHeight = slide.parts?.footer?.preferredSize.height ?? 0;

    final footerWidget = _renderPreferredSize(slide.parts?.footer);
    final headerWidget = _renderPreferredSize(slide.parts?.header);
    final backgroundWidget = slide.parts?.background ?? const SizedBox.shrink();

    final slideSize = Size(
      kResolution.width,
      kResolution.height - headerHeight - footerHeight,
    );

    final sectionsWidget = _renderSections(slide, slideSize);
    return SizedBox.fromSize(
      size: kResolution,
      child: Stack(
        children: [
          Positioned.fill(
            child: backgroundWidget,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: headerWidget,
          ),
          Positioned(
            top: headerHeight,
            left: 0,
            right: 0,
            height: slideSize.height,
            child: sectionsWidget,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: footerHeight,
            child: footerWidget,
          ),
        ],
      ),
    );
  }
}
