import 'package:flutter/foundation.dart';
import 'package:superdeck/superdeck.dart';

/// Present-mode navigation state, scoped to the `/present` route.
///
/// Tracks which slide is on screen and whether the thumbnail menu is open. The
/// slide list itself lives on [DeckController.slides] (a signal) — this store
/// only holds the cursor into it and reads the current count off the controller
/// to keep the index in range. It intentionally does not subscribe to the
/// controller: slides don't change while presenting, and the page watches the
/// signal directly for rendering.
///
/// Seeded from the editor's active slide via `initialIndex` so pressing Present
/// opens on the slide the author was editing.
class PresentationStore extends ChangeNotifier {
  PresentationStore(this._controller, {int initialIndex = 0})
    : _currentIndex = 0 {
    _currentIndex = _clamp(initialIndex);
  }

  final DeckController _controller;

  int _currentIndex;
  bool _isMenuOpen = false;

  int get currentIndex => _currentIndex;

  bool get isMenuOpen => _isMenuOpen;

  int get slideCount => _controller.slides.value.length;

  bool get canGoNext => _currentIndex < slideCount - 1;

  bool get canGoPrevious => _currentIndex > 0;

  int _clamp(int index) {
    final maxIndex = slideCount > 0 ? slideCount - 1 : 0;
    return index.clamp(0, maxIndex);
  }

  void goToSlide(int index) {
    final clamped = _clamp(index);
    if (_currentIndex == clamped) return;
    _currentIndex = clamped;
    notifyListeners();
  }

  void next() => goToSlide(_currentIndex + 1);

  void previous() => goToSlide(_currentIndex - 1);

  void openMenu() {
    if (_isMenuOpen) return;
    _isMenuOpen = true;
    notifyListeners();
  }

  void closeMenu() {
    if (!_isMenuOpen) return;
    _isMenuOpen = false;
    notifyListeners();
  }

  void toggleMenu() {
    _isMenuOpen = !_isMenuOpen;
    notifyListeners();
  }
}
