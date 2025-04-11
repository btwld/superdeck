import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/setup_command.dart';
import 'package:test/test.dart';

void main() {
  group('SetupCommand', () {
    late Directory tempDir;
    late Directory webDir;
    late SetupCommand command;
    late CommandRunner<int> runner;

    setUp(() async {
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('setup_command_test_');

      // Create a web directory within the temp dir
      webDir = Directory(path.join(tempDir.path, 'web'));
      await webDir.create();

      // Create a basic test runner
      runner = CommandRunner<int>('test', 'Test runner for SetupCommand');

      // Add our command
      command = SetupCommand();
      runner.addCommand(command);
    });

    tearDown(() async {
      // Clean up test directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('sets up custom index.html when web directory exists', () async {
      // Change the current working directory to the test directory temporarily
      final previousDir = Directory.current;
      Directory.current = tempDir;

      try {
        // Create a basic original index.html file
        final indexFile = File(path.join(webDir.path, 'index.html'));
        await indexFile.writeAsString('''
<!DOCTYPE html>
<html>
<head>
  <title>Original Test File</title>
</head>
<body>
  <h1>Test</h1>
</body>
</html>
''');

        // Execute the command with the setup-web flag
        final result = await runner.run(['setup', '--setup-web']);

        // Verify the command executed successfully
        expect(result, equals(0));

        // Verify the backup file was created
        final backupFile = File(path.join(webDir.path, 'index.html.bak'));
        expect(await backupFile.exists(), isTrue);

        // Verify the index.html was replaced with our custom template
        final modifiedContent = await indexFile.readAsString();
        expect(modifiedContent, contains('<div id="loading-container">'));
        expect(modifiedContent, contains('flutter-loader'));
        expect(modifiedContent, contains('Superdeck Example'));
      } finally {
        // Restore the working directory
        Directory.current = previousDir;
      }
    });
  });
}
