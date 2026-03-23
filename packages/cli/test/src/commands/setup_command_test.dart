import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/setup_command.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SetupCommand', () {
    late Directory tempDir;
    late Directory webDir;
    late SetupCommand command;
    late CommandRunner<int> runner;

    setUp(() async {
      // Create a temporary directory for testing
      tempDir = await createTempDirAsync();

      // Create a web directory within the temp dir
      webDir = createWebDirectory(tempDir);

      // Create a basic test runner
      command = SetupCommand();
      runner = createTestRunner(command);
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

        // Execute the command with the setup-web and force flags
        final result = await runner.run(['setup', '--setup-web', '--force']);

        // Verify the command executed successfully
        expect(result, equals(0));

        // Verify the backup file was created
        final backupFile = File(path.join(webDir.path, 'index.html.bak'));
        expect(await backupFile.exists(), isTrue);

        // Verify the index.html was replaced with our custom template
        final modifiedContent = await indexFile.readAsString();
        expect(modifiedContent, contains('<div class="loading-container">'));
        expect(modifiedContent, contains('Loading presentation...'));
        expect(modifiedContent, contains('flutter-view'));
      } finally {
        // Restore the working directory
        Directory.current = previousDir;
      }
    });

    test('fails fast when superdeck.yaml exists', () async {
      final previousDir = Directory.current;
      Directory.current = tempDir;

      try {
        final configFile = File(path.join(tempDir.path, 'superdeck.yaml'));
        await configFile.writeAsString('slidesPath: custom.md');

        final result = await runner.run(['setup', '--force']);

        expect(result, 65);
      } finally {
        Directory.current = previousDir;
      }
    });

    test('does not modify existing macOS entitlements files', () async {
      final previousDir = Directory.current;
      Directory.current = tempDir;

      try {
        createTestPubspec(tempDir);

        final runnerDir = Directory(path.join(tempDir.path, 'macos', 'Runner'));
        await runnerDir.create(recursive: true);

        const originalEntitlements = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.team-identifier</key>
  <string>TEAM123</string>
</dict>
</plist>
''';

        final releaseEntitlements = File(
          path.join(runnerDir.path, 'Release.entitlements'),
        );
        final debugEntitlements = File(
          path.join(runnerDir.path, 'DebugProfile.entitlements'),
        );

        await releaseEntitlements.writeAsString(originalEntitlements);
        await debugEntitlements.writeAsString(originalEntitlements);

        final result = await runner.run(['setup', '--force', '--no-setup-web']);

        expect(result, equals(0));
        expect(
          await releaseEntitlements.readAsString(),
          equals(originalEntitlements),
        );
        expect(
          await debugEntitlements.readAsString(),
          equals(originalEntitlements),
        );
      } finally {
        Directory.current = previousDir;
      }
    });
  });
}
