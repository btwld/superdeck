import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

/// Format Dart code using dart format
Future<String> formatDartCode(
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
      'superdeck_${DateTime.now().microsecondsSinceEpoch}_$hash.dart',
    ),
  );

  try {
    await tempFile.create(recursive: true);
    await tempFile.writeAsString(code);

    final args = ['format'];
    if (fix) args.add('--fix');
    if (lineLength != null) {
      args.addAll(['--line-length', lineLength.toString()]);
    }
    args.add(tempFile.path);

    final result = await runDartCommand(
      args,
      environmentOverrides: environmentOverrides,
    );

    if (result.exitCode != 0) {
      throw FormatException(
        'Dart code formatting error: ${result.stderr}',
        code,
      );
    }

    return await tempFile.readAsString();
  } finally {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}
