import 'package:signals_flutter/signals_flutter.dart';

/// Editor-local navigation state: which slide the caret is currently in.
///
/// This is the single source of truth for the *active slide* in the editor,
/// distinct from `DeckController.presentation.currentIndex`, which drives
/// presentation-mode routing.
class EditorState {
  final activeSlideIndex = signal<int>(0);

  void dispose() {
    activeSlideIndex.dispose();
  }
}
