/// Log level enum
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// LogUtils for consistent logging in the superdeck_builder
class LogUtils {
  /// Private constructor to prevent instantiation
  LogUtils._();

  /// Log level for controlling verbosity
  static LogLevel _level = LogLevel.info;

  /// Whether to display timestamps in log messages
  static bool _showTimestamps = true;

  /// Whether to display colored output
  static bool _colorEnabled = true;

  /// Configure the logger
  static void configure({
    LogLevel? level,
    bool? showTimestamps,
    bool? colorEnabled,
  }) {
    if (level != null) _level = level;
    if (showTimestamps != null) _showTimestamps = showTimestamps;
    if (colorEnabled != null) _colorEnabled = colorEnabled;
  }

  /// Log a debug message (only displayed with debug level or higher)
  static void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (_level.index >= LogLevel.debug.index) {
      _log('DEBUG', message,
          error: error,
          stackTrace: stackTrace,
          data: data,
          color: _AnsiColor.cyan);
    }
  }

  /// Log an info message (only displayed with info level or higher)
  static void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (_level.index >= LogLevel.info.index) {
      _log('INFO', message,
          error: error,
          stackTrace: stackTrace,
          data: data,
          color: _AnsiColor.green);
    }
  }

  /// Log a warning message (only displayed with warning level or higher)
  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (_level.index >= LogLevel.warning.index) {
      _log('WARNING', message,
          error: error,
          stackTrace: stackTrace,
          data: data,
          color: _AnsiColor.yellow);
    }
  }

  /// Log an error message (only displayed with error level or higher)
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (_level.index >= LogLevel.error.index) {
      _log('ERROR', message,
          error: error,
          stackTrace: stackTrace,
          data: data,
          color: _AnsiColor.red);
    }
  }

  /// Internal method to format and print log messages
  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    _AnsiColor color = _AnsiColor.reset,
  }) {
    final buffer = StringBuffer();

    // Add timestamp if enabled
    if (_showTimestamps) {
      final timestamp = DateTime.now().toIso8601String();
      buffer.write('[$timestamp] ');
    }

    // Add log level
    final coloredLevel =
        _colorEnabled ? '${color.code}$level${_AnsiColor.reset.code}' : level;
    buffer.write('$coloredLevel: ');

    // Add message
    buffer.write(message);

    // Add data if present
    if (data != null && data.isNotEmpty) {
      buffer.write(' - ');
      buffer.write(data.toString());
    }

    // Print the log message
    print(buffer.toString());

    // Print error if present
    if (error != null) {
      print('  ERROR: $error');
    }

    // Print stack trace if present
    if (stackTrace != null) {
      print('  STACK TRACE:');
      print(stackTrace
          .toString()
          .split('\n')
          .map((line) => '    $line')
          .join('\n'));
    }
  }
}

/// ANSI color codes for terminal output
class _AnsiColor {
  final String code;

  const _AnsiColor(this.code);

  static const reset = _AnsiColor('\x1B[0m');
  static const red = _AnsiColor('\x1B[31m');
  static const green = _AnsiColor('\x1B[32m');
  static const yellow = _AnsiColor('\x1B[33m');
  static const cyan = _AnsiColor('\x1B[36m');
}
