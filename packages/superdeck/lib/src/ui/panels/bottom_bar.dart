import 'dart:async';

import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../deck/deck_controller.dart';
import '../../plugins/deck_action.dart';
import '../tokens/colors.dart';
import '../widgets/icon_button.dart';

class DeckBottomBar extends StatelessWidget {
  const DeckBottomBar({super.key, this.actions = const []});

  final List<DeckAction> actions;

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
    final presentation = deck.presentation;

    return FlexBox(
      style: _bottomBarContainer,
      children: [
        // view notes - use Watch for reactive icon
        Watch(
          (context) => SDIconButton(
            onPressed: presentation.toggleNotes,
            icon: presentation.isNotesOpen.value
                ? Icons.comment
                : Icons.comments_disabled,
            semanticLabel: presentation.isNotesOpen.value
                ? 'Close notes panel'
                : 'Open notes panel',
          ),
        ),

        SDIconButton(
          icon: Icons.replay_circle_filled_rounded,
          onPressed: () => presentation.generateThumbnails(
            context,
            deck.slides.value,
            force: true,
          ),
          semanticLabel: 'Regenerate thumbnails',
        ),
        for (final action in actions)
          SDIconButton(
            icon: action.icon,
            onPressed: () => _invokeAction(context, deck, action),
            semanticLabel: action.label,
          ),
        const Spacer(),
        SDIconButton(
          icon: Icons.arrow_back,
          onPressed: presentation.previousSlide,
          semanticLabel: 'Previous slide',
        ),
        SDIconButton(
          icon: Icons.arrow_forward,
          onPressed: presentation.nextSlide,
          semanticLabel: 'Next slide',
        ),
        const Spacer(),

        // Page counter - use Watch for reactive text
        Watch(
          (context) => Text(
            '${presentation.currentIndex.value + 1} of ${presentation.totalSlides.value}',
            style: const TextStyle(color: Colors.white),
          ),
        ),

        SDIconButton(
          icon: Icons.close,
          onPressed: presentation.closeMenu,
          semanticLabel: 'Close menu',
        ),
      ],
    );
  }

  void _invokeAction(
    BuildContext context,
    DeckController deck,
    DeckAction action,
  ) {
    unawaited(
      action.invoke(context, deck).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'superdeck',
            context: ErrorDescription(
              'while invoking deck action "${action.id}"',
            ),
          ),
        );
      }),
    );
  }
}
