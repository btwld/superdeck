import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'exceptions.dart';
import 'package:superdeck_core/superdeck_core.dart';

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

    // Create a SourceFile from the source code
    final sourceFile = SourceFile.fromString(source);

    // Get the location using line and column (converting to 0-based indices)
    final location = sourceFile.location(
      sourceFile.getOffset(line - 1, column - 1),
    );

    // Create a point span at the error location
    final span = location.pointSpan();

    return DeckFormatException(
      'Dart code formatting error: $message',
      span,
      source,
    );
  }

  return DeckFormatException(
    'Error formatting dart code: $stderr',
    null,
    source,
  );
}
