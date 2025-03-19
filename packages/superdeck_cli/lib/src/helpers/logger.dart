import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck/superdeck.dart';

final logger = Logger(
  // Optionally, specify a custom `LogTheme` to override log styles.
  theme: LogTheme(),
  // Optionally, specify a log level (defaults to Level.info).
  level: Level.info,
);

extension LoggerX on Logger {
  void formatError(DeckFormatException exception) {
    final message = exception.message;
    final sourceSpan = exception.source as dynamic;
    final source = sourceSpan.text;
    final start = sourceSpan.start;

    final arrow = _createArrow(start.column);

    final splitLines = source.split('\n');

    // Get the longest line
    final longestLine = splitLines.fold<int>(0, (prev, element) {
      return element.length > prev ? element.length : prev;
    });

    String padline(String line, [int? index]) {
      final pageNumber = index != null ? '${index + 1}' : ' ';

      return ' $pageNumber | ${line.padRight(longestLine + 2)}';
    }

    // Print the error message with the source code
    newLine();
    err('Formatting Error:');
    newLine();
    info('$message on line ${start.line + 1}, column ${start.column + 1}');
    newLine();

    final exceptionLineNumber = start.line;

    // Calculate only 4 lines before and after the error line
    final startLine = (exceptionLineNumber - 5).clamp(0, splitLines.length);
    final endLine = (exceptionLineNumber + 5).clamp(0, splitLines.length);

    for (int i = startLine; i <= endLine; i++) {
      final currentLineContent = splitLines[i];
      final isErrorLine = i == exceptionLineNumber;

      if (isErrorLine) {
        info(padline(currentLineContent, i), style: _highlightLine);
        info(padline(arrow), style: _highlightLine);
      } else {
        _formatCodeBlock(padline(currentLineContent, i));
      }
    }
  }

  void _formatCodeBlock(String message) {
    info(message, style: _formatErrorStyle);
  }

  void newLine() => info('');
}

String _createArrow(int column) {
  return '${' ' * column}^';
}

String? _formatErrorStyle(String? m) {
  return backgroundDefault.wrap(styleBold.wrap(white.wrap(m)));
}

String? _highlightLine(String? m) {
  return backgroundDefault.wrap(styleBold.wrap(yellow.wrap(m)));
}
