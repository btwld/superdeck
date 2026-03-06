import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/provider.dart';
import '../utils/constants.dart';
import '../utils/deck_watcher.dart';
import '../runtime/deck_source.dart';
import '../runtime/superdeck_handle.dart';
import '../runtime/superdeck_runtime.dart';
import 'bundled_deck_service.dart';
import 'deck_controller.dart';

/// Builder widget that creates and manages the DeckController
///
/// Provides the DeckController via InheritedData and manages its lifecycle
/// including deck watcher integration for auto-rebuild functionality.
class DeckControllerBuilder extends StatefulWidget {
  final SuperDeckRuntime runtime;
  final Widget Function(BuildContext context, GoRouter router) builder;

  const DeckControllerBuilder({
    super.key,
    required this.runtime,
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

    final configuration = widget.runtime.configuration;
    final deckService = switch (widget.runtime.source) {
      LocalDeckSource() => DeckService(configuration: configuration),
      BundledDeckSource() => BundledDeckService(
        configuration: configuration,
        deckAssetPath: widget.runtime.bundledDeckAssetPath,
      ),
    };

    _deckController = DeckController(
      deckService: deckService,
      options: widget.runtime.options,
      enableDeckStream: widget.runtime.usesLocalSource && kCanRunProcess,
    );
    widget.runtime.handle.attach(_deckController);

    // Start runtime deck watcher on process-capable platforms (if enabled).
    if (widget.runtime.canWatch && widget.runtime.shouldWatch) {
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
    } else if (!widget.runtime.shouldWatch) {
      _logger.info('Deck watcher disabled via DeckSource.local(watch: false)');
    }
  }

  @override
  void didUpdateWidget(DeckControllerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.runtime.options != oldWidget.runtime.options) {
      _deckController.updateOptions(widget.runtime.options);
    }
    if (!identical(widget.runtime.handle, oldWidget.runtime.handle)) {
      oldWidget.runtime.handle.detach(_deckController);
      widget.runtime.handle.attach(_deckController);
    }
  }

  @override
  void dispose() {
    // Dispose in correct order:
    // 1. Clean up effects first (stop them from accessing signals)
    _deckWatcherEffect?.call();

    // 2. Stop async operations (watching and signals)
    _deckWatcher?.dispose();

    widget.runtime.handle.detach(_deckController);

    // 3. Dispose controller last (signals should not be accessed after this)
    _deckController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedData<SuperDeckHandle>(
      data: widget.runtime.handle,
      child: InheritedData(
        data: _deckController,
        child: Builder(
          builder: (context) {
            return widget.builder(context, _deckController.router);
          },
        ),
      ),
    );
  }
}
