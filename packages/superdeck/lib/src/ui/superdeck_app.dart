import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'tokens/colors.dart';

import '../deck/deck_controller_builder.dart';
import '../deck/deck_options.dart';
import '../deck/loaders/bundled_deck_loader.dart';
import '../deck/loaders/file_deck_loader.dart';
import '../utils/app_initialization.dart';
import '../utils/asset_cache_store.dart';
import '../utils/constants.dart';
import 'app_shell.dart';
import 'app_theme.dart';

class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({
    super.key,
    required this.options,
    this.deckLoader,
    this.workspace,
    this.assetCacheStore,
    this.transitionDuration = const Duration(seconds: 1),
  });

  final DeckOptions options;

  /// Optional loader override. When null, auto-selects [FileDeckLoader] or
  /// [BundledDeckLoader] based on the runtime environment.
  final DeckLoader? deckLoader;
  final DeckWorkspace? workspace;
  final AssetCacheStore? assetCacheStore;
  final Duration transitionDuration;

  static Future<void> initialize() async {
    await initializeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      deckLoader == null || workspace != null || assetCacheStore != null,
      'SuperDeckApp requires a matching workspace or assetCacheStore when '
      'a custom deckLoader is provided.',
    );
    if (deckLoader != null && workspace == null && assetCacheStore == null) {
      throw ArgumentError(
        'SuperDeckApp requires a matching workspace or assetCacheStore when '
        'a custom deckLoader is provided.',
      );
    }

    final runtimeWorkspace = workspace ?? DeckWorkspace();
    final loader =
        deckLoader ??
        (kCanRunProcess
            ? FileDeckLoader(workspace: runtimeWorkspace)
            : BundledDeckLoader(workspace: runtimeWorkspace));
    final cacheStore =
        assetCacheStore ?? RuntimeAssetCacheStore(workspace: runtimeWorkspace);

    return DeckControllerBuilder(
      options: options,
      deckLoader: loader,
      assetCacheStore: cacheStore,
      transitionDuration: transitionDuration,
      builder: (context, router) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Superdeck',
          routerConfig: router,
          builder: (context, child) {
            return MixScope(
              colors: SDColors.colorMap,
              child: AppShell(child: child!),
            );
          },
          theme: theme,
        );
      },
    );
  }
}
