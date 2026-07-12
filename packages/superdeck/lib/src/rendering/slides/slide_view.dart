import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../deck/slide_configuration.dart';
import '../../styling/components/slide.dart';
import '../../utils/constants.dart';
import '../blocks/block_widget.dart';

class SlideView extends StatelessWidget {
  final SlideConfiguration slide;
  const SlideView(this.slide, {super.key});

  Widget _renderPreferredSize(PreferredSizeWidget? widget, double height) {
    return widget != null
        ? SizedBox(height: height, child: widget)
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

  Widget _renderSections(SlideConfiguration configuration) {
    final sections = configuration.sections;
    if (sections.isEmpty) {
      return const SizedBox.expand();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (
          var sectionIndex = 0;
          sectionIndex < sections.length;
          sectionIndex++
        )
          Expanded(
            flex: sections[sectionIndex].flex,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final section = sections[sectionIndex];
                final sectionSize = constraints.biggest;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    SectionWidget(section: section, sectionIndex: sectionIndex),
                    if (configuration.debug)
                      _renderDebugInfo(section, sectionSize),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = slide.parts?.header;
    final footer = slide.parts?.footer;

    final backgroundWidget = slide.parts?.background ?? const SizedBox.shrink();

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
                return Align(
                  child: Box(
                    styleSpec: spec.slideContainer,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.hasBoundedHeight
                            ? constraints.maxHeight
                            : kResolution.height;
                        final preferredHeaderHeight =
                            header?.preferredSize.height ?? 0.0;
                        final preferredFooterHeight =
                            footer?.preferredSize.height ?? 0.0;
                        final preferredChromeHeight =
                            preferredHeaderHeight + preferredFooterHeight;
                        final chromeScale =
                            preferredChromeHeight > 0 &&
                                preferredChromeHeight > availableHeight
                            ? availableHeight / preferredChromeHeight
                            : 1.0;
                        final headerHeight =
                            preferredHeaderHeight * chromeScale;
                        final footerHeight =
                            preferredFooterHeight * chromeScale;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _renderPreferredSize(header, headerHeight),
                            Expanded(child: _renderSections(slide)),
                            _renderPreferredSize(footer, footerHeight),
                          ],
                        );
                      },
                    ),
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
