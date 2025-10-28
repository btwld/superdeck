import 'package:flutter/material.dart' show MaterialApp;
import 'package:mix/mix.dart';
import 'package:superdeck_ui/superdeck_ui.dart';

import '../utils/initializer_provider.dart';
import '../deck/deck_options.dart';
import '../deck/deck_provider.dart';
import 'app_shell.dart';
import '../styling/theme.dart';
import 'package:flutter/widgets.dart';

class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({super.key, required this.options});

  final DeckOptions options;

  static Future<void> initialize() async {
    await initializeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return DeckControllerBuilder(
      options: options,
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
