import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:superdeck_ai/core/constants/paths.dart';

/// Debug file logger for tracking GenUI workflow events.
///
/// Writes logs to `.superdeck/debug.log` when in debug mode.
/// Uses buffered async writing to avoid blocking the UI thread.
/// Creates a new file on each app run (clears previous logs).
class DebugLogger {
  static final _instance = DebugLogger._internal();
  static DebugLogger get instance => _instance;

  DebugLogger._internal();

  File? _logFile;
  bool _initialized = false;
  bool _fileLoggingEnabled = false;

  /// Buffer for pending log lines to reduce file I/O.
  final _buffer = StringBuffer();

  /// Timer for periodic buffer flushing.
  Timer? _flushTimer;

  /// Guard to prevent concurrent flush operations.
  bool _flushing = false;

  /// Maximum buffer size before forcing a flush.
  static const _maxBufferSize = 4096;

  /// Flush interval in milliseconds.
  static const _flushInterval = Duration(milliseconds: 500);

  /// Initialize the logger. Clears existing log file.
  /// Disabled on web platforms (dart:io not supported).
  Future<void> init() async {
    if (!kDebugMode || kIsWeb) return;
    if (_initialized) return;

    try {
      final dir = Directory(Paths.superdeckDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      _logFile = File(Paths.debugLogPath);

      // Clear file on each run
      await _logFile!.writeAsString(
        '=== SuperDeck AI Debug Log ===\n'
        'Started: ${DateTime.now().toIso8601String()}\n'
        '${'=' * 40}\n\n',
      );

      _fileLoggingEnabled = true;

      // Start periodic flush timer
      _flushTimer = Timer.periodic(_flushInterval, (_) => _flushBuffer());
    } catch (e) {
      _logFile = null;
      _fileLoggingEnabled = false;
      debugPrint('[DebugLogger] File logging disabled: $e');
    } finally {
      _initialized = true;
    }
  }

  /// Flush the buffer to file asynchronously.
  Future<void> _flushBuffer() async {
    // Prevent concurrent flush operations
    if (_flushing || _buffer.isEmpty || _logFile == null) return;

    _flushing = true;
    final content = _buffer.toString();
    _buffer.clear();

    try {
      await _logFile!.writeAsString(content, mode: FileMode.append);
    } catch (_) {
      // Ignore file write errors in debug logging
    } finally {
      _flushing = false;
    }
  }

  /// Add a line to the buffer and flush if needed.
  void _appendToBuffer(String line) {
    _buffer.write(line);

    // Flush immediately if buffer is too large
    if (_buffer.length > _maxBufferSize) {
      _flushBuffer();
    }
  }

  /// Log a message with timestamp and category.
  void log(String category, String message) {
    if (!kDebugMode || !_initialized) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final line = '[$timestamp] [$category] $message\n';

    if (_fileLoggingEnabled) {
      _appendToBuffer(line);
    }
    debugPrint(line.trimRight());
  }

  /// Log a surface event
  void surface(String event, String surfaceId) {
    log('SURFACE', '$event: $surfaceId');
  }

  /// Log user action
  void userAction(String action, [Map<String, dynamic>? context]) {
    final contextStr = context != null ? ' | $context' : '';
    log('USER', '$action$contextStr');
  }

  /// Log AI response
  void aiResponse(String type, String content) {
    final truncated = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;
    log('AI', '$type: $truncated');
  }

  /// Log error
  void error(String source, dynamic error, [StackTrace? stack]) {
    log('ERROR', '$source: $error');
    if (stack != null) {
      log('STACK', stack.toString().split('\n').take(5).join('\n'));
    }
  }

  /// Add a section separator
  void section(String title) {
    if (!kDebugMode || !_initialized) return;
    final line = '\n--- $title ---\n';
    if (_fileLoggingEnabled) {
      _appendToBuffer(line);
    }
    debugPrint(line.trimRight());
  }

  /// Dispose of the logger, flushing any remaining buffer.
  Future<void> dispose() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flushBuffer();
  }
}

/// Global shortcut for logging
DebugLogger get debugLog => DebugLogger.instance;
