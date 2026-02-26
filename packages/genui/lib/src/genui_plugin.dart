import 'package:flutter/material.dart' show Icon, IconButton, Icons;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:superdeck/superdeck.dart';

import 'bootstrap/genui_bootstrap.dart';
import 'routes.dart';

/// SuperDeck plugin that installs GenUI routes, initialization, and actions.
class GenUiPlugin extends SuperDeckPlugin {
  const GenUiPlugin();

  @override
  String get name => 'genui';

  @override
  Future<void> initialize() => initializeGenUi();

  @override
  List<RouteBase> buildRoutes() => genUiRoutes();

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.auto_awesome),
      onPressed: () => GoRouter.of(context).go(GenUiRoutes.chat),
    ),
  ];
}
