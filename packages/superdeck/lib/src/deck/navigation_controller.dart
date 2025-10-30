import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'navigation_events.dart';
import 'slide_page_content.dart';

/// Core navigation controller for deck presentation
///
/// Manages all navigation state including current slide index, history,
/// transitions, and routing. Uses ChangeNotifier for reactive state management.
class NavigationController extends ChangeNotifier {
  // Dependencies - callback to get total slides instead of signal dependency
  final int Function() getTotalSlides;

  static const _transitionDuration = Duration(seconds: 1);

  // Private state fields
  int _currentIndex = 0;
  final List<int> _history = [];
  bool _isTransitioning = false;

  // Router
  late final GoRouter router;

  NavigationController({required this.getTotalSlides}) {
    // Initialize router
    router = _buildRouter();
  }

  // Public getters
  int get currentIndex => _currentIndex;
  List<int> get history => List.unmodifiable(_history);
  bool get isTransitioning => _isTransitioning;

  // Computed getters
  int get totalSlides => getTotalSlides();
  bool get canGoNext => _currentIndex < totalSlides - 1;
  bool get canGoPrevious => _currentIndex > 0;
  bool get canGoBack => _history.isNotEmpty;

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/slides/0',
      redirect: (context, state) {
        if (state.path == '/') return '/slides/0';
        return null;
      },
      routes: [
        GoRoute(
          path: '/slides/:index',
          pageBuilder: (context, state) {
            final index = _parseSlideIndex(state.pathParameters['index']);

            return CustomTransitionPage(
              key: ValueKey('slide-$index'),
              // Slide content comes from context via SlidePageContent widget
              child: SlidePageContent(index: index),
              transitionDuration: _transitionDuration,
              reverseTransitionDuration: _transitionDuration,
              transitionsBuilder: _fadeTransition,
            );
          },
        ),
      ],
    );
  }

  // Navigation methods - router is the source of truth

  /// Navigate to a specific slide by index
  ///
  /// Adds current index to history before navigating.
  /// Sets transitioning state during navigation.
  Future<void> goToSlide(int index) async {
    if (index >= 0 && index < totalSlides) {
      // Add current index to history before navigating
      if (_currentIndex != index) {
        _history.add(_currentIndex);
      }

      _isTransitioning = true;
      notifyListeners();

      router.go('/slides/$index');

      // Reset transitioning state after a brief delay
      await Future.delayed(_transitionDuration);
      _isTransitioning = false;
      notifyListeners();
    }
  }

  /// Navigate to the next slide
  Future<void> nextSlide() async {
    if (canGoNext) {
      await goToSlide(_currentIndex + 1);
    }
  }

  /// Navigate to the previous slide
  Future<void> previousSlide() async {
    if (canGoPrevious) {
      await goToSlide(_currentIndex - 1);
    }
  }

  /// Navigate back to the previous slide in history
  ///
  /// This is different from previousSlide() - it follows the actual
  /// navigation history rather than just going to index - 1.
  Future<void> goBack() async {
    if (canGoBack) {
      final previousIndex = _history.last;
      // Remove from history
      _history.removeLast();

      _isTransitioning = true;
      notifyListeners();

      router.go('/slides/$previousIndex');

      await Future.delayed(_transitionDuration);
      _isTransitioning = false;
      notifyListeners();
    }
  }

  /// Handles navigation events from input handlers
  ///
  /// This is the central entry point for all navigation events,
  /// dispatching them to the appropriate navigation methods.
  void handleNavigationEvent(NavigationEvent event) {
    switch (event) {
      case NextSlideEvent():
        nextSlide();
      case PreviousSlideEvent():
        previousSlide();
      case GoToSlideEvent(:final index):
        goToSlide(index);
    }
  }

  /// Updates the current index (called by route sync)
  ///
  /// Internal method used to sync the controller state with the router state.
  void updateCurrentIndex(int index) {
    final maxIndex = totalSlides > 0 ? totalSlides - 1 : 0;
    final clampedIndex = index.clamp(0, maxIndex);

    if (_currentIndex != clampedIndex) {
      _currentIndex = clampedIndex;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // ChangeNotifier handles cleanup
    super.dispose();
  }

  // Helper methods for router
  int _parseSlideIndex(String? indexParam) {
    return int.tryParse(indexParam ?? '0') ?? 0;
  }

  Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
