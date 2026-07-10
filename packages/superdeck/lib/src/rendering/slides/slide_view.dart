import 'package:flutter/material.dart' show Colors;
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../deck/slide_configuration.dart';
import '../../styling/components/slide.dart';
import '../../utils/constants.dart';
import '../blocks/block_widget.dart';
import 'package:flutter/widgets.dart';

class SlideView extends StatelessWidget {
  final SlideConfiguration slide;
  const SlideView(this.slide, {super.key});

  Widget _renderPreferredSize(PreferredSizeWidget? widget) {
    return widget != null
        ? SizedBox.fromSize(size: widget.preferredSize, child: widget)
        : const SizedBox.shrink();
  }

  Positioned _renderDebugInfo(SectionBlock section, Size slideSize) {
    final label = '''
@section | blocks: ${section.blocks.length} | ${slideSize.width.toStringAsFixed(2)} x ${slideSize.height.toStringAsFixed(2)} | align: ${section.align} | flex: ${section.flex}''';

    const textStyle = TextStyle(color: Colors.black, fontSize: 12);
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
    final totalSectionsFlex = sections.fold(
      0,
      (previous, section) => previous + section.flex,
    );

    var topOffset = 0.0;
    final sectionWidgets = <Widget>[];
    for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final section = sections[sectionIndex];
      final heightPercentage = section.flex / totalSectionsFlex;
      final sectionSize = Size(
        slideSize.width,
        slideSize.height * heightPercentage,
      );
      sectionWidgets.add(
        Positioned(
          left: 0,
          top: topOffset,
          width: sectionSize.width,
          height: sectionSize.height,
          child: Stack(
            children: [
              SectionWidget(
                section: section,
                size: sectionSize,
                sectionIndex: sectionIndex,
              ),
              if (configuration.debug) _renderDebugInfo(section, sectionSize),
            ],
          ),
        ),
      );
      topOffset += sectionSize.height;
    }

    return Stack(children: sectionWidgets);
  }

  @override
  Widget build(BuildContext context) {
    final header = slide.parts?.header;
    final footer = slide.parts?.footer;

    final headerHeight = header != null ? header.preferredSize.height : 0.0;
    final footerHeight = footer != null ? footer.preferredSize.height : 0.0;

    final footerWidget = _renderPreferredSize(footer);
    final headerWidget = _renderPreferredSize(header);
    final backgroundWidget = slide.parts?.background ?? const SizedBox.shrink();

    final slideSize = Size(
      kResolution.width,
      kResolution.height - headerHeight - footerHeight,
    );

    final sectionsWidget = _renderSections(slide, slideSize);

    // Background should be outside the modifier to fill entire viewport
    return SizedBox.fromSize(
      size: kResolution,
      child: Stack(
        children: [
          // Opaque floor so a slide is never transparent: a transparent or
          // absent background part would otherwise let other slides bleed
          // through during cross-fade transitions.
          const Positioned.fill(
            child: ColoredBox(color: kSlideBackgroundColor),
          ),
          // Background fills entire viewport (not affected by modifier)
          Positioned.fill(child: backgroundWidget),
          // Content wrapped with StyleBuilder to apply modifiers
          Positioned.fill(
            child: StyleBuilder<SlideSpec>(
              style: slide.style,
              builder: (context, spec) {
                return Box(
                  styleSpec: spec.slideContainer,
                  child: Stack(
                    children: [
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
