import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/provider.dart';
import 'deck_controller.dart';
import 'deck_options.dart';

/// Builder widget that creates and manages the DeckController.
///
/// Provides the DeckController via InheritedData and manages its lifecycle.
/// The [deckLoader] is immutable after mount — only read in [initState].
class DeckControllerBuilder extends StatefulWidget {
  final DeckOptions options;
  final DeckLoader deckLoader;
  final AssetCacheStore? assetCacheStore;
  final Widget Function(BuildContext context, GoRouter router) builder;

  const DeckControllerBuilder({
    super.key,
    required this.options,
    required this.deckLoader,
    this.assetCacheStore,
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

    _deckController = DeckController(
      deckLoader: widget.deckLoader,
      options: widget.options,
      assetCacheStore: widget.assetCacheStore,
    );
  }

  @override
  void didUpdateWidget(DeckControllerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      widget.deckLoader == oldWidget.deckLoader,
      'DeckControllerBuilder.deckLoader must not change after mount. '
      'Create a new key to force a full rebuild.',
    );
    if (widget.options != oldWidget.options) {
      _deckController.options.value = widget.options;
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
          return widget.builder(context, _deckController.presentation.router);
        },
      ),
    );
  }
}
