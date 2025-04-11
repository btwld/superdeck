// A simplified test for the setup command's web setup functionality
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/setup_command.dart';
import 'package:test/test.dart';

void main() {
  test('SetupCommand sets up custom index.html correctly', () async {
    // Create a temporary test directory
    final tempDir = await Directory.systemTemp.createTemp('setup_test');
    final webDir = Directory(path.join(tempDir.path, 'web'));
    await webDir.create();

    // Create a test HTML file
    final indexFile = File(path.join(webDir.path, 'index.html'));
    await indexFile.writeAsString('<html><body>Original Content</body></html>');

    try {
      // Create a command runner with our setup command
      final runner = CommandRunner<int>('test', 'Test runner');
      runner.addCommand(SetupCommand());

      // Save current directory
      final previousDir = Directory.current;

      // Change to temp dir for test
      Directory.current = tempDir;

      try {
        // Run the command
        await runner.run(['setup', '--setup-web']);

        // Verify backup was created
        final backupFile = File(path.join(webDir.path, 'index.html.bak'));
        expect(await backupFile.exists(), isTrue);

        // Verify content was changed
        final content = await indexFile.readAsString();
        expect(content, contains('<div id="loading-container">'));
        expect(content, contains('flutter-loader'));
        expect(content, contains('Superdeck Example'));
      } finally {
        // Restore directory
        Directory.current = previousDir;
      }
    } finally {
      // Clean up test directory
      await tempDir.delete(recursive: true);
    }
  });
}
