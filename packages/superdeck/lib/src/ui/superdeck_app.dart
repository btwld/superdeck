import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/deck_controller_builder.dart';
import '../deck/deck_options.dart';
import '../utils/app_initialization.dart';
import 'app_shell.dart';
import 'theme.dart';

class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({super.key, required this.options, this.configuration});

  final DeckOptions options;
  final DeckConfiguration? configuration;

  static Future<void> initialize() async {
    await initializeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return DeckControllerBuilder(
      options: options,
      configuration: configuration,
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
