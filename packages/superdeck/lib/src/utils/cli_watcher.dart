import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Status of the CLI watcher process
enum CliWatcherStatus {
  /// Not started yet
  idle,

  /// Process.start called, waiting for first output
  starting,

  /// Process healthy and watching
  running,

  /// Process exited with error or couldn't start
  failed,

  /// Explicitly stopped via dispose()
  stopped,
}

/// Watches and manages the CLI build process
///
/// Automatically starts `dart run superdeck_cli:main build --watch` and monitors
/// the process health. Injects error presentations when the process fails.
class CliWatcher {
  final Directory projectRoot;
  final DeckConfiguration configuration;
  final _logger = Logger('CliWatcher');

  // Reactive state - Signals
  final _status = signal<CliWatcherStatus>(CliWatcherStatus.idle);
  final _error = signal<Exception?>(null);
  final _isRebuilding = signal<bool>(false);
  final _lastBuildStatus = signal<String>('unknown');
  final _lastBuildStatusPayload = signal<Map<String, dynamic>?>(null);

  // Non-reactive internal state
  bool _disposed = false;
  bool _isWatchingBuildStatus = false;
  bool _isReadingBuildStatus = false;
  FileWatcher? _buildStatusWatcher;
  DateTime? _lastBuildStatusTimestamp;

  // Process management
  Process? _process;
  final StringBuffer _stdoutBuffer = StringBuffer();
  final StringBuffer _stderrBuffer = StringBuffer();
  String? _lastErrorLine;
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;

  // Readonly accessors
  ReadonlySignal<CliWatcherStatus> get status => _status;
  ReadonlySignal<Exception?> get error => _error;
  ReadonlySignal<bool> get isRebuilding => _isRebuilding;
  ReadonlySignal<String> get lastBuildStatus => _lastBuildStatus;

  /// Raw payload from the last build status write (includes slideCount/error).
  Map<String, dynamic>? get lastBuildStatusPayload {
    final payload = _lastBuildStatusPayload.value;
    if (payload == null) return null;
    return Map<String, dynamic>.unmodifiable(payload);
  }

  CliWatcher({required this.projectRoot, required this.configuration});

  /// Starts the CLI watcher process
  Future<void> start() async {
    if (_status.value != CliWatcherStatus.idle) {
      _logger.warning('CLI watcher already started');
      return;
    }

    _status.value = CliWatcherStatus.starting;
    _error.value = null;

    try {
      await _initializeBuildStatusMonitoring();

      final executable = _findDartExecutable();
      _logger.info('Starting CLI watcher with executable: $executable');

      _process = await Process.start(executable, [
        'run',
        'superdeck_cli:main',
        'build',
        '--watch',
      ], workingDirectory: projectRoot.path);

      // Subscribe to streams to prevent buffer blocking
      _stdoutSubscription = _process!.stdout.listen(
        (data) => _processStreamLines(
          data,
          _stdoutBuffer,
          (line) => _logger.info('[CLI] $line'),
        ),
        onError: (error) => _logger.warning('stdout error: $error'),
      );

      _stderrSubscription = _process!.stderr.listen(
        (data) => _processStreamLines(data, _stderrBuffer, (line) {
          _lastErrorLine = line;
          _logger.severe('[CLI ERROR] $line');
          debugPrint('[CLI ERROR] $line');
        }),
        onError: (error) => _logger.warning('stderr error: $error'),
      );

      _status.value = CliWatcherStatus.running;

      // Monitor process exit
      unawaited(
        _process!.exitCode.then((exitCode) {
          _handleProcessExit(exitCode);
        }),
      );
    } catch (e) {
      final exception = Exception('Failed to start CLI watcher: $e');
      _error.value = exception;
      _status.value = CliWatcherStatus.failed;
      await _writeErrorPresentation(exception);
      _logger.severe('Failed to start CLI watcher', e);
    }
  }

  /// Processes incoming stream data line-by-line with ANSI code stripping.
  ///
  /// Accumulates chunks in [buffer], extracts complete lines,
  /// strips ANSI escape codes, and calls [onLine] for each non-empty line.
  void _processStreamLines(
    List<int> data,
    StringBuffer buffer,
    void Function(String line) onLine,
  ) {
    final chunk = String.fromCharCodes(data);
    buffer.write(chunk);

    // Normalize carriage returns used by progress spinners
    var text = buffer.toString().replaceAll('\r', '\n');
    final lastNewline = text.lastIndexOf('\n');

    if (lastNewline == -1) {
      // Wait for a full line
      return;
    }

    final complete = text.substring(0, lastNewline);
    final remainder = text.substring(lastNewline + 1);
    buffer
      ..clear()
      ..write(remainder);

    final lines = complete.split('\n');
    for (var line in lines) {
      // Strip ANSI escape codes
      line = line.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
      line = line.trim();
      if (line.isEmpty) continue;

      onLine(line);
    }
  }

  /// Finds the dart executable, preferring FVM if available
  String _findDartExecutable() {
    // Check for FVM dart first
    final fvmDart = File(
      '.fvm/flutter_sdk/bin/dart${Platform.isWindows ? '.exe' : ''}',
    );
    if (fvmDart.existsSync()) {
      return fvmDart.path;
    }

    // Fallback to PATH dart
    return 'dart${Platform.isWindows ? '.exe' : ''}';
  }

  /// Handles process exit
  Future<void> _handleProcessExit(int exitCode) async {
    // Check disposal flag BEFORE accessing any signals to avoid
    // "signal read after disposed" warning when dispose() was called
    // before this async callback executed
    if (_disposed) {
      return;
    }

    if (_status.value == CliWatcherStatus.stopped) {
      // Already stopped via dispose(), nothing to do
      return;
    }

    _logger.info('CLI process exited with code: $exitCode');

    if (exitCode == 0) {
      _status.value = CliWatcherStatus.stopped;
    } else {
      final lastError = _lastErrorLine;
      if (lastError != null) {
        _logger.severe('Last CLI stderr line before exit: $lastError');
      }
      final exception = Exception(
        lastError == null
            ? 'CLI process exited with code: $exitCode'
            : 'CLI process exited with code $exitCode. Last stderr line: $lastError',
      );
      _error.value = exception;
      _status.value = CliWatcherStatus.failed;
      await _writeErrorPresentation(exception);
    }
  }

  /// Writes an error deck to the deck.json file
  Future<void> _writeErrorPresentation(Exception exception) async {
    try {
      final errorDeck = Deck(
        slides: [
          Slide.error(
            title: 'CLI Build Process Failed',
            message: 'Watch process exited unexpectedly',
            error: exception,
          ),
        ],
        configuration: configuration,
      );

      final repository = DeckService(configuration: configuration);
      await repository.saveReferences(errorDeck);
      _logger.info('Error deck written to ${configuration.deckJson.path}');
    } catch (e) {
      _logger.severe('Failed to write error deck', e);
    }
  }

  Future<void> _initializeBuildStatusMonitoring() async {
    if (_isWatchingBuildStatus) return;

    final file = configuration.buildStatusJson;
    if (!await file.exists()) {
      await file.ensureWrite(
        jsonEncode({
          'status': 'unknown',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    }

    _buildStatusWatcher = FileWatcher(file);
    _buildStatusWatcher!.startWatching(_refreshBuildStatus);
    _isWatchingBuildStatus = true;

    await _refreshBuildStatus();
  }

  Future<void> _refreshBuildStatus() async {
    if (_isReadingBuildStatus || _disposed) return;

    // Check if disposed before starting
    if (_status.value == CliWatcherStatus.stopped) return;

    _isReadingBuildStatus = true;

    try {
      final file = configuration.buildStatusJson;
      if (!await file.exists()) {
        return;
      }

      // Guard after async operation - dispose could have been called
      if (_disposed) return;

      final raw = await file.readAsString();

      // Guard after async operation
      if (_disposed) return;

      if (raw.trim().isEmpty) {
        return;
      }

      Map<String, dynamic> payload;
      try {
        payload = Map<String, dynamic>.from(
          jsonDecode(raw) as Map<dynamic, dynamic>,
        );
      } catch (e, stackTrace) {
        _logger.warning('Failed to decode build_status.json: $e');
        _logger.fine('$stackTrace');
        return;
      }

      final status = (payload['status'] as String? ?? 'unknown').toLowerCase();
      final timestampRaw = payload['timestamp'] as String?;
      final timestamp = timestampRaw != null
          ? DateTime.tryParse(timestampRaw)
          : null;

      if (_lastBuildStatusTimestamp != null &&
          timestamp != null &&
          !timestamp.isAfter(_lastBuildStatusTimestamp!)) {
        return;
      }

      _lastBuildStatusTimestamp = timestamp ?? DateTime.now();

      // Guard before accessing signals - dispose could have happened during parsing
      if (_disposed) return;

      final previousStatus = _lastBuildStatus.value;
      final wasRebuilding = _isRebuilding.value;

      // Update signals (only if not disposed)
      _lastBuildStatus.value = status;
      _lastBuildStatusPayload.value = payload;

      // Update rebuilding state based on status
      _isRebuilding.value = (status == 'building');

      // Log state changes
      if (previousStatus != status || wasRebuilding != _isRebuilding.value) {
        if (_isRebuilding.value) {
          _logger.info('Build started (status: building)');
        } else if (previousStatus == 'building') {
          _logger.info('Build completed (status: $_lastBuildStatus)');
        }
      }
    } finally {
      _isReadingBuildStatus = false;
    }
  }

  /// Disposes the watcher and kills the process
  void dispose() {
    // Check if already disposed (use bool flag to avoid reading disposed signals)
    if (_disposed) {
      return;
    }
    _disposed = true;

    _status.value = CliWatcherStatus.stopped;

    // Stop file watching
    _buildStatusWatcher?.stopWatching();
    _isWatchingBuildStatus = false;
    _buildStatusWatcher = null;

    // Cancel stream subscriptions
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();

    // Kill process
    if (_process != null) {
      _logger.info('Killing CLI watcher process');
      _process!.kill();
      _process = null;
    }

    // Dispose signals
    _status.dispose();
    _error.dispose();
    _isRebuilding.dispose();
    _lastBuildStatus.dispose();
    _lastBuildStatusPayload.dispose();
  }
}
