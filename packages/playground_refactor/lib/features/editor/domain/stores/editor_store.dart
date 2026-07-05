import 'package:flutter/foundation.dart';

/// Shared editor navigation state: which slide the caret currently sits in.
///
/// Pure domain state with no super_editor coupling. The document itself lives in
/// the presentation-layer `TextEditorController`, which keeps this in sync with
/// the caret and reacts when it's set from outside the editor (e.g. a preview
/// tap) by scrolling the caret to that slide.
class EditorStore extends ChangeNotifier {
  int _activeSlideIndex = 0;
  bool _showPreviewSidebar = true;
  bool _showCustomizationSidebar = true;

  /// The 0-based slide the caret currently sits in.
  int get activeSlideIndex => _activeSlideIndex;

  /// Whether the left preview sidebar is showing.
  bool get showPreviewSidebar => _showPreviewSidebar;

  /// Whether the right customization sidebar is showing.
  bool get showCustomizationSidebar => _showCustomizationSidebar;

  set activeSlideIndex(int value) {
    if (_activeSlideIndex == value) return;
    _activeSlideIndex = value;
    notifyListeners();
  }

  void togglePreviewSidebar() {
    _showPreviewSidebar = !_showPreviewSidebar;
    notifyListeners();
  }

  void toggleCustomizationSidebar() {
    _showCustomizationSidebar = !_showCustomizationSidebar;
    notifyListeners();
  }
}
