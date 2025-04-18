import 'package:mason_logger/mason_logger.dart';

final logger = Logger(
  // Optionally, specify a custom `LogTheme` to override log styles.
  theme: LogTheme(),
  // Optionally, specify a log level (defaults to Level.info).
  level: Level.info,
);

extension LoggerX on Logger {
  void newLine() => info('');
}
