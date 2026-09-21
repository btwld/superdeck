import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals.dart';

import '../thumbnails/async_thumbnail.dart';
import '../thumbnails/thumbnail_service.dart';
import 'slide_configuration.dart';
import 'slide_page_content.dart';

final class DeckPresentationState {
  final ThumbnailService _thumbnailService;
  final Duration _transitionDuration;
  final ReadonlySignal<List<SlideConfiguration>> _slides;

  final _isMenuOpen = signal<bool>(false);
  final _isNotesOpen = signal<bool>(false);
  final _currentIndex = signal<int>(0);
  final _isTransitioning = signal<bool>(false);
  final _thumbnails = signal<Map<String, AsyncThumbnail>>({});

  EffectCleanup? _indexClampEffect;
  EffectCleanup? _thumbnailPruneEffect;
  int _transitionOperation = 0;
  bool _disposed = false;

  late final GoRouter router = GoRouter(
    initialLocation: '/slides/0',
    redirect: (context, state) => state.uri.path == '/' ? '/slides/0' : null,
    routes: [
      GoRoute(
        path: '/slides/:index',
        pageBuilder: (context, state) {
          final index = _parseIndex(state.pathParameters['index']);

          return CustomTransitionPage(
            key: ValueKey<String>('slide-$index'),
            child: SlidePageContent(index: index),
            transitionDuration: _transitionDuration,
            transitionsBuilder: _fadeTransition,
          );
        },
      ),
    ],
  );

  DeckPresentationState({
    required ThumbnailService thumbnailService,
    required ReadonlySignal<List<SlideConfiguration>> slides,
    Duration transitionDuration = const Duration(seconds: 1),
  }) : _thumbnailService = thumbnailService,
       _transitionDuration = transitionDuration,
       _slides = slides {
    router.routeInformationProvider.addListener(_syncCurrentIndexFromRouter);
    // Runs once here, so the first route is read explicitly rather than
    // waiting for a navigation, and again whenever the deck changes size.
    _indexClampEffect = effect(() {
      _slides.value.length; // explicit trigger on slide count change
      _syncCurrentIndexFromRouter();
    });
    // Thumbnail cleanup follows the slide collection, not thumbnail warmup,
    // so obsolete handles are released even when the deck becomes empty.
    _thumbnailPruneEffect = effect(() {
      _pruneThumbnails(_slideKeys(_slides.value));
    });
  }

  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  ReadonlySignal<int> get currentIndex => _currentIndex;
  ReadonlySignal<bool> get isTransitioning => _isTransitioning;

  late final ReadonlySignal<int> totalSlides = computed(
    () => _slides.value.length,
  );
  late final ReadonlySignal<bool> canGoNext = computed(
    () => _currentIndex.value < _slides.value.length - 1,
  );
  late final ReadonlySignal<bool> canGoPrevious = computed(
    () => _currentIndex.value > 0,
  );
  late final ReadonlySignal<SlideConfiguration?> currentSlide = computed(() {
    final index = _currentIndex.value;
    final list = _slides.value;
    return index >= 0 && index < list.length ? list[index] : null;
  });

  void openMenu() {
    if (_disposed) return;
    _isMenuOpen.value = true;
  }

  void closeMenu() {
    if (_disposed) return;
    _isMenuOpen.value = false;
  }

  void toggleNotes() {
    if (_disposed) return;
    _isNotesOpen.value = !_isNotesOpen.value;
  }

  Future<void> goToSlide(int index) async {
    if (_disposed || index < 0 || index >= _slides.value.length) return;
    // Only the latest transition may clear the transitioning state, so an
    // earlier delay cannot end a transition that started after it.
    final operation = ++_transitionOperation;
    _isTransitioning.value = true;
    router.go('/slides/$index');
    await Future<void>.delayed(_transitionDuration);
    if (_disposed || operation != _transitionOperation) return;
    _isTransitioning.value = false;
  }

  Future<void> nextSlide() async {
    if (canGoNext.value) {
      await goToSlide(_currentIndex.value + 1);
    }
  }

  Future<void> previousSlide() async {
    if (canGoPrevious.value) {
      await goToSlide(_currentIndex.value - 1);
    }
  }

  void generateThumbnails(
    BuildContext context,
    List<SlideConfiguration> slides, {
    bool force = false,
  }) {
    if (_disposed) return;

    _pruneThumbnails(_slideKeys(slides));
    if (slides.isEmpty) return;

    _thumbnailService.generateThumbnails(
      slides: slides,
      context: context,
      cache: _thumbnails.peek(),
      onCacheUpdate: (updated) {
        if (_disposed) return;
        _thumbnails.value = updated;
      },
      force: force,
    );
  }

  AsyncThumbnail? getThumbnail(String slideKey) {
    return _thumbnails.value[slideKey];
  }

  /// Deletes every cached thumbnail (in-memory and persistent).
  ///
  /// After this completes, [getThumbnail] returns `null` for every slide
  /// until [generateThumbnails] is called again.
  Future<void> deleteAllThumbnails() async {
    if (_disposed) return;
    await _thumbnailService.deleteAllThumbnails(
      slides: _slides.value,
      cache: _thumbnails.value,
      onCacheUpdate: (updated) {
        if (_disposed) return;
        _thumbnails.value = updated;
      },
    );
  }

  void dispose() {
    _disposed = true;
    _indexClampEffect?.call();
    _thumbnailPruneEffect?.call();
    router.routeInformationProvider.removeListener(_syncCurrentIndexFromRouter);
    router.dispose();
    for (final thumbnail in _thumbnails.value.values) {
      thumbnail.dispose();
    }
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _currentIndex.dispose();
    _isTransitioning.dispose();
    _thumbnails.dispose();
    totalSlides.dispose();
    canGoNext.dispose();
    canGoPrevious.dispose();
    currentSlide.dispose();
  }

  /// Disposes and drops every thumbnail whose slide is no longer present.
  void _pruneThumbnails(Set<String> validKeys) {
    if (_disposed) return;

    final current = _thumbnails.peek();
    final staleKeys = current.keys
        .where((key) => !validKeys.contains(key))
        .toList(growable: false);
    if (staleKeys.isEmpty) return;

    final cache = Map<String, AsyncThumbnail>.from(current);
    for (final key in staleKeys) {
      cache.remove(key)?.dispose();
    }
    _thumbnails.value = cache;
  }

  /// Makes the route the single authority for the active slide.
  ///
  /// The route decides [currentIndex]. A route outside a loaded deck is
  /// corrected once, by replacing it with the nearest slide that exists;
  /// `replace` keeps that correction out of the browser history on web, which
  /// `go` would add. While the deck is empty the route is left alone, so a
  /// deep link opened before the deck loads still lands on its slide.
  void _syncCurrentIndexFromRouter() {
    if (_disposed) return;
    final path = router.routeInformationProvider.value.uri.path;
    const prefix = '/slides/';
    if (!path.startsWith(prefix)) return;

    final total = _slides.peek().length;
    final routeIndex = _parseIndex(path.substring(prefix.length));
    final clamped = _clampIndex(routeIndex, total);
    if (total > 0 && clamped != routeIndex) {
      // The replacement reports a new route, which syncs the index below.
      router.replace('$prefix$clamped');

      return;
    }
    if (_currentIndex.peek() != clamped) {
      _currentIndex.value = clamped;
    }
  }

  static Set<String> _slideKeys(List<SlideConfiguration> slides) =>
      slides.map((slide) => slide.key).toSet();

  static int _clampIndex(int index, int totalSlides) {
    final maxIndex = totalSlides > 0 ? totalSlides - 1 : 0;
    return index.clamp(0, maxIndex);
  }

  static int _parseIndex(String? param) => int.tryParse(param ?? '0') ?? 0;

  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
