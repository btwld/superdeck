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
import 'navigation_controller.dart';

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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final deck = DeckController.of(context);

    // Initial thumbnail generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        deck.generateThumbnails(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deck = DeckController.of(context);

    // Listen to slide changes and regenerate thumbnails
    return Watch((context) {
      // Watch the slides signal to trigger rebuild when it changes
      deck.slides.value;

      // Regenerate after frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          deck.generateThumbnails(context);
        }
      });

      return widget.child;
    });
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

        // Sync CLI watcher rebuilding state with deck controller
        _cliWatcher!.addListener(_onCliWatcherChanged);
      } catch (e) {
        _logger.warning('CLI watcher failed to start: $e');
      }
    }
  }

  void _onCliWatcherChanged() {
    if (_cliWatcher != null) {
      _deckController.setRebuilding(_cliWatcher!.isRebuilding);
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
    _cliWatcher?.removeListener(_onCliWatcherChanged);
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

/// Provider for the navigation controller (backward compatibility)
///
/// This class provides access to navigation functionality for Phase 4 migration.
/// Returns a NavigationControllerAdapter that delegates to DeckController.
/// Will be removed in Phase 5 after all consumers are updated.
@Deprecated('Use DeckController.of(context) instead')
class NavigationProvider {
  static NavigationController of(BuildContext context) {
    final deck = DeckController.of(context);
    // Return an adapter that delegates to DeckController
    return _NavigationControllerAdapter(deck);
  }
}

/// Adapter that makes DeckController compatible with NavigationController API
///
/// This temporary adapter allows existing consumers to continue using
/// NavigationController methods while the underlying implementation
/// uses DeckController. Will be removed in Phase 5.
class _NavigationControllerAdapter extends NavigationController {
  final DeckController _deck;

  _NavigationControllerAdapter(this._deck)
      : super(getTotalSlides: () => _deck.totalSlides.value) {
    // Override the router with DeckController's router
    router = _deck.router;
  }

  @override
  int get currentIndex => _deck.currentIndex.value;

  @override
  Future<void> goToSlide(int index) => _deck.goToSlide(index);

  @override
  Future<void> nextSlide() => _deck.nextSlide();

  @override
  Future<void> previousSlide() => _deck.previousSlide();

  @override
  void updateCurrentIndex(int index) {
    // DeckController's router handles index updates internally via onIndexChanged
    // This method is called when the route changes, but the router already
    // propagates the change to _deck._updateCurrentIndex via the callback.
    // No action needed here.
  }

  @override
  bool get isTransitioning => _deck.isTransitioning.value;

  @override
  bool get canGoNext => _deck.canGoNext.value;

  @override
  bool get canGoPrevious => _deck.canGoPrevious.value;
}
