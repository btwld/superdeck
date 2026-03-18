import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'tokens/colors.dart';

import '../deck/deck_controller_builder.dart';
import '../deck/deck_loader.dart';
import '../deck/deck_options.dart';
import '../deck/superdeck_plugin.dart';
import '../utils/app_initialization.dart';
import '../utils/constants.dart';
import 'app_shell.dart';
import 'app_theme.dart';

class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({super.key, required this.options, this.deckLoader});

  final DeckOptions options;

  /// Optional loader override. When null, auto-selects [FileDeckLoader] or
  /// [BundledDeckLoader] based on the runtime environment.
  final DeckLoader? deckLoader;

  static Future<void> initialize({
    List<SuperDeckPlugin> plugins = const <SuperDeckPlugin>[],
  }) async {
    await initializeDependencies();
    for (final plugin in plugins) {
      try {
        await plugin.initialize();
      } catch (e, stack) {
        debugPrint(
          'SuperDeckPlugin "${plugin.name}" failed to initialize: $e\n$stack',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loader =
        deckLoader ?? (kCanRunProcess ? FileDeckLoader() : BundledDeckLoader());

    return DeckControllerBuilder(
      options: options,
      deckLoader: loader,
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
