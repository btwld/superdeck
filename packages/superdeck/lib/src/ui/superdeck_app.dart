import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'tokens/colors.dart';

import '../deck/deck_controller_builder.dart';
import '../deck/deck_options.dart';
import '../deck/loaders/bundled_deck_loader.dart';
import '../deck/loaders/file_deck_loader.dart';
import '../plugins/deck_action.dart';
import '../plugins/deck_runtime_plugin.dart';
import '../utils/app_initialization.dart';
import '../utils/asset_cache_store.dart';
import '../utils/constants.dart';
import 'app_shell.dart';
import 'app_theme.dart';

class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({
    super.key,
    required this.options,
    this.plugins = const [],
    this.deckLoader,
    this.workspace,
    this.assetCacheStore,
    this.transitionDuration = const Duration(seconds: 1),
  });

  final DeckOptions options;

  /// Runtime plugins that contribute commands to the app shell.
  ///
  /// Plugin IDs and the action IDs they contribute must be unique.
  final List<DeckRuntimePlugin> plugins;

  /// Optional loader override. When null, auto-selects [FileDeckLoader] or
  /// [BundledDeckLoader] based on the runtime environment.
  final DeckLoader? deckLoader;
  final DeckWorkspace? workspace;
  final AssetCacheStore? assetCacheStore;
  final Duration transitionDuration;

  static Future<void> initialize() async {
    await initializeDependencies();
  }

  static List<DeckAction> _resolvePluginActions(
    List<DeckRuntimePlugin> plugins,
  ) {
    _validatePlugins(plugins);

    final actions = <DeckAction>[];
    final actionIds = <String>{};
    for (final plugin in plugins) {
      for (final action in plugin.actions) {
        final actionId = action.id.trim();
        if (!actionIds.add(actionId)) {
          throw ArgumentError.value(
            action.id,
            'plugins',
            'Duplicate deck action id "$actionId" from runtime plugin '
                '"${plugin.id}".',
          );
        }
        actions.add(action);
      }
    }

    return List.unmodifiable(actions);
  }

  static void _validatePlugins(List<DeckRuntimePlugin> plugins) {
    final pluginIds = <String>{};
    for (final plugin in plugins) {
      final id = plugin.id.trim();
      if (id.isEmpty) {
        throw ArgumentError.value(
          plugin.id,
          'plugins',
          'Runtime plugin id must not be empty.',
        );
      }
      if (!pluginIds.add(id)) {
        throw ArgumentError.value(
          plugin.id,
          'plugins',
          'Duplicate runtime plugin id "$id".',
        );
      }
    }
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
    final actions = _resolvePluginActions(plugins);

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
              child: AppShell(actions: actions, child: child!),
            );
          },
          theme: theme,
        );
      },
    );
  }
}
