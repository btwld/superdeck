import 'package:flutter/foundation.dart';

/// Debug logger for tracking GenUI workflow events.
///
/// Routes log output to [debugPrint] (Flutter's console) when in debug mode.
/// No file I/O; fully web-safe.
class DebugLogger {
  static final _instance = DebugLogger._internal();
  static DebugLogger get instance => _instance;

  DebugLogger._internal();

  /// Log a message with timestamp and category.
  void log(String category, String message) {
    if (!kDebugMode) return;
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('[$timestamp] [$category] $message');
  }

  /// Log a surface event.
  void surface(String event, String surfaceId) {
    log('SURFACE', '$event: $surfaceId');
  }

  /// Log a user action.
  void userAction(String action, [Map<String, dynamic>? context]) {
    final contextStr = context != null ? ' | $context' : '';
    log('USER', '$action$contextStr');
  }

  /// Log an AI response.
  void aiResponse(String type, String content) {
    final truncated = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;
    log('AI', '$type: $truncated');
  }

  /// Log an error with optional stack trace.
  void error(String source, dynamic error, [StackTrace? stack]) {
    if (!kDebugMode) return;
    log('ERROR', '$source: $error');
    if (stack != null) {
      log('STACK', stack.toString().split('\n').take(5).join('\n'));
    }
  }

  /// Add a section separator.
  void section(String title) {
    if (!kDebugMode) return;
    debugPrint('\n--- $title ---');
  }
}

/// Global shortcut for logging.
DebugLogger get debugLog => DebugLogger.instance;
