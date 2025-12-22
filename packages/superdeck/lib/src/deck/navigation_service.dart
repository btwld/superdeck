import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'slide_page_content.dart';

/// Service for deck navigation and routing operations.
///
/// Handles router creation, slide transitions, and navigation logic.
/// Uses index deduplication to prevent redundant callbacks during rebuilds.
class NavigationService {
  /// Default transition duration for slide animations.
  static const _defaultTransitionDuration = Duration(seconds: 1);

  /// Configurable transition duration for testing.
  final Duration transitionDuration;

  /// Tracks last notified index to prevent duplicate callbacks.
  /// The pageBuilder can be called multiple times during rebuilds,
  /// but we only want to notify when the index actually changes.
  int? _lastNotifiedIndex;

  /// Creates a NavigationService with optional custom transition duration.
  ///
  /// [transitionDuration] can be shortened for testing or adjusted for UX.
  NavigationService({Duration? transitionDuration})
      : transitionDuration = transitionDuration ?? _defaultTransitionDuration;

  /// Creates a GoRouter configured for slide navigation.
  ///
  /// The [onIndexChanged] callback is invoked only when the index actually
  /// changes, not on every rebuild. This prevents redundant state updates.
  GoRouter createRouter({
    required void Function(int) onIndexChanged,
  }) {
    return GoRouter(
      initialLocation: '/slides/0',
      // Handle root path - can occur on initial load or direct URL access
      redirect: (context, state) {
        if (state.uri.path == '/') {
          return '/slides/0';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/slides/:index',
          pageBuilder: (context, state) {
            final index = _parseIndex(state.pathParameters['index']);

            // Only notify if index actually changed - prevents redundant
            // callbacks during widget rebuilds, hot reload, etc.
            if (_lastNotifiedIndex != index) {
              _lastNotifiedIndex = index;
              onIndexChanged(index);
            }

            return CustomTransitionPage(
              key: ValueKey('slide-$index'),
              child: SlidePageContent(index: index),
              transitionDuration: transitionDuration,
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
      await Future.delayed(transitionDuration);
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
