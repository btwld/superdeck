import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Status of the CLI watcher lifecycle.
enum CliWatcherStatus { idle, starting, running, failed, stopped }

/// Watches the CLI build status file and publishes structured updates.
class CliWatcher extends ChangeNotifier {
  CliWatcher({required this.configuration});

  final DeckConfiguration configuration;
  final _logger = getLogger('CliWatcher');

  CliWatcherStatus _status = CliWatcherStatus.idle;
  bool _isDisposed = false;

  /// Last error that prevented status reading. Null when healthy.
  Object? _lastError;

  FileWatcher? _buildStatusWatcher;
  BuildStatus? _currentStatus;
  BuildStatus? _previousStatus;

  // Debounce mechanism to batch rapid file changes
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 100);

  CliWatcherStatus get status => _status;

  /// Last error during status file reading, if any.
  Object? get lastError => _lastError;

  /// Current build status, or null if not yet read.
  BuildStatus? get currentStatus => _currentStatus;

  /// Previous build status, or null if this is the first read.
  BuildStatus? get previousStatus => _previousStatus;

  /// Convenience: current build is in progress.
  bool get isBuilding => _currentStatus?.isBuilding ?? false;

  /// Legacy alias for code expecting `isRebuilding`.
  bool get isRebuilding => isBuilding;

  /// Convenience: last known status type name.
  String get lastBuildStatus => _currentStatus?.type.name ?? 'unknown';

  /// Begins watching `build_status.json`.
  Future<void> start() async {
    if (_isDisposed) return;
    if (_status == CliWatcherStatus.running ||
        _status == CliWatcherStatus.starting) {
      return;
    }

    _setStatus(CliWatcherStatus.starting);

    try {
      await _ensureBuildStatusFile();
      await _startBuildStatusWatcher();
      _setStatus(CliWatcherStatus.running);
    } catch (error, stackTrace) {
      _lastError = error;
      _setStatus(CliWatcherStatus.failed);
      _logger.severe('Failed to start CLI watcher', error, stackTrace);
    }
  }

  Future<void> _ensureBuildStatusFile() async {
    final file = configuration.buildStatusJson;
    if (await file.exists()) return;

    await file.ensureWrite(jsonEncode(BuildStatus.unknown().toJson()));
  }

  Future<void> _startBuildStatusWatcher() async {
    final file = configuration.buildStatusJson;
    _buildStatusWatcher ??= FileWatcher(file)
      ..startWatching(_onBuildStatusChanged);

    await _readAndUpdateStatus();
  }

  void _onBuildStatusChanged() {
    if (_isDisposed) return;

    // Debounce: batch rapid file changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (!_isDisposed) {
        unawaited(_readAndUpdateStatus());
      }
    });
  }

  Future<void> _readAndUpdateStatus() async {
    if (_isDisposed) return;

    try {
      final file = configuration.buildStatusJson;
      if (!await file.exists()) {
        _logger.warning('build_status.json missing at ${file.path}');
        return;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) return;

      final json = jsonDecode(content) as Map<String, dynamic>;
      final newStatus = BuildStatus.fromJson(json);

      // Ignore stale updates
      if (!newStatus.isNewerThan(_currentStatus)) {
        _logger.fine('Ignoring stale status update');
        return;
      }

      _updateStatus(newStatus);
      _lastError = null;
    } catch (error, stackTrace) {
      _lastError = error;
      _logger.warning('Failed to read build status', error, stackTrace);

      // Don't transition to failed - keep running, but surface error
      notifyListeners();
    }
  }

  @visibleForTesting
  Future<void> refresh() => _readAndUpdateStatus();

  void _updateStatus(BuildStatus newStatus) {
    final wasBuilding = _currentStatus?.isBuilding ?? false;
    final nowBuilding = newStatus.isBuilding;

    _previousStatus = _currentStatus;
    _currentStatus = newStatus;

    // Log significant transitions
    if (!wasBuilding && nowBuilding) {
      _logger.info('Build started');
    } else if (wasBuilding && !nowBuilding) {
      _logger.info('Build completed (status: ${newStatus.type.name})');
    }

    notifyListeners();
  }

  void _setStatus(CliWatcherStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _setStatus(CliWatcherStatus.stopped);

    _debounceTimer?.cancel();
    _debounceTimer = null;

    _buildStatusWatcher?.stopWatching();
    _buildStatusWatcher = null;

    super.dispose();
  }
}
