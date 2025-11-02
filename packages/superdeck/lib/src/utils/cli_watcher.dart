import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
/// Automatically starts `dart run superdeck build --watch` and monitors
/// the process health. Injects error presentations when the process fails.
class CliWatcher extends ChangeNotifier {
  final Directory projectRoot;
  final DeckConfiguration configuration;
  final _logger = getLogger('CliWatcher');

  // State fields
  CliWatcherStatus _status = CliWatcherStatus.idle;
  Exception? _error;
  bool _isRebuilding = false;
  bool _isWatchingBuildStatus = false;
  bool _isReadingBuildStatus = false;
  FileWatcher? _buildStatusWatcher;
  DateTime? _lastBuildStatusTimestamp;
  String _lastBuildStatus = 'unknown';
  Map<String, dynamic>? _lastBuildStatusPayload;

  // Process management
  Process? _process;
  final StringBuffer _stdoutBuffer = StringBuffer();
  final StringBuffer _stderrBuffer = StringBuffer();
  String? _lastErrorLine;
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;

  /// Current status of the watcher
  CliWatcherStatus get status => _status;

  /// Current error, if any
  Exception? get error => _error;

  /// Whether the CLI is currently rebuilding
  bool get isRebuilding => _isRebuilding;

  /// Latest status recorded in build_status.json (success, failure, unknown).
  String get lastBuildStatus => _lastBuildStatus;

  /// Raw payload from the last build status write (includes slideCount/error).
  Map<String, dynamic>? get lastBuildStatusPayload {
    final payload = _lastBuildStatusPayload;
    if (payload == null) return null;
    return Map<String, dynamic>.unmodifiable(payload);
  }

  CliWatcher({required this.projectRoot, required this.configuration});

  /// Starts the CLI watcher process
  Future<void> start() async {
    if (_status != CliWatcherStatus.idle) {
      _logger.warning('CLI watcher already started');
      return;
    }

    _status = CliWatcherStatus.starting;
    _error = null;
    notifyListeners();

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
      _stdoutSubscription = _process!.stdout.listen((data) {
        // Accumulate chunks and process line-by-line to handle ANSI/progress updates
        final chunk = String.fromCharCodes(data);
        _stdoutBuffer.write(chunk);

        // Normalize carriage returns used by progress spinners
        var text = _stdoutBuffer.toString().replaceAll('\r', '\n');
        final lastNewline = text.lastIndexOf('\n');

        if (lastNewline == -1) {
          // Wait for a full line
          return;
        }

        final complete = text.substring(0, lastNewline);
        final remainder = text.substring(lastNewline + 1);
        _stdoutBuffer
          ..clear()
          ..write(remainder);

        final lines = complete.split('\n');
        for (var line in lines) {
          // Strip ANSI escape codes
          line = line.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
          line = line.trim();
          if (line.isEmpty) continue;

          _logger.info('[CLI] $line');
        }
      }, onError: (error) => _logger.warning('stdout error: $error'));

      _stderrSubscription = _process!.stderr.listen((data) {
        // Accumulate chunks and process line-by-line to handle ANSI/progress updates
        final chunk = String.fromCharCodes(data);
        _stderrBuffer.write(chunk);

        var text = _stderrBuffer.toString().replaceAll('\r', '\n');
        final lastNewline = text.lastIndexOf('\n');

        if (lastNewline == -1) {
          return;
        }

        final complete = text.substring(0, lastNewline);
        final remainder = text.substring(lastNewline + 1);
        _stderrBuffer
          ..clear()
          ..write(remainder);

        final lines = complete.split('\n');
        for (var line in lines) {
          // Strip ANSI escape codes
          line = line.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
          line = line.trim();
          if (line.isEmpty) continue;

          _lastErrorLine = line;
          _logger.severe('[CLI ERROR] $line');
          debugPrint('[CLI ERROR] $line');
        }
      }, onError: (error) => _logger.warning('stderr error: $error'));

      _status = CliWatcherStatus.running;
      notifyListeners();

      // Monitor process exit
      unawaited(
        _process!.exitCode.then((exitCode) {
          _handleProcessExit(exitCode);
        }),
      );
    } catch (e) {
      final exception = Exception('Failed to start CLI watcher: $e');
      _error = exception;
      _status = CliWatcherStatus.failed;
      notifyListeners();
      await _writeErrorPresentation(exception);
      _logger.severe('Failed to start CLI watcher', e);
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
    if (_status == CliWatcherStatus.stopped) {
      // Already disposed, nothing to do
      return;
    }

    _logger.info('CLI process exited with code: $exitCode');

    if (exitCode == 0) {
      _status = CliWatcherStatus.stopped;
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
      _error = exception;
      _status = CliWatcherStatus.failed;
      await _writeErrorPresentation(exception);
    }

    // Only notify if not disposed
    if (_status != CliWatcherStatus.stopped) {
      notifyListeners();
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
    if (_isReadingBuildStatus) return;

    // Check if disposed before starting
    if (_status == CliWatcherStatus.stopped) return;

    _isReadingBuildStatus = true;

    try {
      final file = configuration.buildStatusJson;
      if (!await file.exists()) {
        return;
      }

      final raw = await file.readAsString();
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

      final previousStatus = _lastBuildStatus;
      final wasRebuilding = _isRebuilding;
      _lastBuildStatus = status;
      _lastBuildStatusPayload = payload;

      // Update rebuilding state based on status
      _isRebuilding = (status == 'building');

      var shouldNotify =
          previousStatus != status || wasRebuilding != _isRebuilding;

      // Only notify if not disposed
      if (shouldNotify && _status != CliWatcherStatus.stopped) {
        if (_isRebuilding) {
          _logger.info('Build started (status: building)');
        } else if (previousStatus == 'building') {
          _logger.info('Build completed (status: $_lastBuildStatus)');
        }
        notifyListeners();
      }
    } finally {
      _isReadingBuildStatus = false;
    }
  }

  /// Disposes the watcher and kills the process
  @override
  void dispose() {
    // ChangeNotifier.dispose() can only be called once, so check if already disposed
    if (_status == CliWatcherStatus.stopped) {
      return;
    }

    _status = CliWatcherStatus.stopped;

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

    super.dispose();
  }
}
