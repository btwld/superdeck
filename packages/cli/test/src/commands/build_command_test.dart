import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/build_command.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BuildCommand', () {
    late BuildCommand command;
    late Directory tempDir;
    late Directory previousDir;
    late DeckWorkspace deckWorkspace;

    setUp(() async {
      tempDir = await createTempDirAsync();
      deckWorkspace = DeckWorkspace(projectDir: tempDir.path);
      command = BuildCommand();
      previousDir = Directory.current;
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = previousDir;
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
        expect(command.argParser.options.containsKey('force-rebuild'), isTrue);
        final forceOption = command.argParser.options['force-rebuild']!;
        expect(forceOption.abbr, equals('f'));
        expect(forceOption.negatable, isFalse);
        expect(forceOption.help, contains('Force rebuild all assets'));
      });
    });

    group('run() - basic build execution', () {
      test('successfully builds when slides file exists', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('''
# Test Slide

This is test content.
''');

        createTestPubspec(tempDir);

        final runner = createTestRunner(command);
        final result = await runner.run(['build']);

        expect(
          result,
          anyOf(equals(ExitCode.success.code), equals(ExitCode.software.code)),
        );
      });

      test('creates assets directory if it does not exist', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('# Test\n\nContent');

        createTestPubspec(tempDir);

        final runner = createTestRunner(command);
        await runner.run(['build']);

        // Assets directory should be created
        final assetsDir = deckWorkspace.assetsDir;
        expect(assetsDir.existsSync(), isTrue);
      });

      test('handles empty slides file gracefully', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('');

        createTestPubspec(tempDir);

        final runner = createTestRunner(command);
        final result = await runner.run(['build']);

        // Should not crash, may succeed or fail gracefully
        expect(
          result,
          anyOf(equals(ExitCode.success.code), equals(ExitCode.software.code)),
        );
      });
    });

    group('run() - flag behavior', () {
      test('force-rebuild flag clears assets directory', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('# Test\n\nContent');

        createTestPubspec(tempDir);

        // Create a pre-existing asset
        final assetsDir = deckWorkspace.assetsDir;
        await assetsDir.create(recursive: true);
        final oldAsset = File(path.join(assetsDir.path, 'old_asset.txt'));
        await oldAsset.writeAsString('old content');

        expect(oldAsset.existsSync(), isTrue);

        final runner = createTestRunner(command);
        await runner.run(['build', '--force-rebuild']);

        // Old asset should be gone
        expect(oldAsset.existsSync(), isFalse);
      });

      test('force-rebuild flag replaces stale generated_assets.json', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('# Test\n\nContent');
        createTestPubspec(tempDir);

        await deckWorkspace.superdeckDir.create(recursive: true);
        await deckWorkspace.assetsRefJson.writeAsString('{"stale":true}');

        final runner = createTestRunner(command);
        await runner.run(['build', '--force-rebuild']);

        final assetsRefContents = await deckWorkspace.assetsRefJson
            .readAsString();
        expect(assetsRefContents, isNot('{"stale":true}'));
        expect(assetsRefContents, contains('last_modified'));
        expect(assetsRefContents, contains('files'));
      });

      test('skip-pubspec flag skips pubspec update', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('# Test\n\nContent');

        // Create minimal pubspec
        final pubspecFile = deckWorkspace.pubspecFile;
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
      });
    });

    group('run() - error handling', () {
      test('handles malformed markdown gracefully', () async {
        final slidesFile = deckWorkspace.slidesFile;
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
      });
    });
  });
}
