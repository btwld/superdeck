import 'package:flutter/cupertino.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';

/// Bottom-centered overlay with prev/next, a slide counter, and a menu toggle.
///
/// Purely presentational: the page owns the [PresentationStore] and passes the
/// current position plus callbacks. Buttons disable at the deck's edges.
class PresentationControls extends StatelessWidget {
  const PresentationControls({
    required this.currentIndex,
    required this.slideCount,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleMenu,
    super.key,
  });

  final int currentIndex;
  final int slideCount;
  final VoidCallback onFirst;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleMenu;

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: FlexBoxStyler()
          .spacing(8)
          .mainAxisSize(.min)
          .padding(.horizontal(12).vertical(8))
          .color($overlay())
          .shape(.stadium().side(.color($border()))),
      children: [
        HeroIconButton(
          variant: .ghost,
          size: .sm,
          icon: CupertinoIcons.list_bullet,
          onPressed: onToggleMenu,
        ),
        HeroIconButton(
          variant: .ghost,
          size: .sm,
          icon: CupertinoIcons.backward_end,
          enabled: currentIndex > 0,
          onPressed: onFirst,
        ),
        HeroIconButton(
          variant: .ghost,
          size: .sm,
          icon: CupertinoIcons.chevron_left,
          enabled: currentIndex > 0,
          onPressed: onPrevious,
        ),
        Box(
          style: BoxStyler()
              .paddingX(8)
              .textStyle(.color($surfaceForeground()).fontSize(13)),
          child: StyledText('${currentIndex + 1} / $slideCount'),
        ),
        HeroIconButton(
          variant: .ghost,
          size: .sm,
          icon: CupertinoIcons.chevron_right,
          enabled: currentIndex < slideCount - 1,
          onPressed: onNext,
        ),
      ],
    );
  }
}
