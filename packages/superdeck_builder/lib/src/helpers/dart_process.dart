import 'dart:io';

class DeckFormatException implements Exception {
  final String message;
  final String source;
  final int? offset;

  DeckFormatException(this.message, this.source, this.offset);

  @override
  String toString() {
    return 'DeckFormatException: $message${offset != null ? ' at offset $offset' : ''}';
  }
}

/// Helper class to interact with the Dart formatter.
class DartProcess {
  /// Formats the given Dart code string using dart format.
  /// Throws a [DeckFormatException] if the formatting fails.
  static Future<String> formatDartCode(String code) async {
    if (code.trim().isEmpty) return code;

    final tempDir = await Directory.systemTemp.createTemp('dart_format_');
    final tempFile = File('${tempDir.path}/temp.dart');

    try {
      await tempFile.writeAsString(code);

      final process = await Process.run(
        'dart',
        ['format', tempFile.path],
        runInShell: true,
      );

      if (process.exitCode != 0) {
        throw _handleFormattingError(process.stderr.toString(), code);
      }

      return await tempFile.readAsString();
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}

DeckFormatException _handleFormattingError(String stderr, String source) {
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
