import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

import '../core/data/data_sources/deck_library_asset_store.dart';
import '../core/data/data_sources/memory_asset_cache_store.dart';
import '../core/data/data_sources/memory_deck_loader.dart';
import '../core/domain/stores/deck_customization_store.dart';
import '../core/domain/stores/deck_document_store.dart';
import '../features/library/data/mac_os_deck_library.dart';
import '../features/library/domain/deck_library.dart';
import '../features/library/domain/deck_library_controller.dart';

const _debugDeckLayout = bool.fromEnvironment('SUPERDECK_DEBUG_LAYOUT');

/// App-root dependency injection: the deck globals shared across features.
///
/// `DeckController` and `DeckCustomizationStore` are created eagerly
/// (`lazy: false`) so the `MemoryDeckLoader` → `DeckController.slides` pipeline
/// is subscribed, and the initial `DeckOptions` seeded, before the Wizard
/// publishes its first Markdown — otherwise the loader's broadcast event would
/// be dropped.
///
/// `PresentationPage` hands `DeckController` straight to SuperDeck's own
/// `DeckPresenter`, which reads slides internally — no bridge store.
class AppProviders extends StatelessWidget {
  const AppProviders({required this.child, this.deckLibrary, super.key});

  final Widget child;

  /// Overrides the macOS deck library in tests and on other platforms.
  final DeckLibrary? deckLibrary;

  @override
  Widget build(BuildContext context) {
    // Resolve theme tokens here (listening is allowed in build) rather than
    // inside a provider `create` callback, where Provider forbids it.
    final background = $background.resolve(context);
    final foreground = $foreground.resolve(context);

    return MultiProvider(
      providers: [
        Provider<MemoryDeckLoader>(
          create: (_) => MemoryDeckLoader(),
          dispose: (_, loader) => loader.dispose(),
        ),
        Provider<MemoryAssetCacheStore>(create: (_) => MemoryAssetCacheStore()),
        ChangeNotifierProvider(create: (_) => DeckDocumentStore(markdown: '')),
        Provider<DeckLibrary>(
          create: (_) => deckLibrary ?? MacOsDeckLibrary(),
          dispose: (_, library) => library.dispose(),
        ),
        Provider(
          create: (ctx) => DeckLibraryAssetStore(
            library: ctx.read(),
            // Typed explicitly: generated artwork has to land in the store the
            // thumbnails read, not in any store that happens to be provided.
            fallback: ctx.read<MemoryAssetCacheStore>(),
          ),
        ),
        Provider<DeckController>(
          create: (ctx) => DeckController(
            deckLoader: ctx.read<MemoryDeckLoader>(),
            options: DeckOptions(debug: _debugDeckLayout),
            // Slide artwork follows the open deck; thumbnails are derived
            // from it and stay in memory.
            thumbnailService: ThumbnailService(
              cacheStore: ctx.read<MemoryAssetCacheStore>(),
            ),
            assetCacheStore: ctx.read<DeckLibraryAssetStore>(),
          ),
          dispose: (_, controller) => controller.dispose(),
          lazy: false,
        ),
        ChangeNotifierProvider<DeckCustomizationStore>(
          lazy: false,
          create: (ctx) => DeckCustomizationStore(
            ctx.read<DeckController>(),
            background: background,
            foreground: foreground,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => DeckLibraryController(
            library: ctx.read(),
            documentStore: ctx.read(),
            deckLoader: ctx.read(),
            customizationStore: ctx.read(),
            assetStore: ctx.read(),
          ),
        ),
      ],
      child: child,
    );
  }
}
