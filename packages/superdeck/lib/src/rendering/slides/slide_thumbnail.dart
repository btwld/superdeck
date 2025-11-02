import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/src/ui/ui.dart';

import '../../deck/deck_controller.dart';
import '../../deck/slide_configuration.dart';
import '../../utils/constants.dart';

class SlideThumbnail extends StatelessWidget {
  final bool selected;
  final SlideConfiguration slide;

  const SlideThumbnail({
    super.key,
    required this.selected,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    final deck = DeckController.of(context);

    return Watch((context) {
      final asyncThumbnail = deck.getThumbnail(slide.key);

      if (asyncThumbnail == null) {
        return _PreviewContainer(
          selected: selected,
          child: AspectRatio(
            aspectRatio: kAspectRatio,
            child: Container(
              color: Colors.grey[300],
              child: const Center(child: IsometricLoading()),
            ),
          ),
        );
      }

      return _PreviewContainer(
        selected: selected,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: kAspectRatio,
              child: asyncThumbnail.build(context),
            ),
          ],
        ),
      );
    });
  }
}

class _PreviewContainer extends StatelessWidget {
  final Widget child;
  final bool selected;

  const _PreviewContainer({required this.selected, required this.child});

  @override
  Widget build(BuildContext context) {
    // Using Flutter widgets with AnimatedContainer for transitions
    final scale = selected ? 1.05 : 1.0;
    return AnimatedOpacity(
      opacity: selected ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(8),
        transform: Matrix4.diagonal3Values(scale, scale, 1.0),
        decoration: BoxDecoration(
          color: Colors.grey,
          border: Border.all(
            width: 2,
            color: selected ? Colors.cyan : Colors.transparent,
          ),
          boxShadow: const [BoxShadow(blurRadius: 4, spreadRadius: 1)],
        ),
        child: child,
      ),
    );
  }
}
