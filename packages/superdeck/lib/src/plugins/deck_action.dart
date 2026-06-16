import 'dart:async';

import 'package:flutter/widgets.dart';

import '../deck/deck_controller.dart';

/// Handles a shell action with access to the current deck.
///
/// The [context] belongs to the widget that invoked the action, and [deck]
/// exposes the active presentation state.
typedef DeckActionCallback =
    FutureOr<void> Function(BuildContext context, DeckController deck);

/// A command contributed to the SuperDeck shell.
///
/// Actions are runtime hooks. They are rendered by the presentation shell and
/// receive the active [DeckController] so packages can open their own UI using
/// current deck state.
final class DeckAction {
  /// Stable action identifier used for diagnostics and duplicate checks.
  final String id;

  /// User-facing label used for accessibility and tooltips.
  final String label;

  /// Icon shown by the SuperDeck shell.
  final IconData icon;

  final DeckActionCallback _onPressed;

  /// Creates a shell command.
  ///
  /// Throws [ArgumentError] when [id] or [label] is empty.
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

  /// Runs this action against the active [deck].
  Future<void> invoke(BuildContext context, DeckController deck) async {
    await _onPressed(context, deck);
  }
}
