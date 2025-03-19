import 'package:flutter/material.dart';

import '../modules/common/helpers/theme.dart';
import '../modules/common/initializer_provider.dart';
import '../modules/deck/deck_options.dart';
import '../modules/deck/deck_provider.dart';
import '../modules/navigation/navigation_provider.dart';
import 'organisms/app_shell.dart';

class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({
    super.key,
    required this.options,
  });

  final DeckOptions options;

  static Future<void> initialize() async {
    await initializeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return DeckControllerBuilder(
      options: options,
      builder: (controller) {
        return NavigationProviderBuilder(
          deckController: controller,
          builder: (router) {
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
      },
    );
  }
}
