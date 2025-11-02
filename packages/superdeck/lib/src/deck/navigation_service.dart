import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'slide_page_content.dart';

/// Stateless service for deck navigation and routing operations.
///
/// Handles router creation, slide transitions, and navigation logic without
/// maintaining any state. All state is managed by the controller that uses
/// this service.
class NavigationService {
  static const _transitionDuration = Duration(seconds: 1);

  /// Creates a GoRouter configured for slide navigation.
  ///
  /// The [onIndexChanged] callback is invoked whenever the route changes,
  /// allowing the controller to synchronize its internal state.
  GoRouter createRouter({
    required void Function(int) onIndexChanged,
  }) {
    return GoRouter(
      initialLocation: '/slides/0',
      routes: [
        GoRoute(
          path: '/slides/:index',
          pageBuilder: (context, state) {
            final index = _parseIndex(state.pathParameters['index']);
            onIndexChanged(index); // Notify controller
            return CustomTransitionPage(
              key: ValueKey('slide-$index'),
              child: SlidePageContent(index: index),
              transitionDuration: _transitionDuration,
              transitionsBuilder: _fadeTransition,
            );
          },
        ),
      ],
    );
  }

  /// Navigates to a specific slide with transition handling.
  ///
  /// Validates that [targetIndex] is within bounds before navigating.
  /// Calls [onTransitionStart] before navigation and [onTransitionEnd]
  /// after the transition completes.
  Future<void> goToSlide({
    required GoRouter router,
    required int targetIndex,
    required int totalSlides,
    required void Function() onTransitionStart,
    required void Function() onTransitionEnd,
  }) async {
    if (targetIndex >= 0 && targetIndex < totalSlides) {
      onTransitionStart();
      router.go('/slides/$targetIndex');
      await Future.delayed(_transitionDuration);
      onTransitionEnd();
    }
  }

  /// Parses slide index from route parameter, defaulting to 0 on error.
  int _parseIndex(String? param) => int.tryParse(param ?? '0') ?? 0;

  /// Fade transition animation for slide changes.
  Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
