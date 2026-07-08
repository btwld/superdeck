import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'deck_controller.dart';
import 'deck_presentation_state.dart';
import 'navigation_events.dart';

/// Unified widget for handling navigation input from keyboard and gestures
///
/// This widget wraps the application content and listens to both keyboard
/// and gesture inputs, converting them to navigation events that are then
/// processed by the DeckController.
///
/// Supported inputs:
/// - Keyboard: Meta + Arrow keys (previous/next slide)
/// - Gestures: Tap left/right, Swipe left/right
class NavigationInputListener extends StatefulWidget {
  const NavigationInputListener({super.key, required this.child});

  final Widget child;

  @override
  State<NavigationInputListener> createState() =>
      _NavigationInputListenerState();
}

class _NavigationInputListenerState extends State<NavigationInputListener> {
  final _keyboardHandler = KeyboardNavigationHandler();
  final _gestureHandler = GestureNavigationHandler();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted) return false;

    final navigationEvent = _keyboardHandler.handleKey(event);
    if (navigationEvent == null) return false;

    final presentation = DeckController.of(context).presentation;
    _dispatch(presentation, navigationEvent);

    return true;
  }

  void _dispatch(DeckPresentationState presentation, NavigationEvent? event) {
    if (event == null) return;
    switch (event) {
      case NextSlideEvent():
        presentation.nextSlide();
      case PreviousSlideEvent():
        presentation.previousSlide();
      case GoToSlideEvent(:final index):
        presentation.goToSlide(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final presentation = DeckController.of(context).presentation;

    return SignalBuilder(
      builder: (context) {
        final isMenuOpen = presentation.isMenuOpen.value;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: isMenuOpen
              ? null
              : (details) {
                  final event = _gestureHandler.handleTap(details, size);
                  _dispatch(presentation, event);
                },
          onHorizontalDragStart: isMenuOpen
              ? null
              : (details) {
                  _gestureHandler.handleDragStart(details);
                },
          onHorizontalDragEnd: isMenuOpen
              ? null
              : (details) {
                  final event = _gestureHandler.handleSwipe(details);
                  _dispatch(presentation, event);
                },
          child: widget.child,
        );
      },
    );
  }
}
