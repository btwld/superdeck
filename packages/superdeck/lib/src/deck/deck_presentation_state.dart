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
          _updateCurrentIndex(index);
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

  Future<void> goToSlide(int index, int totalSlides) async {
    if (_disposed || index < 0 || index >= totalSlides) return;
    _currentIndex.value = index;
    _isTransitioning.value = true;
    router.go('/slides/$index');
    await Future<void>.delayed(_transitionDuration);
    if (_disposed) return;
    _isTransitioning.value = false;
  }

  void generateThumbnails(
    BuildContext context,
    List<SlideConfiguration> slides, {
    bool force = false,
  }) {
    if (_disposed) return;
    if (slides.isEmpty) return;
    final cache = _reconcileThumbnailCache(slides);
    _thumbnailService.generateThumbnails(
      slides: slides,
      context: context,
      cache: cache,
      onCacheUpdate: _updateThumbnails,
      force: force,
    );
  }

  AsyncThumbnail? getThumbnail(String slideKey) {
    return _thumbnails.value[slideKey];
  }

  void dispose() {
    _disposed = true;
    _indexClampEffect?.call();
    router.dispose();
    for (final thumbnail in _thumbnails.value.values) {
      thumbnail.dispose();
    }
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _currentIndex.dispose();
    _isTransitioning.dispose();
    _thumbnails.dispose();
  }

  void _updateThumbnails(Map<String, AsyncThumbnail> cache) {
    if (_disposed) return;
    _thumbnails.value = cache;
  }

  Map<String, AsyncThumbnail> _reconcileThumbnailCache(
    List<SlideConfiguration> slides,
  ) {
    final validSlideKeys = slides.map((slide) => slide.key).toSet();
    final currentCache = _thumbnails.value;
    final staleKeys = currentCache.keys
        .where((key) => !validSlideKeys.contains(key))
        .toList(growable: false);

    if (staleKeys.isEmpty) {
      return currentCache;
    }

    final cleanedCache = Map<String, AsyncThumbnail>.from(currentCache);
    for (final key in staleKeys) {
      cleanedCache.remove(key)?.dispose();
    }
    _thumbnails.value = cleanedCache;
    return cleanedCache;
  }

  void _updateCurrentIndex(int index) {
    final clampedIndex = _clampIndex(index, _slides.value.length);
    if (_currentIndex.value != clampedIndex) {
      _currentIndex.value = clampedIndex;
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
