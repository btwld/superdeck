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
  // ========================================
  // DEPENDENCIES
  // ========================================

  final DeckConfiguration _configuration;
  final DeckLoader _deckLoader;
  final NavigationService _navigationService;
  final ThumbnailService _thumbnailService;
  final List<SuperDeckPlugin> _plugins;

  bool _disposed = false;
  StreamSubscription<DeckEvent>? _subscription;

  // ========================================
  // INTERNAL STATE (Private Signals)
  // ========================================

  // Deck state
  final _currentDeck = signal<Deck?>(null);
  final _isLoading = signal<bool>(true);
  final _error = signal<Object?>(null);
  final _isBuildActive = signal<bool>(false);
  final _buildFailure = signal<DeckBuildError?>(null);

  // Deck options
  final _options = signal<DeckOptions>(DeckOptions());

  // UI state
  final _isMenuOpen = signal<bool>(false);
  final _isNotesOpen = signal<bool>(false);

  // Navigation state
  final _currentIndex = signal<int>(0);
  final _isTransitioning = signal<bool>(false);

  // Thumbnail state
  final _thumbnails = signal<Map<String, AsyncThumbnail>>({});

  // Router (required by MaterialApp)
  late final GoRouter router;

  EffectCleanup? _indexClampEffect;

  // ========================================
  // COMPUTED STATE (Read-Only Public API)
  // ========================================

  // Deck computeds
  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final deck = _currentDeck.value;
    if (deck == null) return <SlideConfiguration>[];
    final configuration = _resolveDeckConfiguration(deck);
    return SlideConfigurationBuilder(
      configuration: configuration,
    ).buildConfigurations(deck.slides, _options.value);
  });

  late final ReadonlySignal<int> totalSlides = computed(
    () => slides.value.length,
  );
  ReadonlySignal<bool> get isLoading => _isLoading;
  late final ReadonlySignal<bool> hasError = computed(
    () => _error.value != null && _currentDeck.value == null,
  );
  ReadonlySignal<Object?> get error => _error;
  ReadonlySignal<DeckBuildError?> get buildFailure => _buildFailure;

  // UI computeds
  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  ReadonlySignal<bool> get isBuildActive => _isBuildActive;
  List<SuperDeckPlugin> get plugins => _plugins;

  // Navigation computeds
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

  // ========================================
  // CONSTRUCTOR
  // ========================================

  DeckController({
    required DeckConfiguration configuration,
    required DeckLoader deckLoader,
    required DeckOptions options,
    NavigationService? navigationService,
    ThumbnailService? thumbnailService,
  }) : _configuration = configuration,
       _deckLoader = deckLoader,
       _navigationService = navigationService ?? NavigationService(),
       _thumbnailService =
           thumbnailService ??
           ThumbnailService(
             cacheStore: createAssetCacheStore(configuration: configuration),
           ),
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
      final total = totalSlides.value;
      final maxIndex = total > 0 ? total - 1 : 0;
      final currentIdx = _currentIndex.peek();
      final clamped = currentIdx.clamp(0, maxIndex);
      if (_currentIndex.value != clamped) {
        _currentIndex.value = clamped;
      }
    });

    _subscribe();
  }

  // ========================================
  // DECK LOADER EVENT HANDLING
  // ========================================

  void _subscribe() {
    _subscription = _deckLoader.load().listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        debugPrint('[DeckController] Loader stream error: $error');
      },
    );
  }

  void _handleEvent(DeckEvent event) {
    if (_disposed) return;

    switch (event) {
      case DeckLoadingEvent():
        _isLoading.value = true;
        _error.value = null;
      case DeckLoadedEvent(:final deck):
        _currentDeck.value = deck;
        _isLoading.value = false;
        _error.value = null;
        _isBuildActive.value = false;
        _buildFailure.value = null;
      case DeckErrorEvent(:final message, :final error):
        if (_currentDeck.value != null) {
          _isLoading.value = false;
          _isBuildActive.value = false;
          _buildFailure.value = error is DeckBuildError
              ? error
              : DeckBuildError(type: 'BuildFailure', message: message);
        } else {
          _error.value = error ?? message;
          _isLoading.value = false;
        }
      case DeckRebuildingEvent():
        _isBuildActive.value = true;
    }
  }

  // ========================================
  // DECK OPERATIONS
  // ========================================

  DeckConfiguration _resolveDeckConfiguration(Deck deck) {
    final deckConfiguration = deck.configuration;
    return _hasExplicitConfigurationOverrides(deckConfiguration)
        ? deckConfiguration
        : _configuration;
  }

  bool _hasExplicitConfigurationOverrides(DeckConfiguration configuration) {
    return configuration.projectDir != null ||
        configuration.slidesPath != null ||
        configuration.outputDir != null ||
        configuration.assetsPath != null;
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
    await _subscription?.cancel();
    _error.value = null;
    _buildFailure.value = null;
    _isBuildActive.value = false;
    _isLoading.value = true;
    _subscribe();
  }

  // ========================================
  // UI ACTIONS
  // ========================================

  void openMenu() => _isMenuOpen.value = true;
  void closeMenu() => _isMenuOpen.value = false;
  void toggleNotes() => _isNotesOpen.value = !_isNotesOpen.value;

  // ========================================
  // NAVIGATION ACTIONS
  // ========================================

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

    final maxIndex = totalSlides.value > 0 ? totalSlides.value - 1 : 0;
    final clampedIndex = index.clamp(0, maxIndex);

    if (_currentIndex.value != clampedIndex) {
      _currentIndex.value = clampedIndex;
    }
  }

  // ========================================
  // THUMBNAIL ACTIONS
  // ========================================

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

  // ========================================
  // LIFECYCLE
  // ========================================

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

    // Dispose signals
    _currentDeck.dispose();
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

    // Dispose computed signals
    slides.dispose();
    totalSlides.dispose();
    hasError.dispose();
    canGoNext.dispose();
    canGoPrevious.dispose();
    currentSlide.dispose();
  }

  // ========================================
  // STATIC ACCESS
  // ========================================

  static DeckController of(BuildContext context) {
    return InheritedData.of<DeckController>(context);
  }
}
