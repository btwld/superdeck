import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Creates a temporary directory with async cleanup.
Future<Directory> createTempDirAsync() async {
  final tempDir = await Directory.systemTemp.createTemp('superdeck_cli_test_');
  addTearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
  return tempDir;
}

/// Creates a test command runner with the given command.
CommandRunner<int> createTestRunner(Command<int> command) {
  final runner = CommandRunner<int>('test', 'Test runner');
  runner.addCommand(command);
  return runner;
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
    } else if (entry.value is String) {
      final value = (entry.value as String).replaceAll("'", "''");
      buffer.writeln(" '$value'");
    } else {
      buffer.writeln(' ${entry.value}');
    }
  }

  return buffer.toString();
}
