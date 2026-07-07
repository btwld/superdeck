import 'package:flutter/foundation.dart';

/// Shared editor navigation state: which slide the caret currently sits in.
///
/// Pure domain state with no super_editor coupling. The document itself lives in
/// the presentation-layer `TextEditorController`, which keeps this in sync with
/// the caret and reacts when it's set from outside the editor (e.g. a preview
/// tap) by scrolling the caret to that slide.
class EditorStore extends ChangeNotifier {
  static const double minPreviewSidebarWidth = 160;
  static const double maxPreviewSidebarWidth = 480;
  static const double minCustomizationSidebarWidth = 240;
  static const double maxCustomizationSidebarWidth = 560;

  int _activeSlideIndex = 0;
  bool _showPreviewSidebar = true;
  bool _showCustomizationSidebar = true;
  double _previewSidebarWidth = minPreviewSidebarWidth;
  double _customizationSidebarWidth = maxCustomizationSidebarWidth;

  /// The 0-based slide the caret currently sits in.
  int get activeSlideIndex => _activeSlideIndex;

  /// Whether the left preview sidebar is showing.
  bool get showPreviewSidebar => _showPreviewSidebar;

  /// Whether the right customization sidebar is showing.
  bool get showCustomizationSidebar => _showCustomizationSidebar;

  /// Width of the left preview sidebar's content, in logical pixels.
  double get previewSidebarWidth => _previewSidebarWidth;

  /// Width of the right customization sidebar's content, in logical pixels.
  double get customizationSidebarWidth => _customizationSidebarWidth;

  set activeSlideIndex(int value) {
    if (_activeSlideIndex == value) return;
    _activeSlideIndex = value;
    notifyListeners();
  }

  set previewSidebarWidth(double value) {
    final clamped = value.clamp(minPreviewSidebarWidth, maxPreviewSidebarWidth);
    if (_previewSidebarWidth == clamped) return;
    _previewSidebarWidth = clamped;
    notifyListeners();
  }

  set customizationSidebarWidth(double value) {
    final clamped = value.clamp(
      minCustomizationSidebarWidth,
      maxCustomizationSidebarWidth,
    );
    if (_customizationSidebarWidth == clamped) return;
    _customizationSidebarWidth = clamped;
    notifyListeners();
  }

  void togglePreviewSidebar(bool value) {
    _showPreviewSidebar = value;
    notifyListeners();
  }

  void toggleCustomizationSidebar(bool value) {
    _showCustomizationSidebar = value;
    notifyListeners();
  }
}
