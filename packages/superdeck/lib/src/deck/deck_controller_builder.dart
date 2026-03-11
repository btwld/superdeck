import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/provider.dart';
import '../utils/config_resolver.dart';
import '../utils/constants.dart';
import 'deck_loader.dart';
import 'deck_controller.dart';
import 'deck_options.dart';

/// Builder widget that creates and manages the DeckController
///
/// Provides the DeckController via InheritedData and manages its lifecycle
/// including optional runtime build-status watching in debug IO runtimes.
class DeckControllerBuilder extends StatefulWidget {
  final DeckOptions options;
  final DeckConfiguration? configuration;
  final Widget Function(BuildContext context, GoRouter router) builder;

  const DeckControllerBuilder({
    super.key,
    required this.options,
    this.configuration,
    required this.builder,
  });

  @override
  State<DeckControllerBuilder> createState() => _DeckControllerBuilderState();
}

class _DeckControllerBuilderState extends State<DeckControllerBuilder> {
  late final DeckController _deckController;

  @override
  void initState() {
    super.initState();

    final configuration = resolveConfiguration(widget.configuration);
    final deckLoader = kCanRunProcess
        ? FileDeckLoader(configuration: configuration)
        : BundledDeckLoader(configuration: configuration);

    _deckController = DeckController(
      configuration: configuration,
      deckLoader: deckLoader,
      options: widget.options,
    );
  }

  @override
  void didUpdateWidget(DeckControllerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      _deckController.updateOptions(widget.options);
    }
  }

  @override
  void dispose() {
    _deckController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedData(
      data: _deckController,
      child: Builder(
        builder: (context) {
          return widget.builder(context, _deckController.router);
        },
      ),
    );
  }
}
