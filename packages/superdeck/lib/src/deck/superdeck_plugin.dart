import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Describes deck extensions that can be installed by host applications.
abstract class SuperDeckPlugin {
  const SuperDeckPlugin();

  /// Unique plugin name.
  String get name;

  /// Extra routes contributed by this plugin.
  List<RouteBase> buildRoutes() => const [];

  /// Inline action widgets rendered in the deck bottom bar.
  List<Widget> buildActions(BuildContext context) => const [];

  /// Optional floating action shown when the menu is closed.
  Widget? buildFloatingAction(BuildContext context) => null;

  /// One-time async initialization hook called at app startup.
  Future<void> initialize() async {}
}
