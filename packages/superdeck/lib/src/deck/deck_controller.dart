import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../export/async_thumbnail.dart';
import '../export/thumbnail_service.dart';
import '../ui/widgets/provider.dart';
import '../utils/asset_cache_store.dart';
import 'deck_options.dart';
import 'navigation_events.dart';
import 'navigation_service.dart';
import 'slide_configuration.dart';
import 'slide_configuration_builder.dart';
import 'superdeck_plugin.dart';

/// Unified facade for all deck state and operations
///
/// Manages reactive state with signals and delegates navigation and
/// thumbnails to focused collaborators. Subscribes directly to a
/// [DeckLoader.load] stream for deck loading and rebuild watching.
class DeckController {
  late final GoRouter router;

  final DeckLoader _deckLoader;
  final NavigationService _navigationService;
  final ThumbnailService _thumbnailService;
  final List<SuperDeckPlugin> _plugins;

  bool _disposed = false;
  StreamSubscription<SlidesEvent>? _subscription;

  final _loadedSlides = signal<List<Slide>?>(null);
  final _isLoading = signal<bool>(true);
  final _error = signal<Object?>(null);
  final _isBuildActive = signal<bool>(false);
  final _buildFailure = signal<DeckBuildError?>(null);

  final _options = signal<DeckOptions>(DeckOptions());

  final _isMenuOpen = signal<bool>(false);
  final _isNotesOpen = signal<bool>(false);

  final _currentIndex = signal<int>(0);
  final _isTransitioning = signal<bool>(false);

  final _thumbnails = signal<Map<String, AsyncThumbnail>>({});

  EffectCleanup? _indexClampEffect;

  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final loadedSlides = _loadedSlides.value;
    if (loadedSlides == null) return <SlideConfiguration>[];
    return const SlideConfigurationBuilder().buildConfigurations(
      loadedSlides,
      _options.value,
    );
  });

  late final ReadonlySignal<int> totalSlides = computed(
    () => slides.value.length,
  );
  ReadonlySignal<bool> get isLoading => _isLoading;
  late final ReadonlySignal<bool> hasError = computed(
    () => _error.value != null && _loadedSlides.value == null,
  );
  ReadonlySignal<Object?> get error => _error;
  ReadonlySignal<DeckBuildError?> get buildFailure => _buildFailure;

  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  ReadonlySignal<bool> get isBuildActive => _isBuildActive;
  List<SuperDeckPlugin> get plugins => _plugins;

  ReadonlySignal<int> get currentIndex => _currentIndex;
  ReadonlySignal<bool> get isTransitioning => _isTransitioning;
  late final ReadonlySignal<bool> canGoNext = computed(
    () => _currentIndex.value < totalSlides.value - 1,
  );
  late final ReadonlySignal<bool> canGoPrevious = computed(
    () => _currentIndex.value > 0,
  );
  late final ReadonlySignal<SlideConfiguration?> currentSlide = computed(() {
    final index = _currentIndex.value;
    final slidesList = slides.value;
    return index >= 0 && index < slidesList.length ? slidesList[index] : null;
  });

  DeckController({
    required DeckLoader deckLoader,
    required DeckOptions options,
    NavigationService? navigationService,
    ThumbnailService? thumbnailService,
  }) : _deckLoader = deckLoader,
       _navigationService = navigationService ?? NavigationService(),
       _thumbnailService =
           thumbnailService ??
           ThumbnailService(cacheStore: RuntimeAssetCacheStore()),
       _plugins = options.plugins {
    _options.value = options.copyWith(plugins: _plugins);
    final pluginRoutes = _plugins
        .expand((plugin) => plugin.buildRoutes())
        .toList(growable: false);

    router = _navigationService.createRouter(
      onIndexChanged: (index) => _updateCurrentIndex(index),
      additionalRoutes: pluginRoutes,
    );

    _indexClampEffect = effect(() {
      final currentIdx = _currentIndex.peek();
      final clamped = _clampIndex(currentIdx);
      if (_currentIndex.value != clamped) {
        _currentIndex.value = clamped;
      }
    });

    _subscribe();
  }

  void _subscribe() {
    _subscription = _deckLoader.load().listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        debugPrint('[DeckController] Loader stream error: $error');
      },
    );
  }

  void _handleEvent(SlidesEvent event) {
    if (_disposed) return;

    switch (event) {
      case SlidesLoadingEvent():
        _isLoading.value = true;
        _error.value = null;
      case SlidesLoadedEvent(:final slides):
        _loadedSlides.value = List<Slide>.unmodifiable(slides);
        _isLoading.value = false;
        _error.value = null;
        _isBuildActive.value = false;
        _buildFailure.value = null;
      case SlidesErrorEvent(:final message, :final error):
        if (_loadedSlides.value != null) {
          _isLoading.value = false;
          _isBuildActive.value = false;
          _buildFailure.value = error is DeckBuildError
              ? error
              : DeckBuildError(message: message);
        } else {
          _error.value = error ?? message;
          _isLoading.value = false;
          _isBuildActive.value = false;
          _buildFailure.value = null;
        }
      case SlidesRebuildingEvent():
        _isBuildActive.value = true;
        _buildFailure.value = null;
    }
  }

  @internal
  void updateOptions(DeckOptions newOptions) {
    if (_disposed) return;
    final normalizedOptions = identical(newOptions.plugins, _plugins)
        ? newOptions
        : newOptions.copyWith(plugins: _plugins);

    if (_options.value != normalizedOptions) {
      _options.value = normalizedOptions;
    }
  }

  Future<void> reloadDeck() async {
    if (_disposed) return;
    _error.value = null;
    _buildFailure.value = null;
    _isBuildActive.value = false;
    _isLoading.value = true;
    await _deckLoader.reload();
  }

  void openMenu() => _isMenuOpen.value = true;
  void closeMenu() => _isMenuOpen.value = false;
  void toggleNotes() => _isNotesOpen.value = !_isNotesOpen.value;

  Future<void> goToSlide(int index) async {
    await _navigationService.goToSlide(
      router: router,
      targetIndex: index,
      totalSlides: totalSlides.value,
      onTransitionStart: () => _isTransitioning.value = true,
      onTransitionEnd: () {
        if (_disposed) return;
        _isTransitioning.value = false;
      },
    );
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

  @internal
  Future<void> handleNavigationEvent(NavigationEvent event) async {
    switch (event) {
      case NextSlideEvent():
        await nextSlide();
      case PreviousSlideEvent():
        await previousSlide();
      case GoToSlideEvent(:final index):
        await goToSlide(index);
    }
  }

  void _updateCurrentIndex(int index) {
    if (_disposed) return;
    final clampedIndex = _clampIndex(index);

    if (_currentIndex.value != clampedIndex) {
      _currentIndex.value = clampedIndex;
    }
  }

  int _clampIndex(int index) {
    final total = totalSlides.value;
    final maxIndex = total > 0 ? total - 1 : 0;
    return index.clamp(0, maxIndex);
  }

  void generateThumbnails(BuildContext context, {bool force = false}) {
    if (_disposed) return;

    final currentSlides = slides.value;
    final currentSlideKeys = currentSlides.map((s) => s.key).toSet();

    final currentCache = _thumbnails.value;
    final staleKeys = currentCache.keys
        .where((k) => !currentSlideKeys.contains(k))
        .toList();

    if (staleKeys.isNotEmpty) {
      for (final key in staleKeys) {
        currentCache[key]?.dispose();
      }
      final cleanedCache = Map<String, AsyncThumbnail>.from(currentCache)
        ..removeWhere((k, _) => staleKeys.contains(k));
      _thumbnails.value = cleanedCache;
    }

    _thumbnailService.generateThumbnails(
      slides: currentSlides,
      context: context,
      cache: _thumbnails.value,
      onCacheUpdate: (cache) {
        if (!_disposed) {
          _thumbnails.value = cache;
        }
      },
      force: force,
    );
  }

  AsyncThumbnail? getThumbnail(String slideKey) {
    return _thumbnails.value[slideKey];
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _indexClampEffect?.call();

    unawaited(_subscription?.cancel());
    unawaited(_deckLoader.dispose());

    router.dispose();

    for (final thumbnail in _thumbnails.value.values) {
      thumbnail.dispose();
    }

    _loadedSlides.dispose();
    _isLoading.dispose();
    _error.dispose();
    _isBuildActive.dispose();
    _buildFailure.dispose();
    _options.dispose();
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _currentIndex.dispose();
    _isTransitioning.dispose();
    _thumbnails.dispose();

    slides.dispose();
    totalSlides.dispose();
    hasError.dispose();
    canGoNext.dispose();
    canGoPrevious.dispose();
    currentSlide.dispose();
  }

  static DeckController of(BuildContext context) {
    return InheritedData.of<DeckController>(context);
  }
}
