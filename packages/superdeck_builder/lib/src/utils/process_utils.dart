import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/src/common/hash.dart'
    show generateValueHash;

import '../core/deck_format_exception.dart';

/// Utilities for working with processes
class ProcessUtils {
  /// Private constructor to prevent instantiation
  ProcessUtils._();

  /// Run a Dart command with arguments
  static Future<ProcessResult> runDartCommand(List<String> args,
      {Map<String, String>? environmentOverrides}) {
    return Process.run(
      'dart',
      args,
      environment: environmentOverrides?.isNotEmpty == true
          ? environmentOverrides
          : null,
    );
  }

  /// Format Dart code using dart format
  static Future<String> formatDartCode(
    String code, {
    int? lineLength,
    bool fix = true,
    Map<String, String>? environmentOverrides,
  }) async {
    final hash = generateValueHash(code);
    // Create a temp file with the code
    final tempFile = File(
      p.join(
        Directory.systemTemp.path,
        'temp_${DateTime.now().microsecondsSinceEpoch}_$hash.dart',
      ),
    );

    try {
      await tempFile.create(recursive: true);
      await tempFile.writeAsString(code);

      final args = ['format'];
      if (fix) args.add('--fix');
      if (lineLength != null)
        args.addAll(['--line-length', lineLength.toString()]);
      args.add(tempFile.path);

      final result = await runDartCommand(args,
          environmentOverrides: environmentOverrides);

      if (result.exitCode != 0) {
        throw _handleFormattingError(result.stderr as String, code);
      }

      return await tempFile.readAsString();
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Helper function for handling formatting errors
  static DeckFormatException _handleFormattingError(
      String stderr, String source) {
    final match =
        RegExp(r'line (\d+), column (\d+) of .*: (.+)').firstMatch(stderr);

    if (match != null) {
      final line = int.parse(match.group(1)!);
      final column = int.parse(match.group(2)!);
      final message = match.group(3)!;

      // Calculate the offset manually
      final lines = source.split('\n');
      int offset = 0;

      // Add the length of each line plus 1 for the newline character
      for (int i = 0; i < line - 1; i++) {
        if (i < lines.length) {
          offset += lines[i].length + 1; // +1 for the newline character
        }
      }

      // Add the column position (converting to 0-based index)
      if (line - 1 < lines.length) {
        offset += column - 1;
      }

      return DeckFormatException(
        'Dart code formatting error: $message',
        source,
        offset,
      );
    }

    return DeckFormatException(
      'Error formatting dart code: $stderr',
      source,
      null,
    );
  }
}
