import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../deck/deck_controller.dart';
import '../tokens/colors.dart';
import '../widgets/icon_button.dart';

class DeckBottomBar extends StatelessWidget {
  const DeckBottomBar({super.key});

  FlexBoxStyler get _bottomBarContainer => FlexBoxStyler()
      .mainAxisAlignment(MainAxisAlignment.center)
      .crossAxisAlignment(CrossAxisAlignment.center)
      .height(60)
      .marginAll(12)
      .spacing(16)
      .paddingX(20)
      .paddingY(10)
      .color(SDColors.bgLow.token())
      .borderRounded(16);

  @override
  Widget build(BuildContext context) {
    final deck = DeckController.of(context);

    return FlexBox(
      style: _bottomBarContainer,
      children: [
        // view notes - use Watch for reactive icon
        Watch(
          (context) => SDIconButton(
            onPressed: deck.toggleNotes,
            icon: deck.isNotesOpen.value
                ? Icons.comment
                : Icons.comments_disabled,
            semanticLabel: deck.isNotesOpen.value
                ? 'Close notes panel'
                : 'Open notes panel',
          ),
        ),

        SDIconButton(
          icon: Icons.replay_circle_filled_rounded,
          onPressed: () => deck.generateThumbnails(context, force: true),
          semanticLabel: 'Regenerate thumbnails',
        ),
        const Spacer(),
        SDIconButton(
          icon: Icons.arrow_back,
          onPressed: deck.previousSlide,
          semanticLabel: 'Previous slide',
        ),
        SDIconButton(
          icon: Icons.arrow_forward,
          onPressed: deck.nextSlide,
          semanticLabel: 'Next slide',
        ),
        const Spacer(),

        // Page counter - use Watch for reactive text
        Watch(
          (context) => Text(
            '${deck.currentIndex.value + 1} of ${deck.totalSlides.value}',
            style: const TextStyle(color: Colors.white),
          ),
        ),

        SDIconButton(
          icon: Icons.close,
          onPressed: deck.closeMenu,
          semanticLabel: 'Close menu',
        ),
      ],
    );
  }
}
