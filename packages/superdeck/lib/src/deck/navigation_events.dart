import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

// ============================================================================
// Navigation Events
// ============================================================================

/// Navigation events representing user actions in the presentation
///
/// This sealed class hierarchy defines all possible navigation events
/// that can occur in the application. Events are created by input handlers
/// (keyboard, gesture) and consumed by the DeckController.
sealed class NavigationEvent {}

/// Event to navigate to the next slide
class NextSlideEvent extends NavigationEvent {}

/// Event to navigate to the previous slide
class PreviousSlideEvent extends NavigationEvent {}

/// Event to navigate to a specific slide by index
class GoToSlideEvent extends NavigationEvent {
  final int index;

  GoToSlideEvent(this.index);
}

// ============================================================================
// Keyboard Navigation Handler
// ============================================================================

/// Handles keyboard input and converts it to navigation events
///
/// This handler is responsible for mapping keyboard keys to navigation events.
/// Requires Meta key (Command on macOS) to be pressed with arrow keys.
/// It returns null for keys that don't trigger navigation, allowing other
/// handlers to process them.
class KeyboardNavigationHandler {
  /// Processes a keyboard event and returns the corresponding navigation event
  ///
  /// Requires Meta key + arrow keys for navigation.
  /// Returns null if the key doesn't correspond to a navigation action.
  NavigationEvent? handleKey(KeyEvent event) {
    // Only handle key down events to avoid double-triggering
    if (event is! KeyDownEvent) return null;

    // Require meta key to be pressed for navigation
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

// ============================================================================
// Gesture Navigation Handler
// ============================================================================

/// Handles gesture input and converts it to navigation events
///
/// This handler processes tap and swipe gestures, converting them
/// into navigation events. It supports:
/// - Tap on right half of screen → next slide
/// - Tap on left half of screen → previous slide
/// - Swipe left → next slide
/// - Swipe right → previous slide
class GestureNavigationHandler {
  /// Minimum velocity (pixels/second) required to trigger swipe navigation
  static const double minSwipeVelocity = 500.0;

  /// Tracks the device kind that initiated the current drag gesture
  PointerDeviceKind? _dragDeviceKind;

  /// Processes a tap gesture and returns the corresponding navigation event
  ///
  /// Divides the screen into left and right halves:
  /// - Right half: next slide
  /// - Left half: previous slide
  ///
  /// Only responds to touch input; ignores mouse clicks on desktop.
  NavigationEvent? handleTap(TapUpDetails details, Size size) {
    // Ignore mouse input - only respond to actual touch
    if (details.kind == PointerDeviceKind.mouse) return null;

    final tapX = details.localPosition.dx;
    final rightHalf = tapX > size.width / 2;
    return rightHalf ? NextSlideEvent() : PreviousSlideEvent();
  }

  /// Processes the start of a drag gesture to track the device kind
  ///
  /// This must be called before handleSwipe to properly filter mouse input.
  void handleDragStart(DragStartDetails details) {
    _dragDeviceKind = details.kind;
  }

  /// Processes a swipe gesture and returns the corresponding navigation event
  ///
  /// Returns null if the swipe velocity is below the minimum threshold.
  /// - Swipe left (negative velocity): next slide
  /// - Swipe right (positive velocity): previous slide
  ///
  /// Only responds to touch input; ignores mouse drags on desktop.
  NavigationEvent? handleSwipe(DragEndDetails details) {
    // Ignore mouse input - only respond to actual touch
    if (_dragDeviceKind == PointerDeviceKind.mouse) {
      _dragDeviceKind = null;
      return null;
    }

    final velocity = details.velocity.pixelsPerSecond.dx;

    // Require minimum velocity to avoid accidental navigation
    if (velocity.abs() < minSwipeVelocity) {
      _dragDeviceKind = null;
      return null;
    }

    // Positive velocity = swipe right = previous slide
    // Negative velocity = swipe left = next slide
    _dragDeviceKind = null;
    return velocity > 0 ? PreviousSlideEvent() : NextSlideEvent();
  }
}
