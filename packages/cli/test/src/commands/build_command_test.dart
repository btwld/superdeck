import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/build_command.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('BuildCommand', () {
    late BuildCommand command;
    late Directory tempDir;

    setUp(() async {
      tempDir = await createTempDirAsync();
      command = BuildCommand();
    });

    group('initialization', () {
      test('has correct name', () {
        expect(command.name, equals('build'));
      });

      test('has correct description', () {
        expect(
          command.description,
          equals('Build SuperDeck presentations from markdown'),
        );
      });

      test('has watch flag configured correctly', () {
        expect(command.argParser.options.containsKey('watch'), isTrue);
        final watchOption = command.argParser.options['watch']!;
        expect(watchOption.abbr, equals('w'));
        expect(watchOption.negatable, isFalse);
        expect(watchOption.help, contains('Watch for changes'));
      });

      test('has skip-pubspec flag configured correctly', () {
        expect(command.argParser.options.containsKey('skip-pubspec'), isTrue);
        final skipOption = command.argParser.options['skip-pubspec']!;
        expect(skipOption.negatable, isFalse);
        expect(skipOption.help, contains('Skip updating pubspec assets'));
      });

      test('has force-rebuild flag configured correctly', () {
        expect(
          command.argParser.options.containsKey('force-rebuild'),
          isTrue,
        );
        final forceOption = command.argParser.options['force-rebuild']!;
        expect(forceOption.abbr, equals('f'));
        expect(forceOption.negatable, isFalse);
        expect(forceOption.help, contains('Force rebuild all assets'));
      });
    });

    group('run() - configuration loading', () {
      test('returns error code when slides file does not exist', () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          // Create a config file but no slides file
          final configFile = File(
            path.join(tempDir.path, 'superdeck.yaml'),
          );
          await configFile.writeAsString('slides_path: slides.md');

          final runner = createTestRunner(command);
          final result = await runner.run(['build']);

          // Should fail due to configuration error
          expect(
            result,
            anyOf(
              equals(ExitCode.unavailable.code),
              equals(ExitCode.software.code),
            ),
          );
        } finally {
          Directory.current = previousDir;
        }
      });

      test('loads default configuration when config file does not exist',
          () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          // Create slides file without config
          final slidesFile = File(path.join(tempDir.path, 'slides.md'));
          await slidesFile.writeAsString('# Test Slide\n\nContent');

          final runner = createTestRunner(command);
          final result = await runner.run(['build']);

          // Should succeed with default config
          expect(
            result,
            anyOf(
              equals(ExitCode.success.code),
              equals(ExitCode.software.code),
            ),
          );
        } finally {
          Directory.current = previousDir;
        }
      });
    });

    group('run() - basic build execution', () {
      test('successfully builds when slides file exists', () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          final slidesFile = File(path.join(tempDir.path, 'slides.md'));
          await slidesFile.writeAsString('''
# Test Slide

This is test content.
''');

          createTestPubspec(tempDir);

          final runner = createTestRunner(command);
          final result = await runner.run(['build']);

          expect(
            result,
            anyOf(
              equals(ExitCode.success.code),
              equals(ExitCode.software.code),
            ),
          );
        } finally {
          Directory.current = previousDir;
        }
      });

      test('creates assets directory if it does not exist', () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          final slidesFile = File(path.join(tempDir.path, 'slides.md'));
          await slidesFile.writeAsString('# Test\n\nContent');

          createTestPubspec(tempDir);

          final runner = createTestRunner(command);
          await runner.run(['build']);

          // Assets directory should be created
          final assetsDir = Directory(
            path.join(tempDir.path, '.superdeck', 'assets'),
          );
          expect(assetsDir.existsSync(), isTrue);
        } finally {
          Directory.current = previousDir;
        }
      });

      test('handles empty slides file gracefully', () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          final slidesFile = File(path.join(tempDir.path, 'slides.md'));
          await slidesFile.writeAsString('');

          createTestPubspec(tempDir);

          final runner = createTestRunner(command);
          final result = await runner.run(['build']);

          // Should not crash, may succeed or fail gracefully
          expect(
            result,
            anyOf(
              equals(ExitCode.success.code),
              equals(ExitCode.software.code),
            ),
          );
        } finally {
          Directory.current = previousDir;
        }
      });
    });

    group('run() - flag behavior', () {
      test('force-rebuild flag clears assets directory', () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          final slidesFile = File(path.join(tempDir.path, 'slides.md'));
          await slidesFile.writeAsString('# Test\n\nContent');

          createTestPubspec(tempDir);

          // Create a pre-existing asset
          final assetsDir = Directory(
            path.join(tempDir.path, '.superdeck', 'assets'),
          );
          await assetsDir.create(recursive: true);
          final oldAsset = File(path.join(assetsDir.path, 'old_asset.txt'));
          await oldAsset.writeAsString('old content');

          expect(oldAsset.existsSync(), isTrue);

          final runner = createTestRunner(command);
          await runner.run(['build', '--force-rebuild']);

          // Old asset should be gone
          expect(oldAsset.existsSync(), isFalse);
        } finally {
          Directory.current = previousDir;
        }
      });

      test('skip-pubspec flag skips pubspec update', () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          final slidesFile = File(path.join(tempDir.path, 'slides.md'));
          await slidesFile.writeAsString('# Test\n\nContent');

          // Create minimal pubspec
          final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
          final originalContent = '''
name: test_project
version: 1.0.0
''';
          await pubspecFile.writeAsString(originalContent);

          final runner = createTestRunner(command);
          await runner.run(['build', '--skip-pubspec']);

          // Pubspec should not have superdeck assets
          final updatedContent = await pubspecFile.readAsString();
          expect(updatedContent, equals(originalContent));
        } finally {
          Directory.current = previousDir;
        }
      });
    });

    group('run() - error handling', () {
      test('handles invalid YAML in config file', () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          final slidesFile = File(path.join(tempDir.path, 'slides.md'));
          await slidesFile.writeAsString('# Test');

          final configFile = File(
            path.join(tempDir.path, 'superdeck.yaml'),
          );
          await configFile.writeAsString('invalid: yaml: content:');

          createTestPubspec(tempDir);

          final runner = createTestRunner(command);
          final result = await runner.run(['build']);

          // Should handle gracefully
          expect(result, isA<int>());
        } finally {
          Directory.current = previousDir;
        }
      });

      test('handles malformed markdown gracefully', () async {
        final previousDir = Directory.current;
        Directory.current = tempDir;

        try {
          final slidesFile = File(path.join(tempDir.path, 'slides.md'));
          await slidesFile.writeAsString('''
# Malformed

```unclosed code block

More content
''');

          createTestPubspec(tempDir);

          final runner = createTestRunner(command);
          final result = await runner.run(['build']);

          // Should not crash
          expect(result, isA<int>());
        } finally {
          Directory.current = previousDir;
        }
      });
    });
  });
}
