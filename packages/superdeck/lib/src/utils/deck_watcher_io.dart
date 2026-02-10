import 'dart:async';
import 'dart:io';

import 'package:signals/signals.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'deck_watcher_types.dart';

/// Watches slide file changes and rebuilds using DeckBuilder directly.
///
/// This replaces the previous subprocess-based watcher with in-process builds.
class DeckWatcher {
  final DeckConfiguration configuration;
  final DeckService? _externalStore;
  final _logger = Logger('DeckWatcher');

  // Reactive state - Signals
  final _status = signal<DeckWatcherStatus>(DeckWatcherStatus.idle);
  final _error = signal<Exception?>(null);
  final _isRebuilding = signal<bool>(false);
  final _lastBuildStatus = signal<String>('unknown');
  final _lastBuildStatusPayload = signal<Map<String, dynamic>?>(null);

  // Non-reactive internal state
  bool _disposed = false;
  DeckService? _store;
  DeckBuilder? _builder;
  StreamSubscription<BuildEvent>? _buildSubscription;

  // Readonly accessors
  ReadonlySignal<DeckWatcherStatus> get status => _status;
  ReadonlySignal<Exception?> get error => _error;
  ReadonlySignal<bool> get isRebuilding => _isRebuilding;
  ReadonlySignal<String> get lastBuildStatus => _lastBuildStatus;

  /// Raw payload from the last build event write (includes slideCount/error).
  Map<String, dynamic>? get lastBuildStatusPayload {
    final payload = _lastBuildStatusPayload.value;
    if (payload == null) return null;
    return Map<String, dynamic>.unmodifiable(payload);
  }

  DeckWatcher({required this.configuration, DeckService? store})
      : _externalStore = store;

  /// Starts watching and rebuilding slides.
  Future<void> start() async {
    if (_status.value != DeckWatcherStatus.idle) {
      _logger.warning('Watcher already started');
      return;
    }

    _status.value = DeckWatcherStatus.starting;
    _error.value = null;

    try {
      _store = _externalStore ?? DeckService(configuration: configuration);
      await _store!.initialize();

      _builder = DeckBuilder(
        tasks: [
          DartFormatterTask(),
          AssetGenerationTask.withDefaults(
            store: _store!,
            browserLaunchOptions: _resolveBrowserLaunchOptions(),
          ),
        ],
        configuration: configuration,
        store: _store!,
      );

      _buildSubscription = _builder!.watchAndBuild().listen(
        _handleBuildEvent,
        onError: _handleUnexpectedWatchError,
        onDone: _handleWatchCompletion,
      );

      _status.value = DeckWatcherStatus.running;
    } catch (error, stackTrace) {
      final exception = error is Exception
          ? error
          : Exception('Failed to start watcher: $error');
      _error.value = exception;
      _status.value = DeckWatcherStatus.failed;
      _logger.severe('Failed to start watcher', error, stackTrace);
    }
  }

  void _handleBuildEvent(BuildEvent event) {
    if (_disposed) return;

    switch (event) {
      case BuildStarted():
        _lastBuildStatus.value = 'building';
        _isRebuilding.value = true;
        _lastBuildStatusPayload.value = {
          'status': 'building',
          'timestamp': DateTime.now().toIso8601String(),
        };
      case BuildCompleted(:final slides):
        _lastBuildStatus.value = 'success';
        _isRebuilding.value = false;
        _error.value = null;
        _status.value = DeckWatcherStatus.running;
        _lastBuildStatusPayload.value = {
          'status': 'success',
          'slideCount': slides.length,
          'timestamp': DateTime.now().toIso8601String(),
        };
      case BuildFailed(:final error, :final stackTrace):
        final exception = error is Exception
            ? error
            : Exception(error.toString());
        _lastBuildStatus.value = 'failure';
        _isRebuilding.value = false;
        _error.value = exception;
        _status.value = DeckWatcherStatus.failed;
        _lastBuildStatusPayload.value = {
          'status': 'failure',
          'timestamp': DateTime.now().toIso8601String(),
          'error': {
            'type': error.runtimeType.toString(),
            'message': error.toString(),
            if (stackTrace != null) 'stackTrace': stackTrace.toString(),
          },
        };
        _logger.severe('Build failed', error, stackTrace);
    }
  }

  void _handleUnexpectedWatchError(Object error, StackTrace stackTrace) {
    if (_disposed) return;

    final exception = error is Exception
        ? error
        : Exception('Watcher stream error: $error');
    _error.value = exception;
    _status.value = DeckWatcherStatus.failed;
    _isRebuilding.value = false;
    _lastBuildStatus.value = 'failure';
    _logger.severe('Watcher stream error', error, stackTrace);
  }

  void _handleWatchCompletion() {
    if (_disposed) return;

    _logger.warning('Watcher stream completed unexpectedly');
    _status.value = DeckWatcherStatus.stopped;
    _isRebuilding.value = false;
  }

  Map<String, dynamic>? _resolveBrowserLaunchOptions() {
    final env = Platform.environment;
    final isCi =
        env['CI'] == 'true' ||
        env['GITHUB_ACTIONS'] == 'true' ||
        env['GITLAB_CI'] == 'true' ||
        env['CIRCLECI'] == 'true' ||
        env['TRAVIS'] == 'true';

    if (!isCi) {
      return null;
    }

    return <String, dynamic>{
      'args': ['--no-sandbox', '--disable-setuid-sandbox'],
    };
  }

  /// Disposes the watcher and all associated resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _status.value = DeckWatcherStatus.stopped;
    _isRebuilding.value = false;

    final buildSubscription = _buildSubscription;
    _buildSubscription = null;
    unawaited(buildSubscription?.cancel());

    final builder = _builder;
    _builder = null;
    if (builder != null) {
      unawaited(builder.dispose());
    }

    // Only clear the store reference if we created it ourselves
    if (_externalStore == null) {
      _store = null;
    }

    _status.dispose();
    _error.dispose();
    _isRebuilding.dispose();
    _lastBuildStatus.dispose();
    _lastBuildStatusPayload.dispose();
  }
}
