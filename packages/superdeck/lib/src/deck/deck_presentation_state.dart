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
  bool _disposed = false;

  late final GoRouter router = GoRouter(
    initialLocation: '/slides/0',
    redirect: (context, state) => state.uri.path == '/' ? '/slides/0' : null,
    routes: [
      GoRoute(
        path: '/slides/:index',
        pageBuilder: (context, state) {
          final index = _parseIndex(state.pathParameters['index']);
          _writeClampedIndex(index);
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
    _indexClampEffect = effect(() {
      _slides.value.length; // explicit trigger on slide count change
      final currentIdx = _currentIndex.peek();
      final clamped = _clampIndex(currentIdx, _slides.value.length);
      if (currentIdx != clamped) {
        _currentIndex.value = clamped;
      }
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
    _isTransitioning.value = true;
    router.go('/slides/$index');
    await Future<void>.delayed(_transitionDuration);
    if (_disposed) return;
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
    if (slides.isEmpty) return;

    final validKeys = slides.map((s) => s.key).toSet();
    final current = _thumbnails.value;
    final staleKeys = current.keys
        .where((k) => !validKeys.contains(k))
        .toList(growable: false);
    final cache = staleKeys.isEmpty
        ? current
        : Map<String, AsyncThumbnail>.from(current);

    for (final key in staleKeys) {
      cache.remove(key)?.dispose();
    }
    if (staleKeys.isNotEmpty) {
      _thumbnails.value = cache;
    }

    _thumbnailService.generateThumbnails(
      slides: slides,
      context: context,
      cache: cache,
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

  void dispose() {
    _disposed = true;
    _indexClampEffect?.call();
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

  void _syncCurrentIndexFromRouter() {
    if (_disposed) return;
    final path = router.routeInformationProvider.value.uri.path;
    const prefix = '/slides/';
    if (!path.startsWith(prefix)) return;
    _writeClampedIndex(_parseIndex(path.substring(prefix.length)));
  }

  void _writeClampedIndex(int index) {
    final clamped = _clampIndex(index, _slides.value.length);
    if (_currentIndex.value != clamped) {
      _currentIndex.value = clamped;
    }
  }

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
