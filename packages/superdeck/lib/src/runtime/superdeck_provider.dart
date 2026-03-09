import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/loading_indicator.dart';
import '../utils/deck_watcher.dart';
import 'bundled_deck_service.dart';
import 'deck_config.dart';

/// Provides deck data loading and file-watching lifecycle.
///
/// Resolves [DeckConfig] into the appropriate [DeckService], manages
/// optional [DeckWatcher] for live-reload, and invokes [builder] only
/// when a [Deck] is available.
///
/// ```dart
/// SuperDeckProvider(
///   config: DeckConfig.local(watch: true),
///   builder: (context, deck) {
///     return SuperDeckApp(deck: deck, theme: theme, extensions: extensions);
///   },
/// )
/// ```
class SuperDeckProvider extends StatefulWidget {
  const SuperDeckProvider({
    super.key,
    required this.config,
    required this.builder,
  });

  final DeckConfig config;
  final Widget Function(BuildContext context, Deck deck) builder;

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

  final _deck = signal<Deck?>(null);
  final _error = signal<Object?>(null);
  final _isRebuilding = signal<bool>(false);

  @override
  void initState() {
    super.initState();

    final config = widget.config;

    if (kIsWeb && config is LocalDeckConfig) {
      throw UnsupportedError(
        'DeckConfig.local is not supported on web runtimes. '
        'Use DeckConfig.bundle(...) instead.',
      );
    }

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

    _deckService = switch (config) {
      LocalDeckConfig() => DeckService(configuration: _workspace),
      BundledDeckConfig(:final deckAssetPath) => BundledDeckService(
        configuration: _workspace,
        deckAssetPath: deckAssetPath,
      ),
    };

    _subscribeToDeckStream();

    if (config case LocalDeckConfig(watch: true)) {
      _startWatcher();
    } else if (config is LocalDeckConfig) {
      _logger.info('Deck watcher disabled via DeckConfig.local(watch: false)');
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
    _deckSubscription = _deckService.loadDeckStream().listen(
      (deck) {
        if (_disposed) return;
        _deck.value = deck;
        _error.value = null;
      },
      onError: (Object e) {
        if (_disposed) return;
        _error.value = e;
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

    await _deckSubscription?.cancel();
    if (_disposed) return;
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
    _error.dispose();
    _isRebuilding.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final error = _error.value;
      final deck = _deck.value;
      final isRebuilding = _isRebuilding.value;

      if (deck == null && error != null) {
        return _RootErrorScreen(error: error, onRetry: _reloadDeck);
      }

      if (deck == null) {
        return const _RootLoadingScreen();
      }

      final child = widget.builder(context, deck);
      return Stack(
        alignment: Alignment.topLeft,
        children: [child, if (isRebuilding) const _RootRebuildingIndicator()],
      );
    });
  }
}

class _RootLoadingScreen extends StatelessWidget {
  const _RootLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const _RootScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 80, height: 80, child: IsometricLoading()),
          SizedBox(height: 16),
          Text('Loading presentation...'),
        ],
      ),
    );
  }
}

class _RootErrorScreen extends StatelessWidget {
  const _RootErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _RootScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 80, height: 80, child: IsometricLoading()),
          const SizedBox(height: 16),
          const Text('Failed to load presentation'),
          const SizedBox(height: 8),
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              unawaited(onRetry());
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4A4A4A)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text('Retry'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RootRebuildingIndicator extends StatelessWidget {
  const _RootRebuildingIndicator();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _withDirectionality(
            context,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xDD000000),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 16, height: 16, child: IsometricLoading()),
                  SizedBox(width: 8),
                  Text('Rebuilding...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RootScaffold extends StatelessWidget {
  const _RootScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF090909),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DefaultTextStyle(
              style: const TextStyle(color: Color(0xFFE6E6E6), fontSize: 14),
              child: _withDirectionality(context, child),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _withDirectionality(BuildContext context, Widget child) {
  if (Directionality.maybeOf(context) != null) {
    return child;
  }

  return Directionality(textDirection: TextDirection.ltr, child: child);
}
