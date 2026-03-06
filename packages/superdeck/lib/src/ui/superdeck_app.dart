import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';

import '../deck/deck_controller_builder.dart';
import '../runtime/superdeck_runtime.dart';
import 'app_shell.dart';
import 'theme.dart';

class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({super.key, required this.runtime});

  final SuperDeckRuntime runtime;

  @override
  Widget build(BuildContext context) {
    return DeckControllerBuilder(
      runtime: runtime,
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
