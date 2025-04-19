import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart' as core;

import '../common/helpers/provider.dart';
import 'deck_controller.dart';
import 'deck_options.dart';
import 'deck_provider.dart';

/// A builder widget that creates and provides a [DeckController] to its children.
///
/// This widget is responsible for loading deck data from the repository and
/// building the controller with the appropriate configuration.
class DeckControllerBuilder extends StatefulWidget {
  /// The deck options to use.
  final DeckOptions options;

  /// Builder function that receives the created [DeckController] and returns a widget.
  final Widget Function(DeckController controller) builder;

  /// Creates a [DeckControllerBuilder] with the given options and builder.
  const DeckControllerBuilder({
    super.key,
    required this.options,
    required this.builder,
  });

  @override
  State<DeckControllerBuilder> createState() => _DeckControllerBuilderState();
}

class _DeckControllerBuilderState extends State<DeckControllerBuilder>
    with WidgetsBindingObserver {
  late final DeckProvider _deckProvider;
  late DeckController _deckController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDeckProvider();
  }

  Future<void> _initializeDeckProvider() async {
    // Create a presentation config with default settings
    final config = core.PresentationConfig();

    // Initialize the deck provider
    _deckProvider = DeckProvider(config);
    await _deckProvider.initialize();

    // Create the deck controller with empty slides initially
    _deckController = DeckController.build(
      slides: _deckProvider.deckReference?.slides ?? [],
      options: widget.options,
      dataStore: core.LocalPresentationRepository(config),
    );

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void didUpdateWidget(DeckControllerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _deckController.update(options: widget.options);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return InheritedNotifierData(
      data: _deckController,
      child: widget.builder(_deckController),
    );
  }
}
