import 'package:logging/logging.dart';

/// Configure logging for the entire application
void configureLogging({
  Level level = Level.INFO,
  bool includeTimestamp = true,
  bool colorOutput = true,
}) {
  Logger.root.level = level;

  Logger.root.onRecord.listen((record) {
    final timestamp = includeTimestamp ? '[${record.time}] ' : '';
    final levelStr = _formatLevel(record.level, colorOutput);
    final loggerName = record.loggerName.isNotEmpty
        ? '(${record.loggerName}) '
        : '';

    print('$timestamp$levelStr: $loggerName${record.message}');

    if (record.error != null) {
      print('  ERROR: ${record.error}');
    }

    if (record.stackTrace != null) {
      print('  STACKTRACE:');
      print('  ${record.stackTrace.toString().replaceAll('\n', '\n  ')}');
    }
  });
}

/// Get a logger instance for a specific class or component
Logger getLogger(String name) {
  return Logger(name);
}

/// ANSI color codes for different log levels
final _levelColors = {
  Level.FINEST: '\x1B[36m', // Cyan
  Level.FINER: '\x1B[36m', // Cyan
  Level.FINE: '\x1B[36m', // Cyan
  Level.CONFIG: '\x1B[32m', // Green
  Level.INFO: '\x1B[32m', // Green
  Level.WARNING: '\x1B[33m', // Yellow
  Level.SEVERE: '\x1B[31m', // Red
  Level.SHOUT: '\x1B[31m', // Red
};

/// Format level with color if enabled
String _formatLevel(Level level, bool colorOutput) {
  if (!colorOutput) return level.name;

  final color = _levelColors[level] ?? '\x1B[0m';
  const reset = '\x1B[0m';

  return '$color${level.name}$reset';
}

/// Default logger instance for quick access
final logger = Logger('Superdeck');

/// Extensions for the Logger class
extension LoggerX on Logger {
  /// Log with an empty line
  void newLine() => info('');

  /// Log a message with a specific color
  void colorized(String message, String ansiColor) {
    final reset = '\x1B[0m';
    info('$ansiColor$message$reset');
  }

  /// Log a success message (green)
  void success(String message) {
    colorized(message, '\x1B[32m');
  }
}
