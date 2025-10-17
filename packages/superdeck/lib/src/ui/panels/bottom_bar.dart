import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/export/pdf_export_screen.dart';

import '../../deck/deck_controller.dart';
import '../../deck/deck_provider.dart';
import '../../export/thumbnail_controller.dart';

class DeckBottomBar extends StatelessWidget {
  const DeckBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final deckController = DeckController.of(context);
    final navigationController = NavigationProvider.of(context);
    final thumbnail = ThumbnailController.of(context);

    // No ListenableBuilder needed - this widget is inside SplitView's builder
    final currentPage = navigationController.currentIndex + 1;
    final totalPages = deckController.totalSlides;
    final isNotesOpen = deckController.isNotesOpen;

    return _bottomBarContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // view notes
          IconButton(
            onPressed: deckController.toggleNotes,
            icon: isNotesOpen
                ? const Icon(Icons.comment)
                : const Icon(Icons.comments_disabled),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => PdfExportDialogScreen.show(context),
            icon: const Icon(Icons.save),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => thumbnail.generateThumbnails(
              deckController.slides,
              context,
              force: true,
            ),
            icon: const Icon(Icons.replay_circle_filled_rounded),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: navigationController.previousSlide,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: navigationController.nextSlide,
          ),
          const Spacer(),
          Text(
            '$currentPage of $totalPages',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: deckController.closeMenu,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

final _bottomBarContainer = BoxStyler()
    .height(60)
    .marginAll(12)
    .paddingX(20)
    .paddingY(10)
    .color(const Color.fromARGB(255, 17, 17, 17))
    .borderRounded(16);
