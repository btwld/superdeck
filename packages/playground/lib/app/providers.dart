import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

import '../core/data/data_sources/memory_deck_loader.dart';
import '../core/domain/stores/deck_customization_store.dart';
import '../features/editor/data/mac_os_deck_file_repository.dart';
import '../features/editor/domain/files/deck_file_repository.dart';
import '../features/editor/domain/stores/deck_asset_cache_store.dart';
import '../features/ai/image_generation/image_generator.dart';
import '../features/ai/quick_agent/core/env_config.dart';

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
/// [deckFileRepository] defaults to the macOS filesystem implementation; tests
/// inject an in-memory repository so bootstrap runs without touching disk.
class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.child,
    this.deckFileRepository,
    this.imageGenerator,
    super.key,
  });

  final Widget child;
  final DeckFileRepository? deckFileRepository;
  final ImageGenerator? imageGenerator;

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
        ChangeNotifierProvider<DeckAssetCacheStore>(
          create: (_) => DeckAssetCacheStore(),
        ),
        Provider<DeckFileRepository>(
          create: (_) => deckFileRepository ?? MacOsDeckFileRepository(),
          dispose: (_, repository) => repository.dispose(),
        ),
        Provider<ImageGenerator>(
          create: (_) =>
              imageGenerator ??
              (EnvConfig.hasGeminiApiKey
                  ? DartanticImageGenerator(apiKey: EnvConfig.geminiApiKey)
                  : const UnavailableImageGenerator(
                      'No Gemini API key is configured.',
                    )),
        ),
        Provider<DeckController>(
          lazy: false,
          create: (ctx) => DeckController(
            deckLoader: ctx.read<MemoryDeckLoader>(),
            options: DeckOptions(),
            assetCacheStore: ctx.read<DeckAssetCacheStore>(),
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
