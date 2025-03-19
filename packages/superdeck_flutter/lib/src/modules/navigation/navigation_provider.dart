import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../common/helpers/provider.dart';
import '../deck/deck_controller.dart';
import 'navigation_controller.dart';

class NavigationProviderBuilder extends StatefulWidget {
  final Widget Function(GoRouter router) builder;
  const NavigationProviderBuilder({
    super.key,
    required DeckController deckController,
    required this.builder,
  }) : _deckController = deckController;

  final DeckController _deckController;

  @override
  State<NavigationProviderBuilder> createState() =>
      _NavigationProviderBuilderState();
}

class _NavigationProviderBuilderState extends State<NavigationProviderBuilder> {
  late final NavigationController _navigationController;

  @override
  void initState() {
    super.initState();

    _navigationController = NavigationController(
      slides: widget._deckController.slides,
    );
  }

  @override
  void dispose() {
    super.dispose();

    _navigationController.dispose();
  }

  @override
  void didUpdateWidget(NavigationProviderBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    final slidesChanged = listEquals(
      widget._deckController.slides,
      oldWidget._deckController.slides,
    );

    if (slidesChanged) {
      _navigationController.updateSlides(
        widget._deckController.slides,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InheritedNotifierData(
      data: _navigationController,
      child: widget.builder(_navigationController.router),
    );
  }
}
