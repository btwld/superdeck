import 'package:flutter/material.dart';

import '../utils/initializer_provider.dart';
import '../deck/deck_options.dart';
import '../deck/deck_provider.dart';
import 'app_shell.dart';
import '../styling/theme.dart';

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
            return AppShell(child: child!);
          },
          theme: theme,
        );
      },
    );
  }
}
