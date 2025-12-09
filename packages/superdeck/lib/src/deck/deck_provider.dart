import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/provider.dart';
import '../utils/cli_watcher.dart';
import '../utils/constants.dart';
import 'deck_controller.dart';
import 'deck_options.dart';

/// Widget that syncs thumbnail generation with deck slide changes
///
/// Automatically regenerates thumbnails when the deck controller's slides change.
/// This separates the thumbnail sync concern from DeckControllerBuilder.
class ThumbnailSyncManager extends StatefulWidget {
  final Widget child;

  const ThumbnailSyncManager({super.key, required this.child});

  @override
  State<ThumbnailSyncManager> createState() => _ThumbnailSyncManagerState();
}

class _ThumbnailSyncManagerState extends State<ThumbnailSyncManager> {
  EffectCleanup? _slidesEffect;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once
    if (_isInitialized) return;
    _isInitialized = true;

    final deck = DeckController.of(context);

    // Use effect instead of Watch to avoid infinite rebuild loop.
    // Watch would cause: slides.value access → generateThumbnails →
    // _thumbnails update → rebuild → repeat infinitely.
    // Effect only tracks slides changes without triggering widget rebuilds.
    _slidesEffect = effect(() {
      // Track slides signal - effect will re-run when slides change
      deck.slides.value;

      // Regenerate thumbnails after frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          deck.generateThumbnails(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _slidesEffect?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No Watch widget - effect handles the reactive tracking
    return widget.child;
  }
}

/// Builder widget that creates and manages the DeckController
///
/// Provides the DeckController via InheritedData and manages its lifecycle
/// including CLI watcher integration for auto-rebuild functionality.
class DeckControllerBuilder extends StatefulWidget {
  final DeckOptions options;
  final Widget Function(BuildContext context, GoRouter router) builder;

  const DeckControllerBuilder({
    super.key,
    required this.options,
    required this.builder,
  });

  @override
  State<DeckControllerBuilder> createState() => _DeckControllerBuilderState();
}

class _DeckControllerBuilderState extends State<DeckControllerBuilder> {
  late final DeckController _deckController;
  CliWatcher? _cliWatcher;
  EffectCleanup? _cliWatcherEffect;
  final _logger = getLogger('DeckControllerBuilder');

  @override
  void initState() {
    super.initState();

    final configuration = DeckConfiguration();
    final deckService = DeckService(configuration: configuration);

    _deckController = DeckController(
      deckService: deckService,
      options: widget.options,
    );

    // Start CLI watcher in debug mode for auto-rebuild
    if (kCanRunProcess) {
      try {
        _cliWatcher = CliWatcher(
          projectRoot: Directory.current,
          configuration: configuration,
        );
        _cliWatcher!.start();
        _logger.info('CLI watcher started');

        // Sync CLI watcher rebuilding state with deck controller using effect
        _cliWatcherEffect = effect(() {
          final isRebuilding = _cliWatcher!.isRebuilding.value;
          _deckController.setRebuilding(isRebuilding);
        });
      } catch (e) {
        _logger.warning('CLI watcher failed to start: $e');
      }
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
    // 2. Stop async operations (CliWatcher file watching and signals)
    // 3. Dispose controller last (signals should not be accessed after this)

    _cliWatcherEffect?.call();
    _cliWatcher?.dispose();
    _deckController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedData(
      data: _deckController,
      child: ThumbnailSyncManager(
        child: Builder(
          builder: (context) {
            return widget.builder(context, _deckController.router);
          },
        ),
      ),
    );
  }
}
