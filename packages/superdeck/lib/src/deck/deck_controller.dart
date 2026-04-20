import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../thumbnails/async_thumbnail.dart';
import '../thumbnails/thumbnail_service.dart';
import '../ui/widgets/provider.dart';
import '../utils/asset_cache_store.dart';
import 'deck_options.dart';
import 'deck_presentation_state.dart';
import 'deck_session_state.dart';
import 'navigation_events.dart';
import 'slide_configuration.dart';
import 'slide_configuration_builder.dart';

/// Unified facade for all deck state and operations.
///
/// Load/build lifecycle lives in [_session], while routing, navigation, menu
/// state, and thumbnails live in [_presentation]. Consumers interact with this
/// facade instead of reaching into those subsystems directly.
class DeckController {
  late final DeckSessionState _session;
  late final DeckPresentationState _presentation;
  final _options = signal<DeckOptions>(DeckOptions());

  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final loadedSlides = _session.loadedSlides.value;
    if (loadedSlides == null) return <SlideConfiguration>[];
    return const SlideConfigurationBuilder().buildConfigurations(
      loadedSlides,
      _options.value,
    );
  });

  late final ReadonlySignal<int> totalSlides = computed(
    () => slides.value.length,
  );
  late final ReadonlySignal<bool> canGoNext = computed(
    () => currentIndex.value < totalSlides.value - 1,
  );
  late final ReadonlySignal<bool> canGoPrevious = computed(
    () => currentIndex.value > 0,
  );
  late final ReadonlySignal<SlideConfiguration?> currentSlide = computed(() {
    final index = currentIndex.value;
    final slidesList = slides.value;
    return index >= 0 && index < slidesList.length ? slidesList[index] : null;
  });

  DeckController({
    required DeckLoader deckLoader,
    required DeckOptions options,
    ThumbnailService? thumbnailService,
    AssetCacheStore? assetCacheStore,
    Duration transitionDuration = const Duration(seconds: 1),
  }) {
    _options.value = options;
    _session = DeckSessionState(deckLoader: deckLoader);
    _presentation = DeckPresentationState(
      thumbnailService:
          thumbnailService ??
          ThumbnailService(
            cacheStore: assetCacheStore ?? RuntimeAssetCacheStore(),
          ),
      slides: slides,
      transitionDuration: transitionDuration,
    );
  }

  ReadonlySignal<bool> get isLoading => _session.isLoading;
  ReadonlySignal<bool> get hasError => _session.hasFatalError;
  ReadonlySignal<Object?> get error => _session.error;
  ReadonlySignal<bool> get isBuildActive => _session.isBuildActive;
  ReadonlySignal<DeckBuildError?> get buildFailure => _session.buildFailure;

  ReadonlySignal<bool> get isMenuOpen => _presentation.isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _presentation.isNotesOpen;
  ReadonlySignal<int> get currentIndex => _presentation.currentIndex;
  ReadonlySignal<bool> get isTransitioning => _presentation.isTransitioning;

  GoRouter get router => _presentation.router;

  @internal
  void updateOptions(DeckOptions newOptions) {
    if (_options.value != newOptions) {
      _options.value = newOptions;
    }
  }

  Future<void> reloadDeck() => _session.reload();

  void openMenu() => _presentation.openMenu();
  void closeMenu() => _presentation.closeMenu();
  void toggleNotes() => _presentation.toggleNotes();

  Future<void> goToSlide(int index) {
    return _presentation.goToSlide(index, totalSlides.value);
  }

  Future<void> nextSlide() async {
    if (canGoNext.value) {
      await goToSlide(currentIndex.value + 1);
    }
  }

  Future<void> previousSlide() async {
    if (canGoPrevious.value) {
      await goToSlide(currentIndex.value - 1);
    }
  }

  @internal
  Future<void> handleNavigationEvent(NavigationEvent event) async {
    switch (event) {
      case NextSlideEvent():
        await goToSlide(currentIndex.value + 1);
      case PreviousSlideEvent():
        await goToSlide(currentIndex.value - 1);
      case GoToSlideEvent(:final index):
        await goToSlide(index);
    }
  }

  void generateThumbnails(BuildContext context, {bool force = false}) {
    _presentation.generateThumbnails(context, slides.value, force: force);
  }

  AsyncThumbnail? getThumbnail(String slideKey) {
    return _presentation.getThumbnail(slideKey);
  }

  void dispose() {
    _presentation.dispose();
    _session.dispose();

    _options.dispose();
    slides.dispose();
    totalSlides.dispose();
    canGoNext.dispose();
    canGoPrevious.dispose();
    currentSlide.dispose();
  }

  static DeckController of(BuildContext context) {
    return InheritedData.of<DeckController>(context);
  }
}
