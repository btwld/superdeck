import 'package:flutter/widgets.dart';

import 'deck_controller.dart';
import 'navigation_events.dart';

/// Unified widget for handling navigation input from keyboard and gestures
///
/// This widget wraps the application content and listens to both keyboard
/// and gesture inputs, converting them to navigation events that are then
/// processed by the DeckController.
///
/// Supported inputs:
/// - Keyboard: Meta + Arrow keys (Command + Arrow on macOS)
/// - Gestures: Tap left/right, Swipe left/right
class NavigationManager extends StatefulWidget {
  const NavigationManager({super.key, required this.child});

  final Widget child;

  @override
  State<NavigationManager> createState() => _NavigationManagerState();
}

class _NavigationManagerState extends State<NavigationManager> {
  final _keyboardHandler = KeyboardNavigationHandler();
  final _gestureHandler = GestureNavigationHandler();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus on mount to ensure keyboard events are captured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleNavigationEvent(NavigationEvent? event) {
    if (event == null) return;

    final deck = DeckController.of(context);
    deck.handleNavigationEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        final navigationEvent = _keyboardHandler.handleKey(event);
        _handleNavigationEvent(navigationEvent);

        // Return handled if we processed the event, otherwise ignored
        return navigationEvent != null
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          final event = _gestureHandler.handleTap(details, size);
          _handleNavigationEvent(event);
        },
        onHorizontalDragStart: (details) {
          _gestureHandler.handleDragStart(details);
        },
        onHorizontalDragEnd: (details) {
          final event = _gestureHandler.handleSwipe(details);
          _handleNavigationEvent(event);
        },
        child: widget.child,
      ),
    );
  }
}
