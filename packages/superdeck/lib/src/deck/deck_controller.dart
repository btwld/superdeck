import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../export/async_thumbnail.dart';
import '../export/thumbnail_service.dart';
import '../ui/widgets/provider.dart';
import '../utils/constants.dart';
import 'deck_options.dart';
import 'navigation_events.dart';
import 'navigation_service.dart';
import 'slide_configuration.dart';
import 'slide_configuration_builder.dart';

/// Loading state for the deck
enum DeckLoadingState { idle, loading, loaded, error }

/// Unified facade for all deck state and operations
///
/// Manages reactive state with signals and delegates operations to
/// stateless services. Consolidates deck, navigation, and thumbnail
/// concerns under a single controller.
class DeckController {
  // ========================================
  // DEPENDENCIES (Private Services)
  // ========================================

  final DeckService _deckService;
  final NavigationService _navigationService;
  final ThumbnailService _thumbnailService;
  final SlideConfigurationBuilder _slideBuilder;
  final bool _enableDeckStream;

  // Disposal guard to prevent accessing disposed signals
  // ignore: prefer_final_fields
  bool _disposed = false;

  // ========================================
  // INTERNAL STATE (Private Signals)
  // ========================================

  // Deck state
  final _loadingState = signal<DeckLoadingState>(DeckLoadingState.idle);
  final _currentDeck = signal<Deck?>(null);
  final _error = signal<Object?>(null);
  final _options = signal<DeckOptions>(DeckOptions()); // NEVER exposed

  // UI state
  final _isMenuOpen = signal<bool>(false);
  final _isNotesOpen = signal<bool>(false);
  final _isRebuilding = signal<bool>(false);

  // Navigation state
  final _currentIndex = signal<int>(0);
  final _isTransitioning = signal<bool>(false);

  // Thumbnail state
  final _thumbnails = signal<Map<String, AsyncThumbnail>>({});

  // Router (required by MaterialApp)
  late final GoRouter router;

  // Stream subscription
  StreamSubscription<Deck>? _deckSubscription;
  EffectCleanup? _indexClampEffect;

  // ========================================
  // COMPUTED STATE (Read-Only Public API)
  // ========================================

  // Deck computeds
  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final deck = _currentDeck.value;
    if (deck == null) return <SlideConfiguration>[];
    return _slideBuilder.buildConfigurations(deck.slides, _options.value);
  });

  late final ReadonlySignal<int> totalSlides = computed(
    () => slides.value.length,
  );
  late final ReadonlySignal<bool> isLoading = computed(
    () => _loadingState.value == DeckLoadingState.loading,
  );
  late final ReadonlySignal<bool> hasError = computed(
    () => _loadingState.value == DeckLoadingState.error,
  );
  ReadonlySignal<Object?> get error => _error;

  // UI computeds
  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  ReadonlySignal<bool> get isRebuilding => _isRebuilding;

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

  /// Creates a DeckController with the given dependencies.
  ///
  /// [navigationService] and [thumbnailService] can be injected for testing.
  /// If not provided, default instances are created.
  DeckController({
    required DeckService deckService,
    required DeckOptions options,
    bool enableDeckStream = !kIsTest,
    NavigationService? navigationService,
    ThumbnailService? thumbnailService,
  }) : _deckService = deckService,
       _navigationService = navigationService ?? NavigationService(),
       _thumbnailService = thumbnailService ?? ThumbnailService(),
       _enableDeckStream = enableDeckStream,
       _slideBuilder = SlideConfigurationBuilder(
         configuration: deckService.configuration,
       ) {
    _options.value = options;

    // Create router with index change callback
    router = _navigationService.createRouter(
      onIndexChanged: (index) => _updateCurrentIndex(index),
    );

    // Clamp index when slide count changes (e.g., deck reloads with fewer slides)
    _indexClampEffect = effect(() {
      final total = totalSlides.value;
      final maxIndex = total > 0 ? total - 1 : 0;
      final currentIdx = _currentIndex.peek();
      final clamped = currentIdx.clamp(0, maxIndex);
      if (_currentIndex.value != clamped) {
        _currentIndex.value = clamped;
      }
    });

    // Start deck loading
    _startDeckStream();
  }

  // ========================================
  // DECK OPERATIONS
  // ========================================

  void _startDeckStream() {
    _loadingState.value = DeckLoadingState.loading;

    if (!_enableDeckStream) {
      unawaited(_loadDeckOnce());
      return;
    }

    _deckSubscription = _deckService.loadDeckStream().listen(
      (deck) {
        if (_disposed) return;
        _currentDeck.value = deck;
        _loadingState.value = DeckLoadingState.loaded;
        _error.value = null;
      },
      onError: (e) {
        if (_disposed) return;
        _error.value = e;
        _loadingState.value = DeckLoadingState.error;
      },
      onDone: () {
        if (_disposed) return;
        // Stream completed unexpectedly - this shouldn't happen during normal
        // operation as the deck stream is a file watcher. Log for debugging.
        debugPrint('[DeckController] Deck stream completed unexpectedly');
      },
    );
  }

  Future<void> _loadDeckOnce() async {
    try {
      final deck = await _deckService.loadDeck();
      if (_disposed) return;
      _currentDeck.value = deck;
      _loadingState.value = DeckLoadingState.loaded;
      _error.value = null;
    } catch (e) {
      if (_disposed) return;
      _error.value = e;
      _loadingState.value = DeckLoadingState.error;
    }
  }

  /// Updates deck options (called by DeckControllerBuilder)
  @internal
  void updateOptions(DeckOptions newOptions) {
    if (_disposed) return;
    if (_options.value != newOptions) {
      _options.value = newOptions;
    }
  }

  /// Sets rebuilding state (called by CliWatcher)
  @internal
  void setRebuilding(bool value) {
    if (_disposed) return;
    _isRebuilding.value = value;
  }

  /// Forces the deck stream to restart (used for retry flows)
  Future<void> reloadDeck() async {
    if (_disposed) return;

    // Clear error and set loading state BEFORE cancellation to prevent race conditions
    _error.value = null;
    _loadingState.value = DeckLoadingState.loading;

    if (!_enableDeckStream) {
      await _loadDeckOnce();
      return;
    }

    await _deckSubscription?.cancel();
    _deckSubscription = null;

    _startDeckStream();
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

  /// Handles navigation events from input handlers (internal)
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

  /// Updates current index from router (internal, called by NavigationService)
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

    // Clean up stale thumbnails for removed slides to prevent memory leaks
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
    // Guard against double disposal
    if (_disposed) return;
    _disposed = true;

    // Stop effects before disposing signals
    _indexClampEffect?.call();

    // Cancel stream subscription - use unawaited since dispose() is sync
    // The subscription may emit events during cancellation, but _disposed
    // flag prevents signal access after disposal
    unawaited(_deckSubscription?.cancel());

    // Dispose router (GoRouter implements ChangeNotifier)
    router.dispose();

    // Dispose thumbnails
    for (final thumbnail in _thumbnails.value.values) {
      thumbnail.dispose();
    }

    // Dispose signals
    _loadingState.dispose();
    _currentDeck.dispose();
    _error.dispose();
    _options.dispose();
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _isRebuilding.dispose();
    _currentIndex.dispose();
    _isTransitioning.dispose();
    _thumbnails.dispose();

    // Dispose computed signals
    slides.dispose();
    totalSlides.dispose();
    isLoading.dispose();
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
