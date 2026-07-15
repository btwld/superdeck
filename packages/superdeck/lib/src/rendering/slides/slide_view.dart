import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../deck/slide_configuration.dart';
import '../../styling/components/slide.dart';
import '../../utils/constants.dart';
import '../blocks/block_widget.dart';
import '../layout_debug_overlay.dart';

class SlideView extends StatelessWidget {
  final SlideConfiguration slide;
  const SlideView(this.slide, {super.key});

  Widget _renderPreferredSize(PreferredSizeWidget? widget, double height) {
    return widget != null
        ? SizedBox(height: height, child: widget)
        : const SizedBox.shrink();
  }

  Positioned _renderDebugInfo(
    SectionBlock section,
    int sectionIndex,
    Size slideSize,
  ) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: LayoutDebugLabel(
        color: debugSectionColor,
        text:
            'SECTION ${sectionIndex + 1}  blocks:${section.blocks.length}  '
            '${slideSize.width.toStringAsFixed(0)} × '
            '${slideSize.height.toStringAsFixed(0)}',
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
                    if (configuration.debug)
                      LayoutDebugFrame(
                        color: debugSectionColor,
                        strokeWidth: 4,
                        child: SectionWidget(
                          section: section,
                          sectionIndex: sectionIndex,
                        ),
                      )
                    else
                      SectionWidget(
                        section: section,
                        sectionIndex: sectionIndex,
                      ),
                    if (configuration.debug)
                      _renderDebugInfo(section, sectionIndex, sectionSize),
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
          if (slide.debug)
            const Positioned(
              left: 8,
              bottom: 8,
              child: IgnorePointer(child: LayoutDebugLegend()),
            ),
        ],
      ),
    );
  }
}
