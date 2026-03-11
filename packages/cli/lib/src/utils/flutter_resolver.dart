import 'dart:io';

import 'package:path/path.dart' as path;

/// Resolves the Flutter binary, preferring an FVM-managed SDK when available.
///
/// Walks up from [workingDirectory] looking for `.fvm/flutter_sdk/bin/flutter`
/// (or `flutter.bat` on Windows). Falls back to the bare `flutter` command
/// (resolved via PATH).
String resolveFlutterBinary(String workingDirectory) {
  final binaryName = Platform.isWindows ? 'flutter.bat' : 'flutter';
  var dir = Directory(path.absolute(workingDirectory));
  while (true) {
    final candidate = File(
      path.join(dir.path, '.fvm', 'flutter_sdk', 'bin', binaryName),
    );
    if (candidate.existsSync()) return candidate.path;

    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return 'flutter';
}
