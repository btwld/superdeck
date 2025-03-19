import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck/superdeck.dart';

class DartProcess {
  static Future<ProcessResult> _run(List<String> args) {
    return Process.run('dart', args);
  }

  static Future<String> format(String code) async {
    final hash = generateValueHash(code);
    // create a temp file with the code
    final tempFile = File(
      p.join(
        Directory.systemTemp.path,
        'temp_${DateTime.now().microsecondsSinceEpoch}_$hash.dart',
      ),
    );
    try {
      await tempFile.create(recursive: true);

      await tempFile.writeAsString(code);

      final result = await _run(['format', '--fix', tempFile.path]);

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
