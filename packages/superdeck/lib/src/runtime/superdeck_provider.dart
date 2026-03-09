import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/provider.dart';
import '../utils/deck_watcher.dart';
import 'bundled_deck_service.dart';
import 'deck_config.dart';

/// Loading state for the deck.
enum DeckLoadingState { idle, loading, loaded, error }

/// Reactive data state provided by [SuperDeckProvider].
///
/// Holds the current deck, loading/error state, and rebuild status.
/// Access internally via [SuperDeckProvider.of] from [SuperDeckApp].
class DeckDataState {
  DeckDataState({
    required this.deck,
    required this.loadingState,
    required this.error,
    required this.isRebuilding,
    required this.workspace,
    required Future<void> Function() reload,
  }) : _reload = reload;

  final ReadonlySignal<Deck?> deck;
  final ReadonlySignal<DeckLoadingState> loadingState;
  final ReadonlySignal<Object?> error;
  final ReadonlySignal<bool> isRebuilding;
  final DeckWorkspace workspace;
  final Future<void> Function() _reload;

  /// Restarts deck loading from the configured source.
  Future<void> reload() => _reload();
}

/// Provides deck data loading and file-watching lifecycle.
///
/// Resolves [DeckConfig] into the appropriate [DeckService], manages
/// optional [DeckWatcher] for live-reload, and exposes reactive
/// [DeckDataState] to descendants via [InheritedData].
///
/// ```dart
/// SuperDeckProvider(
///   config: DeckConfig.local(watch: true),
///   child: SuperDeckApp(theme: theme, extensions: extensions),
/// )
/// ```
class SuperDeckProvider extends StatefulWidget {
  const SuperDeckProvider({super.key, required this.config, required this.child});

  final DeckConfig config;
  final Widget child;

  /// Returns the [DeckDataState] from the nearest ancestor [SuperDeckProvider].
  ///
  /// Used internally by [SuperDeckApp] to construct [DeckController].
  /// Downstream widgets should use [SuperDeck.of] instead.
  @internal
  static DeckDataState of(BuildContext context) {
    return InheritedData.of<DeckDataState>(context);
  }

  @override
  State<SuperDeckProvider> createState() => _SuperDeckProviderState();
}

class _SuperDeckProviderState extends State<SuperDeckProvider> {
  final _logger = Logger('SuperDeckProvider');

  late final DeckService _deckService;
  late final DeckWorkspace _workspace;

  DeckWatcher? _deckWatcher;
  EffectCleanup? _deckWatcherEffect;
  StreamSubscription<Deck>? _deckSubscription;

  bool _disposed = false;

  // Signals
  final _deck = signal<Deck?>(null);
  final _loadingState = signal<DeckLoadingState>(DeckLoadingState.idle);
  final _error = signal<Object?>(null);
  final _isRebuilding = signal<bool>(false);

  late final DeckDataState _dataState;

  @override
  void initState() {
    super.initState();

    final config = widget.config;

    // Platform validation
    if (kIsWeb && config is LocalDeckConfig) {
      throw UnsupportedError(
        'DeckConfig.local is not supported on web runtimes. '
        'Use DeckConfig.bundle(...) instead.',
      );
    }

    // Workspace computation
    final slidesPath = switch (config) {
      LocalDeckConfig(:final slidesPath) => slidesPath,
      BundledDeckConfig() => null,
    };

    _workspace = DeckWorkspace(
      projectDir: config.projectDir,
      outputDir: config.outputDir,
      assetsPath: config.assetsPath,
      slidesPath: slidesPath,
    );

    // Service resolution
    _deckService = switch (config) {
      LocalDeckConfig() => DeckService(configuration: _workspace),
      BundledDeckConfig(:final deckAssetPath) => BundledDeckService(
        configuration: _workspace,
        deckAssetPath: deckAssetPath,
      ),
    };

    // Build data state
    _dataState = DeckDataState(
      deck: _deck,
      loadingState: _loadingState,
      error: _error,
      isRebuilding: _isRebuilding,
      workspace: _workspace,
      reload: _reloadDeck,
    );

    // Start loading — both DeckService and BundledDeckService implement
    // loadDeckStream() (BundledDeckService yields once and completes).
    _subscribeToDeckStream();

    // Watcher setup
    if (config case LocalDeckConfig(watch: true)) {
      _startWatcher();
    } else if (config is LocalDeckConfig) {
      _logger.info(
        'Deck watcher disabled via DeckConfig.local(watch: false)',
      );
    }
  }

  void _startWatcher() {
    try {
      _deckWatcher = DeckWatcher(
        configuration: _workspace,
        deckService: _deckService,
      );
      unawaited(_deckWatcher!.start());
      _logger.info('Deck watcher started');

      _deckWatcherEffect = effect(() {
        final isRebuilding = _deckWatcher!.isRebuilding.value;
        _isRebuilding.value = isRebuilding;
      });
    } catch (error) {
      _logger.warning('Deck watcher failed to start: $error');
    }
  }

  void _subscribeToDeckStream() {
    _loadingState.value = DeckLoadingState.loading;

    _deckSubscription = _deckService.loadDeckStream().listen(
      (deck) {
        if (_disposed) return;
        _deck.value = deck;
        _loadingState.value = DeckLoadingState.loaded;
        _error.value = null;
      },
      onError: (Object e) {
        if (_disposed) return;
        _error.value = e;
        _loadingState.value = DeckLoadingState.error;
      },
      onDone: () {
        if (_disposed) return;
        _logger.info('Deck stream completed');
      },
    );
  }

  Future<void> _reloadDeck() async {
    if (_disposed) return;

    _error.value = null;
    _loadingState.value = DeckLoadingState.loading;

    await _deckSubscription?.cancel();
    _deckSubscription = null;

    _subscribeToDeckStream();
  }

  @override
  void dispose() {
    _disposed = true;

    _deckWatcherEffect?.call();
    _deckWatcher?.dispose();

    unawaited(_deckSubscription?.cancel());

    _deck.dispose();
    _loadingState.dispose();
    _error.dispose();
    _isRebuilding.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedData<DeckDataState>(
      data: _dataState,
      child: widget.child,
    );
  }
}
