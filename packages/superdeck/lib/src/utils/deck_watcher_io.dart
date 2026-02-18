import 'dart:async';
import 'dart:io';

import 'package:signals/signals.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'deck_watcher_types.dart';

typedef DeckBuilderFactory =
    DeckBuilder Function({
      required DeckConfiguration configuration,
      required DeckService store,
    });

/// Returns whether the process is running in a CI environment.
bool _isCI() {
  final env = Platform.environment;
  return env['CI'] == 'true' ||
      env['GITHUB_ACTIONS'] == 'true' ||
      env['GITLAB_CI'] == 'true' ||
      env['CIRCLECI'] == 'true' ||
      env['TRAVIS'] == 'true';
}

DeckBuilder _createStandardBuilder({
  required DeckConfiguration configuration,
  required DeckService store,
}) {
  // In CI environments, Chrome needs --no-sandbox due to user namespace restrictions.
  final browserLaunchOptions = _isCI()
      ? <String, dynamic>{
          'args': ['--no-sandbox', '--disable-setuid-sandbox'],
        }
      : null;

  return DeckBuilder(
    tasks: [
      DartFormatterTask(),
      AssetGenerationTask.withDefaults(
        store: store,
        browserLaunchOptions: browserLaunchOptions,
      ),
    ],
    configuration: configuration,
    store: store,
  );
}

/// Watches slide file changes and rebuilds with typed build events.
class DeckWatcher {
  final DeckConfiguration configuration;
  final DeckService _store;
  final DeckBuilderFactory _builderFactory;

  final _logger = Logger('DeckWatcher');

  final _status = signal<DeckWatcherStatus>(DeckWatcherStatus.idle);
  final _error = signal<Object?>(null);
  final _isRebuilding = signal<bool>(false);

  bool _disposed = false;
  DeckBuilder? _builder;
  StreamSubscription<BuildEvent>? _buildSubscription;

  ReadonlySignal<DeckWatcherStatus> get status => _status;
  ReadonlySignal<Object?> get error => _error;
  ReadonlySignal<bool> get isRebuilding => _isRebuilding;

  DeckWatcher({
    required this.configuration,
    DeckService? store,
    DeckBuilderFactory? builderFactory,
  }) : _store = store ?? DeckService(configuration: configuration),
       _builderFactory = builderFactory ?? _createStandardBuilder;

  Future<void> start() async {
    if (_disposed || _status.value == DeckWatcherStatus.stopped) {
      return;
    }

    if (_status.value != DeckWatcherStatus.idle) {
      _logger.warning('Deck watcher already started');
      return;
    }

    _status.value = DeckWatcherStatus.starting;
    _error.value = null;

    try {
      await _store.initialize();

      _builder = _builderFactory(configuration: configuration, store: _store);

      _buildSubscription = _builder!.watchAndBuild().listen(
        _handleBuildEvent,
        onError: _handleUnexpectedWatchError,
        onDone: _handleWatchCompletion,
      );

      if (_disposed) return;
      _status.value = DeckWatcherStatus.running;
    } on Object catch (error, stackTrace) {
      if (_disposed) return;
      _error.value = error;
      _isRebuilding.value = false;
      _status.value = DeckWatcherStatus.failed;
      _logger.severe('Failed to start deck watcher', error, stackTrace);
    }
  }

  void _handleBuildEvent(BuildEvent event) {
    if (_disposed) return;

    switch (event) {
      case BuildStarted():
        _status.value = DeckWatcherStatus.running;
        _error.value = null;
        _isRebuilding.value = true;
      case BuildCompleted():
        _status.value = DeckWatcherStatus.running;
        _isRebuilding.value = false;
      case BuildFailed(:final error, :final stackTrace):
        _status.value = DeckWatcherStatus.failed;
        _error.value = error;
        _isRebuilding.value = false;
        _logger.severe('Deck build failed while watching', error, stackTrace);
    }
  }

  void _handleUnexpectedWatchError(Object error, StackTrace stackTrace) {
    if (_disposed) return;

    _status.value = DeckWatcherStatus.failed;
    _error.value = error;
    _isRebuilding.value = false;
    _logger.severe('Deck watcher stream error', error, stackTrace);
  }

  void _handleWatchCompletion() {
    if (_disposed) return;

    _status.value = DeckWatcherStatus.stopped;
    _isRebuilding.value = false;
    _logger.warning('Deck watcher stream completed unexpectedly');
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _status.value = DeckWatcherStatus.stopped;
    _isRebuilding.value = false;

    final buildSubscription = _buildSubscription;
    _buildSubscription = null;
    final builder = _builder;
    _builder = null;

    unawaited(() async {
      await buildSubscription?.cancel();
      await builder?.dispose();
    }());

    _status.dispose();
    _error.dispose();
    _isRebuilding.dispose();
  }
}
