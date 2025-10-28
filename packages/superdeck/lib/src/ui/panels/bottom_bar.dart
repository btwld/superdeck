import 'package:flutter/material.dart' show Icons, Colors;
import 'package:mix/mix.dart';
import 'package:superdeck/src/export/pdf_export_screen.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck/src/ui/widgets/icon_button.dart';

import 'package:flutter/widgets.dart';

import '../../deck/deck_controller.dart';
import '../../deck/deck_provider.dart';
import '../../export/thumbnail_controller.dart';

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
    final deckController = DeckController.of(context);
    final navigationController = NavigationProvider.of(context);
    final thumbnail = ThumbnailController.of(context);

    // No ListenableBuilder needed - this widget is inside SplitView's builder
    final currentPage = navigationController.currentIndex + 1;
    final totalPages = deckController.totalSlides;
    final isNotesOpen = deckController.isNotesOpen;

    return FlexBox(
      style: _bottomBarContainer,
      children: [
        // view notes
        SDIconButton(
          onPressed: deckController.toggleNotes,
          icon: isNotesOpen ? Icons.comment : Icons.comments_disabled,
        ),

        SDIconButton(
          icon: Icons.save,
          onPressed: () => PdfExportDialogScreen.show(context),
        ),

        SDIconButton(
          icon: Icons.replay_circle_filled_rounded,
          onPressed: () => thumbnail.generateThumbnails(
            deckController.slides,
            context,
            force: true,
          ),
        ),
        const Spacer(),
        SDIconButton(
          icon: Icons.arrow_back,
          onPressed: navigationController.previousSlide,
        ),
        SDIconButton(
          icon: Icons.arrow_forward,
          onPressed: navigationController.nextSlide,
        ),
        const Spacer(),
        Text(
          '$currentPage of $totalPages',
          style: const TextStyle(color: Colors.white),
        ),
        SDIconButton(icon: Icons.close, onPressed: deckController.closeMenu),
      ],
    );
  }
}
