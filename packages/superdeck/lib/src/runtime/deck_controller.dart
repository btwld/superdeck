import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';
import 'package:signals/signals.dart';

import '../export/async_thumbnail.dart';
import '../export/pdf_export_screen.dart';
import '../export/thumbnail_service.dart';
import '../presentation/deck_extension.dart';
import '../presentation/deck_theme.dart';
import '../slides/slide_data.dart';
import '../slides/slide_data_builder.dart';
import '../utils/asset_cache_store.dart';
import 'superdeck_provider.dart';
import 'navigation/navigation_events.dart';
import 'navigation/navigation_service.dart';

/// Presentation controller for deck navigation, UI state, and thumbnails.
///
/// Receives reactive deck data from [DeckDataState] (provided by
/// [SuperDeckProvider]) and manages presentation concerns only.
class DeckController {
  // ========================================
  // DEPENDENCIES
  // ========================================

  final DeckDataState _dataState;
  final NavigationService _navigationService;
  final ThumbnailService _thumbnailService;
  final List<DeckExtension> _extensions;

  bool _disposed = false;

  // ========================================
  // INTERNAL STATE (Private Signals)
  // ========================================

  final _theme = signal<DeckTheme>(const DeckTheme());

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
  late final ReadonlySignal<List<SlideData>> slides = computed(() {
    final deck = _dataState.deck.value;
    if (deck == null) return <SlideData>[];
    return SlideDataBuilder(
      configuration: _dataState.workspace,
    ).buildSlides(deck.slides, _theme.value);
  });

  late final ReadonlySignal<int> totalSlides = computed(
    () => slides.value.length,
  );

  // Data state pass-throughs
  late final ReadonlySignal<bool> isLoading = computed(
    () => _dataState.loadingState.value == DeckLoadingState.loading,
  );
  late final ReadonlySignal<bool> hasError = computed(
    () => _dataState.loadingState.value == DeckLoadingState.error,
  );
  ReadonlySignal<Object?> get error => _dataState.error;
  ReadonlySignal<bool> get isRebuilding => _dataState.isRebuilding;

  // UI computeds
  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  List<DeckExtension> get extensions => _extensions;

  // Navigation computeds
  ReadonlySignal<int> get currentIndex => _currentIndex;
  ReadonlySignal<bool> get isTransitioning => _isTransitioning;
  late final ReadonlySignal<bool> canGoNext = computed(
    () => _currentIndex.value < totalSlides.value - 1,
  );
  late final ReadonlySignal<bool> canGoPrevious = computed(
    () => _currentIndex.value > 0,
  );
  late final ReadonlySignal<SlideData?> currentSlide = computed(() {
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
    required DeckDataState dataState,
    required DeckTheme theme,
    List<DeckExtension> extensions = const <DeckExtension>[],
    NavigationService? navigationService,
    ThumbnailService? thumbnailService,
  }) : _dataState = dataState,
       _navigationService = navigationService ?? NavigationService(),
       _thumbnailService =
           thumbnailService ??
           ThumbnailService(
             cacheStore: createAssetCacheStore(
               configuration: dataState.workspace,
             ),
           ),
       _extensions = extensions {
    _theme.value = theme;
    final extensionRoutes = _extensions
        .expand((extension) => extension.buildRoutes())
        .toList(growable: false);

    // Create router with index change callback
    router = _navigationService.createRouter(
      onIndexChanged: (index) => _updateCurrentIndex(index),
      additionalRoutes: extensionRoutes,
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
  }

  // ========================================
  // DECK OPERATIONS
  // ========================================

  /// Updates theme state from the app layer.
  @internal
  void updateTheme(DeckTheme newTheme) {
    if (_disposed) return;
    if (_theme.value != newTheme) {
      _theme.value = newTheme;
    }
  }

  /// Delegates to [DeckDataState.reload] to restart deck loading.
  Future<void> reload() => _dataState.reload();

  // ========================================
  // UI ACTIONS
  // ========================================

  void openMenu() => _isMenuOpen.value = true;
  void closeMenu() => _isMenuOpen.value = false;
  void openNotes() => _isNotesOpen.value = true;
  void closeNotes() => _isNotesOpen.value = false;
  void toggleNotes() => _isNotesOpen.value = !_isNotesOpen.value;

  @internal
  List<Widget> buildActions(BuildContext context) {
    return _extensions
        .expand((extension) => extension.buildActions(context))
        .toList(growable: false);
  }

  @internal
  Widget? buildFloatingAction(BuildContext context) {
    for (final extension in _extensions) {
      final action = extension.buildFloatingAction(context);
      if (action != null) return action;
    }
    return null;
  }

  @internal
  void exportPdf(BuildContext context) {
    PdfExportDialogScreen.show(context);
  }

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
    if (_disposed) return;
    _disposed = true;

    _indexClampEffect?.call();

    // Dispose router (GoRouter implements ChangeNotifier)
    router.dispose();

    // Dispose thumbnails
    for (final thumbnail in _thumbnails.value.values) {
      thumbnail.dispose();
    }

    // Dispose owned signals
    _theme.dispose();
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
    canGoNext.dispose();
    canGoPrevious.dispose();
    currentSlide.dispose();
  }
}
