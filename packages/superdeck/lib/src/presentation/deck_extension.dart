import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Behavioral add-on surface for SuperDeck runtimes.
abstract class DeckExtension {
  const DeckExtension();

  String get name;

  List<RouteBase> buildRoutes() => const [];

  List<Widget> buildActions(BuildContext context) => const [];

  Widget? buildFloatingAction(BuildContext context) => null;

  Future<void> initialize() async {}
}
