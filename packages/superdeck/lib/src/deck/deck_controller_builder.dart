import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/provider.dart';
import '../utils/config_resolver.dart';
import '../utils/constants.dart';
import '../utils/deck_watcher.dart';
import 'bundled_deck_service.dart';
import 'deck_controller.dart';
import 'deck_options.dart';

/// Builder widget that creates and manages the DeckController
///
/// Provides the DeckController via InheritedData and manages its lifecycle
/// including deck watcher integration for auto-rebuild functionality.
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
  DeckWatcher? _deckWatcher;
  EffectCleanup? _deckWatcherEffect;
  final _logger = Logger('DeckControllerBuilder');

  @override
  void initState() {
    super.initState();

    final configuration = resolveConfiguration(widget.configuration);
    final deckService = kCanRunProcess
        ? DeckService(configuration: configuration)
        : BundledDeckService(configuration: configuration);

    _deckController = DeckController(
      deckService: deckService,
      options: widget.options,
      // Asset-based runtimes load once; process-capable runtimes can file-watch.
      enableDeckStream: kCanRunProcess,
    );

    // Start runtime deck watcher on process-capable platforms (if enabled).
    if (kCanRunProcess && widget.options.watchForChanges) {
      try {
        _deckWatcher = DeckWatcher(
          configuration: configuration,
          store: deckService,
        );
        unawaited(_deckWatcher!.start());
        _logger.info('Deck watcher started');

        // Sync deck watcher rebuilding state with deck controller using effect.
        _deckWatcherEffect = effect(() {
          final isRebuilding = _deckWatcher!.isRebuilding.value;
          _deckController.setRebuilding(isRebuilding);
        });
      } catch (e) {
        _logger.warning('Deck watcher failed to start: $e');
      }
    } else if (!widget.options.watchForChanges) {
      _logger.info('Deck watcher disabled via DeckOptions.watchForChanges');
    }
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
    // Dispose in correct order:
    // 1. Clean up effects first (stop them from accessing signals)
    _deckWatcherEffect?.call();

    // 2. Stop async operations (watching and signals)
    _deckWatcher?.dispose();

    // 3. Dispose controller last (signals should not be accessed after this)
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
