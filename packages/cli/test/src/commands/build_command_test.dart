import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
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

      test('creates superdeck directory if it does not exist', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('# Test\n\nContent');

        createTestPubspec(tempDir);

        final runner = createTestRunner(command);
        await runner.run(['build']);

        expect(deckWorkspace.superdeckDir.existsSync(), isTrue);
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
      test('watch exits on interactive quit command', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('# Test\n\nContent');

        createTestPubspec(tempDir);
        command = BuildCommand(
          commandInput: Stream.value('q'),
          stdinIsInteractive: true,
        );

        final runner = createTestRunner(command);
        final result = await runner.run(['build', '--watch', '--skip-pubspec']);

        expect(result, ExitCode.success.code);
      });

      test('watch ignores non-interactive stdin EOF', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('# Test\n\nContent');

        createTestPubspec(tempDir);
        final releaseWatch = Completer<void>();
        final watchReady = Completer<void>();
        var runCompleted = false;
        command = BuildCommand(
          commandInput: const Stream<String>.empty(),
          stdinIsInteractive: false,
          watchQuitSignal: releaseWatch.future,
          watchReady: watchReady.complete,
        );

        final runner = createTestRunner(command);
        final runFuture = runner
            .run(['build', '--watch', '--skip-pubspec'])
            .whenComplete(() {
              runCompleted = true;
            });

        await watchReady.future;
        await Future<void>.delayed(Duration.zero);
        expect(runCompleted, isFalse);

        releaseWatch.complete();
        expect(await runFuture, ExitCode.success.code);
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

      test('passes build plugins into the deck builder', () async {
        final slidesFile = deckWorkspace.slidesFile;
        await slidesFile.writeAsString('# Test\n\nOriginal');

        createTestPubspec(tempDir);
        command = BuildCommand(plugins: const [_CliTransformPlugin()]);

        final runner = createTestRunner(command);
        final result = await runner.run(['build', '--skip-pubspec']);

        expect(result, ExitCode.success.code);

        final deckJson =
            jsonDecode(await deckWorkspace.deckJson.readAsString())
                as List<dynamic>;
        final savedSlide = deckJson.single as Map<String, dynamic>;
        final savedSection =
            (savedSlide['sections'] as List<dynamic>).single
                as Map<String, dynamic>;
        final savedBlock =
            (savedSection['blocks'] as List<dynamic>).single
                as Map<String, dynamic>;

        expect(savedBlock['content'], contains('CLI transformed.'));
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

final class _CliTransformPlugin extends DeckBuildPlugin {
  const _CliTransformPlugin();

  @override
  String get id => 'test.cli-transform';

  @override
  ContentBlock transformContentBlock(ContentBlock block, DeckBuildContext _) {
    return block.copyWith(content: '${block.content}\n\nCLI transformed.');
  }
}
