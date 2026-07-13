import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

import '../core/data/data_sources/app_settings_store.dart';
import '../core/data/data_sources/deck_file_store.dart';
import '../core/data/data_sources/memory_asset_cache_store.dart';
import '../core/data/data_sources/memory_deck_loader.dart';
import '../core/domain/stores/deck_customization_store.dart';

/// App-root dependency injection: the deck globals shared across features.
///
/// `DeckController` and `DeckCustomizationStore` are created eagerly
/// (`lazy: false`) so the `MemoryDeckLoader` → `DeckController.slides` pipeline
/// is subscribed, and the initial `DeckOptions` seeded, before the editor mounts
/// and writes its first markdown — otherwise the loader's broadcast event would
/// be dropped.
///
/// The editor's `EditorStore` is provided at its route instead. Slides are read
/// straight off `DeckController.slides` (a signal) in the UI — no bridge store.
///
/// [deckFileStore]/[appSettingsStore] default to the native (filesystem)
/// implementations; tests inject in-memory fakes so the editor's file-backed
/// bootstrap runs without touching disk.
class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.child,
    this.deckFileStore,
    this.appSettingsStore,
    super.key,
  });

  final Widget child;
  final DeckFileStore? deckFileStore;
  final AppSettingsStore? appSettingsStore;

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
        Provider<DeckFileStore>(
          create: (_) => deckFileStore ?? const NativeDeckFileStore(),
        ),
        Provider<AppSettingsStore>(
          create: (_) => appSettingsStore ?? const NativeAppSettingsStore(),
        ),
        Provider<DeckController>(
          lazy: false,
          create: (ctx) => DeckController(
            deckLoader: ctx.read<MemoryDeckLoader>(),
            options: DeckOptions(),
            assetCacheStore: ctx.read<MemoryAssetCacheStore>(),
          ),
          dispose: (_, controller) => controller.dispose(),
        ),
        ChangeNotifierProvider<DeckCustomizationStore>(
          lazy: false,
          create: (ctx) => DeckCustomizationStore(
            ctx.read<DeckController>(),
            background: background,
            foreground: foreground,
          ),
        ),
      ],
      child: child,
    );
  }
}
