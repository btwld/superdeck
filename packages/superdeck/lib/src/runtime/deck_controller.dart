import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart' show Deck;

import '../export/async_thumbnail.dart';
import '../export/pdf_export_screen.dart';
import '../export/thumbnail_service.dart';
import '../presentation/deck_extension.dart';
import '../presentation/deck_theme.dart';
import '../slides/slide_data.dart';
import '../slides/slide_data_builder.dart';
import '../utils/asset_cache_store.dart';
import 'navigation/navigation_events.dart';
import 'navigation/navigation_service.dart';

/// Presentation controller for deck navigation, UI state, and thumbnails.
///
/// This controller owns render-time concerns only.
class DeckController {
  final NavigationService _navigationService;
  final ThumbnailService _thumbnailService;
  final List<DeckExtension> _extensions;

  bool _disposed = false;

  final _deck = signal<Deck?>(null);
  final _theme = signal<DeckTheme>(const DeckTheme());

  final _isMenuOpen = signal<bool>(false);
  final _isNotesOpen = signal<bool>(false);

  final _currentIndex = signal<int>(0);
  final _isTransitioning = signal<bool>(false);

  final _thumbnails = signal<Map<String, AsyncThumbnail>>({});

  late final GoRouter router;

  EffectCleanup? _indexClampEffect;

  late final ReadonlySignal<List<SlideData>> slides = computed(() {
    final deck = _deck.value;
    if (deck == null) {
      return <SlideData>[];
    }

    return const SlideDataBuilder().buildSlides(deck.slides, _theme.value);
  });

  late final ReadonlySignal<int> totalSlides = computed(
    () => slides.value.length,
  );

  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  List<DeckExtension> get extensions => _extensions;

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

  DeckController({
    required Deck deck,
    required DeckTheme theme,
    List<DeckExtension> extensions = const <DeckExtension>[],
    NavigationService? navigationService,
    ThumbnailService? thumbnailService,
  }) : _navigationService = navigationService ?? NavigationService(),
       _thumbnailService =
           thumbnailService ??
           ThumbnailService(
             cacheStore: createAssetCacheStore(
               configuration: deck.configuration,
             ),
           ),
       _extensions = extensions {
    _deck.value = deck;
    _theme.value = theme;

    final extensionRoutes = _extensions
        .expand((extension) => extension.buildRoutes())
        .toList(growable: false);

    router = _navigationService.createRouter(
      onIndexChanged: _updateCurrentIndex,
      additionalRoutes: extensionRoutes,
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
  }

  @internal
  void updateDeck(Deck newDeck) {
    if (_disposed) return;
    if (_deck.value != newDeck) {
      _deck.value = newDeck;
    }
  }

  @internal
  void updateTheme(DeckTheme newTheme) {
    if (_disposed) return;
    if (_theme.value != newTheme) {
      _theme.value = newTheme;
    }
  }

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
      if (action != null) {
        return action;
      }
    }
    return null;
  }

  @internal
  void exportPdf(BuildContext context) {
    PdfExportDialogScreen.show(context);
  }

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

  void generateThumbnails(BuildContext context, {bool force = false}) {
    if (_disposed) return;

    final currentSlides = slides.value;
    final currentSlideKeys = currentSlides.map((slide) => slide.key).toSet();

    final currentCache = _thumbnails.value;
    final staleKeys = currentCache.keys
        .where((key) => !currentSlideKeys.contains(key))
        .toList(growable: false);

    if (staleKeys.isNotEmpty) {
      for (final key in staleKeys) {
        currentCache[key]?.dispose();
      }

      final cleanedCache = Map<String, AsyncThumbnail>.from(currentCache)
        ..removeWhere((key, _) => staleKeys.contains(key));
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
    router.dispose();

    for (final thumbnail in _thumbnails.value.values) {
      thumbnail.dispose();
    }

    // Dispose computed signals before their source dependencies.
    currentSlide.dispose();
    canGoPrevious.dispose();
    canGoNext.dispose();
    totalSlides.dispose();
    slides.dispose();

    _deck.dispose();
    _theme.dispose();
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _currentIndex.dispose();
    _isTransitioning.dispose();
    _thumbnails.dispose();
  }
}
