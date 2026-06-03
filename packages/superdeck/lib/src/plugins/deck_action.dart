import 'dart:async';

import 'package:flutter/widgets.dart';

import '../deck/deck_controller.dart';

typedef DeckActionCallback =
    FutureOr<void> Function(BuildContext context, DeckController deck);

/// A command contributed to the SuperDeck shell.
///
/// Actions are runtime hooks. They are rendered by the presentation shell and
/// receive the active [DeckController] so packages can open their own UI using
/// current deck state.
final class DeckAction {
  final String id;
  final String label;
  final IconData icon;
  final DeckActionCallback _onPressed;

  DeckAction({
    required this.id,
    required this.label,
    required this.icon,
    required DeckActionCallback onPressed,
  }) : _onPressed = onPressed {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Deck action id must not be empty.');
    }
    if (label.trim().isEmpty) {
      throw ArgumentError.value(
        label,
        'label',
        'Deck action label must not be empty.',
      );
    }
  }

  Future<void> invoke(BuildContext context, DeckController deck) async {
    await _onPressed(context, deck);
  }
}
