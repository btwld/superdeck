import 'package:flutter/widgets.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../thumbnails/thumbnail_service.dart';
import '../ui/widgets/provider.dart';
import '../ui/widgets/webview_controller_cache.dart';
import '../utils/asset_cache_store.dart';
import 'deck_options.dart';
import 'deck_presentation_state.dart';
import 'deck_session_state.dart';
import 'slide_configuration.dart';
import 'slide_configuration_builder.dart';

/// Composition root for deck state.
///
/// Load/build lifecycle lives on [session]; routing, navigation, menu, and
/// thumbnails live on [presentation]. Consumers reach through those directly.
final class DeckController {
  DeckController({
    required DeckLoader deckLoader,
    required DeckOptions options,
    ThumbnailService? thumbnailService,
    AssetCacheStore? assetCacheStore,
    Duration transitionDuration = const Duration(seconds: 1),
  }) {
    this.assetCacheStore = assetCacheStore ?? RuntimeAssetCacheStore();
    this.options = signal<DeckOptions>(options);
    session = DeckSessionState(deckLoader: deckLoader);
    presentation = DeckPresentationState(
      thumbnailService:
          thumbnailService ??
          ThumbnailService(cacheStore: this.assetCacheStore),
      slides: slides,
      transitionDuration: transitionDuration,
    );
  }

  /// Asset cache shared by thumbnail capture and in-slide image resolution.
  late final AssetCacheStore assetCacheStore;

  /// Deck-scoped WebView controllers reused across slide remounts.
  final webViewControllerCache = WebViewControllerCache();

  late final Signal<DeckOptions> options;
  late final DeckSessionState session;
  late final DeckPresentationState presentation;

  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final loaded = session.loadedSlides.value;
    if (loaded == null) return const <SlideConfiguration>[];
    return const SlideConfigurationBuilder().buildConfigurations(
      loaded,
      options.value,
      assetCacheStore: assetCacheStore,
    );
  });

  Future<void> reloadDeck() => session.reload();

  void dispose() {
    webViewControllerCache.clear();
    presentation.dispose();
    session.dispose();
    options.dispose();
    slides.dispose();
  }

  static DeckController of(BuildContext context) {
    return InheritedData.of<DeckController>(context);
  }
}
