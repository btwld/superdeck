import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../export/async_thumbnail.dart';
import '../export/thumbnail_service.dart';
import '../ui/widgets/provider.dart';
import '../utils/asset_cache_store.dart';
import '../utils/constants.dart';
import 'deck_options.dart';
import 'navigation_events.dart';
import 'navigation_service.dart';
import 'slide_configuration.dart';
import 'slide_configuration_builder.dart';
import 'superdeck_plugin.dart';

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
  final bool _enableBuildStatusWatch;
  final List<SuperDeckPlugin> _plugins;

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
  final _buildStatus = signal<DeckBuildStatus?>(null);
  final _options = signal<DeckOptions>(DeckOptions()); // NEVER exposed

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

  // Stream subscription
  StreamSubscription<DeckBuildStatus>? _buildStatusSubscription;
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
  late final ReadonlySignal<bool> isLoading = computed(
    () => _loadingState.value == DeckLoadingState.loading,
  );
  late final ReadonlySignal<bool> hasError = computed(
    () => _loadingState.value == DeckLoadingState.error,
  );
  ReadonlySignal<Object?> get error => _error;
  late final ReadonlySignal<DeckBuildError?> buildFailure = computed(() {
    final status = _buildStatus.value;
    if (status == null || status.phase != DeckBuildPhase.failure) {
      return null;
    }

    return status.error ??
        const DeckBuildError(
          type: 'BuildFailure',
          message: 'Deck build failed',
        );
  });

  // UI computeds
  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  late final ReadonlySignal<bool> isBuildActive = computed(() {
    final status = _buildStatus.value;
    return status?.phase == DeckBuildPhase.building ||
        status?.phase == DeckBuildPhase.success;
  });
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

  /// Creates a DeckController with the given dependencies.
  ///
  /// [navigationService] and [thumbnailService] can be injected for testing.
  /// If not provided, default instances are created.
  DeckController({
    required DeckService deckService,
    required DeckOptions options,
    bool enableBuildStatusWatch = !kIsTest,
    NavigationService? navigationService,
    ThumbnailService? thumbnailService,
  }) : _deckService = deckService,
       _navigationService = navigationService ?? NavigationService(),
       _thumbnailService =
           thumbnailService ??
           ThumbnailService(
             cacheStore: createAssetCacheStore(
               configuration: deckService.configuration,
             ),
           ),
       _enableBuildStatusWatch = enableBuildStatusWatch,
       _plugins = options.plugins {
    _options.value = options.copyWith(plugins: _plugins);
    final pluginRoutes = _plugins
        .expand((plugin) => plugin.buildRoutes())
        .toList(growable: false);

    // Create router with index change callback
    router = _navigationService.createRouter(
      onIndexChanged: (index) => _updateCurrentIndex(index),
      additionalRoutes: pluginRoutes,
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

    unawaited(_loadInitialDeck());
    if (_enableBuildStatusWatch) {
      _startBuildStatusWatch();
    }
  }

  // ========================================
  // DECK OPERATIONS
  // ========================================

  DeckConfiguration _resolveDeckConfiguration(Deck deck) {
    final deckConfiguration = deck.configuration;
    return _hasExplicitConfigurationOverrides(deckConfiguration)
        ? deckConfiguration
        : _deckService.configuration;
  }

  bool _hasExplicitConfigurationOverrides(DeckConfiguration configuration) {
    return configuration.projectDir != null ||
        configuration.slidesPath != null ||
        configuration.outputDir != null ||
        configuration.assetsPath != null;
  }

  Future<void> _loadInitialDeck() async {
    _loadingState.value = DeckLoadingState.loading;
    _buildStatus.value = null;

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

  void _startBuildStatusWatch() {
    _buildStatusSubscription = _deckService.watchBuildStatus().listen(
      _handleBuildStatus,
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        debugPrint('[DeckController] Build status watcher failed: $error');
      },
    );
  }

  Future<void> _reloadDeckInBackground(DeckBuildStatus triggerStatus) async {
    try {
      final deck = await _deckService.loadDeck();
      if (!_canApplyReloadResult(triggerStatus)) return;

      if (_isErrorDeck(deck)) {
        _buildStatus.value = DeckBuildStatus(
          phase: DeckBuildPhase.failure,
          timestamp: DateTime.now(),
          error: const DeckBuildError(
            type: 'DeckLoadError',
            message: 'Failed to load updated deck from superdeck.json',
          ),
        );
        return;
      }

      _currentDeck.value = deck;
      _buildStatus.value = null;
    } catch (e) {
      if (!_canApplyReloadResult(triggerStatus)) return;
      _buildStatus.value = DeckBuildStatus(
        phase: DeckBuildPhase.failure,
        timestamp: DateTime.now(),
        error: DeckBuildError(
          type: e.runtimeType.toString(),
          message: e.toString(),
        ),
      );
    }
  }

  bool _isErrorDeck(Deck deck) {
    return deck.slides.length == 1 && deck.slides.first.key == 'error';
  }

  bool _canApplyReloadResult(DeckBuildStatus triggerStatus) {
    return !_disposed && _buildStatus.value == triggerStatus;
  }

  void _handleBuildStatus(DeckBuildStatus status) {
    if (_disposed) return;

    switch (status.phase) {
      case DeckBuildPhase.building:
        _buildStatus.value = status;
        return;
      case DeckBuildPhase.success:
        _buildStatus.value = status;
        unawaited(_reloadDeckInBackground(status));
        return;
      case DeckBuildPhase.failure:
        _buildStatus.value = status;
        return;
      case DeckBuildPhase.unknown:
        // Ignore unknown statuses except to stop active build UI.
        if (isBuildActive.peek()) {
          _buildStatus.value = null;
        }
        return;
    }
  }

  /// Updates deck options (called by DeckControllerBuilder)
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

  /// Reloads deck and updates full-screen loading/error state.
  Future<void> reloadDeck() async {
    if (_disposed) return;

    _error.value = null;
    _buildStatus.value = null;
    _loadingState.value = DeckLoadingState.loading;

    await _loadInitialDeck();
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

    // Cancel stream subscription - use unawaited since dispose() is sync.
    unawaited(_buildStatusSubscription?.cancel());

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
    _buildStatus.dispose();
    _options.dispose();
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _currentIndex.dispose();
    _isTransitioning.dispose();
    _thumbnails.dispose();

    // Dispose computed signals
    slides.dispose();
    totalSlides.dispose();
    isLoading.dispose();
    hasError.dispose();
    buildFailure.dispose();
    isBuildActive.dispose();
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
