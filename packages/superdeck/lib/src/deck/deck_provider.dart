import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../utils/cli_watcher.dart';
import '../utils/constants.dart';
import '../ui/widgets/provider.dart';
import '../export/thumbnail_controller.dart';
import 'deck_controller.dart';
import 'navigation_controller.dart';
import 'deck_options.dart';

/// Provider for the deck controller
///
/// Uses a custom InheritedWidget (not InheritedNotifierData) to provide
/// manual control over rebuild behavior via ListenableBuilder. This allows
/// fine-grained rebuild control where needed.
///
/// Note: updateShouldNotify returns false - rebuilds are controlled manually
/// through ListenableBuilder widgets in the UI layer.
class DeckProvider extends InheritedWidget {
  final DeckController controller;

  const DeckProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static DeckController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DeckProvider>()!
        .controller;
  }

  @override
  bool updateShouldNotify(DeckProvider oldWidget) => false;
}

/// Provider for the navigation controller
///
/// Uses InheritedNotifierData for automatic rebuild when controller changes.
/// Unlike DeckProvider, this provides automatic propagation of changes to
/// dependent widgets without requiring manual ListenableBuilder.
class NavigationProvider {
  static NavigationController of(BuildContext context) {
    return InheritedNotifierData.of<NavigationController>(context);
  }
}

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

    final deckController = DeckProvider.of(context);
    final thumbnailController = ThumbnailController.of(context);

    // Initial thumbnail generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        thumbnailController.generateThumbnails(deckController.slides.value, context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deckController = DeckProvider.of(context);
    final thumbnailController = ThumbnailController.of(context);

    // Listen to deck changes and regenerate thumbnails
    return Watch((context) {
      final slides = deckController.slides.value;

      // Regenerate thumbnails after frame is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          thumbnailController.generateThumbnails(slides, context);
        }
      });

      return widget.child;
    });
  }
}

/// Builder widget that creates and manages the controller
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
  late final NavigationController _navigationController;
  late final ThumbnailController _thumbnailController;
  CliWatcher? _cliWatcher;
  final _logger = getLogger('DeckControllerBuilder');

  @override
  void initState() {
    super.initState();

    final configuration = DeckConfiguration();
    final repository = DeckRepository(configuration: configuration);

    _deckController = DeckController(
      repository: repository,
      options: widget.options,
    );

    // Create navigation controller with callback for total slides
    _navigationController = NavigationController(
      getTotalSlides: () => _deckController.totalSlides.value,
    );

    _thumbnailController = ThumbnailController();

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
    _navigationController.dispose();
    _deckController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DeckProvider(
      controller: _deckController,
      child: InheritedNotifierData(
        data: _navigationController,
        child: InheritedNotifierData(
          data: _thumbnailController,
          child: ThumbnailSyncManager(
            child: Builder(
              builder: (context) {
                return widget.builder(context, _navigationController.router);
              },
            ),
          ),
        ),
      ),
    );
  }
}
