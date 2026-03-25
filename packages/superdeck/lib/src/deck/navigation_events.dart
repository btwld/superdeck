import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

sealed class NavigationEvent {}

class NextSlideEvent extends NavigationEvent {}

class PreviousSlideEvent extends NavigationEvent {}

class GoToSlideEvent extends NavigationEvent {
  final int index;

  GoToSlideEvent(this.index);
}

/// Maps Meta+arrow keyboard shortcuts to navigation events.
///
/// Returns `null` for keys that don't trigger navigation.
class KeyboardNavigationHandler {
  /// Returns the navigation event for [event], or `null` if unrecognized.
  NavigationEvent? handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return null;
    if (!HardwareKeyboard.instance.isMetaPressed) return null;

    return switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => NextSlideEvent(),
      LogicalKeyboardKey.arrowDown => NextSlideEvent(),
      LogicalKeyboardKey.arrowLeft => PreviousSlideEvent(),
      LogicalKeyboardKey.arrowUp => PreviousSlideEvent(),
      _ => null,
    };
  }
}

/// Converts tap and swipe gestures to navigation events.
///
/// Touch-only — ignores mouse clicks and drags on desktop.
/// - Tap right half of screen → next slide
/// - Tap left half → previous slide
/// - Swipe left → next slide
/// - Swipe right → previous slide
class GestureNavigationHandler {
  /// Minimum velocity (pixels/second) required to trigger swipe navigation.
  static const double minSwipeVelocity = 500.0;

  PointerDeviceKind? _dragDeviceKind;

  /// Returns a navigation event based on tap position, or `null` for non-touch input.
  NavigationEvent? handleTap(TapUpDetails details, Size size) {
    if (!_isTouchLike(details.kind)) return null;

    final tapX = details.localPosition.dx;
    final rightHalf = tapX > size.width / 2;
    return rightHalf ? NextSlideEvent() : PreviousSlideEvent();
  }

  void handleDragStart(DragStartDetails details) {
    _dragDeviceKind = details.kind;
  }

  /// Returns a navigation event if the swipe exceeds [minSwipeVelocity], or `null`.
  NavigationEvent? handleSwipe(DragEndDetails details) {
    if (!_isTouchLike(_dragDeviceKind)) {
      _dragDeviceKind = null;
      return null;
    }

    final velocity = details.velocity.pixelsPerSecond.dx;

    if (velocity.abs() < minSwipeVelocity) {
      _dragDeviceKind = null;
      return null;
    }

    _dragDeviceKind = null;
    return velocity > 0 ? PreviousSlideEvent() : NextSlideEvent();
  }

  static bool _isTouchLike(PointerDeviceKind? kind) {
    return switch (kind) {
      PointerDeviceKind.touch ||
      PointerDeviceKind.stylus ||
      PointerDeviceKind.invertedStylus => true,
      _ => false,
    };
  }
}
