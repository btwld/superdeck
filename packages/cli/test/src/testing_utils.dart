import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Creates a temporary directory that will be automatically cleaned up
/// when the test completes.
Directory createTempDir() {
  final tempDir = Directory.systemTemp.createTempSync('superdeck_cli_test_');
  addTearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
  return tempDir;
}

/// Creates a temporary directory with async cleanup.
/// Use this for tests that need async setup/tearDown.
Future<Directory> createTempDirAsync() async {
  final tempDir = await Directory.systemTemp.createTemp('superdeck_cli_test_');
  addTearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
  return tempDir;
}

/// Creates a temporary file with the given content and returns the file.
/// The file will be automatically cleaned up when the test completes.
File createTempFile(String content, {String? extension}) {
  final dir = createTempDir();
  final file = File(path.join(dir.path, 'test${extension ?? ''}'));
  file.writeAsStringSync(content);
  return file;
}

/// Creates a test command runner with the given command
CommandRunner<int> createTestRunner(Command<int> command) {
  final runner = CommandRunner<int>('test', 'Test runner');
  runner.addCommand(command);
  return runner;
}

/// Creates a web directory structure for testing web-related commands
Directory createWebDirectory(Directory parent) {
  final webDir = Directory(path.join(parent.path, 'web'));
  webDir.createSync();
  return webDir;
}

/// Creates a basic pubspec.yaml file for testing
File createTestPubspec(Directory parent, {Map<String, dynamic>? content}) {
  final pubspecFile = File(path.join(parent.path, 'pubspec.yaml'));
  final defaultContent = {
    'name': 'test_project',
    'version': '1.0.0',
    'environment': {'sdk': '>=3.0.0 <4.0.0'},
    'dependencies': {
      'flutter': {'sdk': 'flutter'},
    },
  };

  final finalContent = content ?? defaultContent;
  pubspecFile.writeAsStringSync(_mapToYaml(finalContent));
  return pubspecFile;
}

/// Simple YAML serializer for test purposes
String _mapToYaml(Map<String, dynamic> map, [int indent = 0]) {
  final buffer = StringBuffer();
  final spaces = '  ' * indent;

  for (final entry in map.entries) {
    buffer.write('$spaces${entry.key}:');
    if (entry.value is Map<String, dynamic>) {
      buffer.writeln();
      buffer.write(_mapToYaml(entry.value as Map<String, dynamic>, indent + 1));
    } else if (entry.value is List) {
      buffer.writeln();
      for (final item in entry.value as List) {
        buffer.writeln('$spaces  - $item');
      }
    } else {
      buffer.writeln(' ${entry.value}');
    }
  }

  return buffer.toString();
}
