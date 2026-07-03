import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

/// A scrollable list of slide thumbnails for jumping around during present
/// mode. Shown in the sliding menu overlay; tapping a thumbnail jumps to it.
///
/// Like the editor's preview list, each thumbnail is a live [SlideRenderView]
/// scaled down — there's no thumbnail cache, so previews always reflect the
/// current deck.
class SlideMenu extends StatelessWidget {
  const SlideMenu({
    required this.slides,
    required this.activeIndex,
    required this.onSelect,
    super.key,
  });

  final List<SlideConfiguration> slides;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: false,
      child: Box(
        style: BoxStyler()
            .color($surface())
            .padding(.all(16))
            .borderRounded(16)
            .border(.color($border()))
            .shadow(
              .color(
                $backdrop().withOpacity(0.05),
              ).blurRadius(1).offset(x: 0, y: 2),
            ),
        child: ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(scrollbars: false),
          child: ListView.builder(
            clipBehavior: .none,
            itemCount: slides.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const .only(bottom: 16),
                child: _MenuThumbnail(
                  index: index,
                  configuration: slides[index],
                  isActive: index == activeIndex,
                  onTap: () => onSelect(index),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuThumbnail extends StatelessWidget {
  const _MenuThumbnail({
    required this.index,
    required this.configuration,
    required this.isActive,
    required this.onTap,
  });

  final int index;
  final SlideConfiguration configuration;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Box(
        style: BoxStyler()
            .borderRounded(10)
            .borderAll(
              color: isActive ? $accent() : $overlay(),
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
            )
            .clipBehavior(.antiAliasWithSaveLayer)
            .wrap(.aspectRatio(16 / 9)),
        child: FittedBox(
          fit: .cover,
          alignment: .topLeft,
          child: SlideRenderView(configuration),
        ),
      ),
    );
  }
}
