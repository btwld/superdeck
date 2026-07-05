import 'package:flutter/foundation.dart';

/// Shared editor navigation state: which slide the caret currently sits in.
///
/// Pure domain state with no super_editor coupling. The document itself lives in
/// the presentation-layer `TextEditorController`, which keeps this in sync with
/// the caret and reacts when it's set from outside the editor (e.g. a preview
/// tap) by scrolling the caret to that slide.
class EditorStore extends ChangeNotifier {
  int _activeSlideIndex = 0;

  /// The 0-based slide the caret currently sits in.
  int get activeSlideIndex => _activeSlideIndex;

  set activeSlideIndex(int value) {
    if (_activeSlideIndex == value) return;
    _activeSlideIndex = value;
    notifyListeners();
  }
}
