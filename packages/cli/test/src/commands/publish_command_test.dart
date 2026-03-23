import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/publish/build_support.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('resolveFlutterBinary', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await createTempDirAsync();
    });

    test('prefers repo-root .fvm flutter binary', () async {
      final flutterBinary = File(
        path.join(tempDir.path, '.fvm', 'flutter_sdk', 'bin', 'flutter'),
      );
      await flutterBinary.create(recursive: true);

      final resolved = resolveFlutterBinary(tempDir.path, isWindows: false);

      expect(resolved, flutterBinary.path);
    });

    test(
      'finds ancestor .fvm flutter binary from nested working directory',
      () async {
        final flutterBinary = File(
          path.join(tempDir.path, '.fvm', 'flutter_sdk', 'bin', 'flutter'),
        );
        await flutterBinary.create(recursive: true);

        final nestedDir = Directory(path.join(tempDir.path, 'example', 'app'));
        await nestedDir.create(recursive: true);

        final resolved = resolveFlutterBinary(nestedDir.path, isWindows: false);

        expect(resolved, flutterBinary.path);
      },
    );

    test('falls back to flutter when no local .fvm sdk exists', () {
      final resolved = resolveFlutterBinary(tempDir.path, isWindows: false);

      expect(resolved, 'flutter');
    });

    test('uses flutter.bat when resolving on Windows', () async {
      final flutterBinary = File(
        path.join(tempDir.path, '.fvm', 'flutter_sdk', 'bin', 'flutter.bat'),
      );
      await flutterBinary.create(recursive: true);

      final resolved = resolveFlutterBinary(tempDir.path, isWindows: true);

      expect(resolved, flutterBinary.path);
    });
  });

  group('temporary index.html handling', () {
    late Directory tempDir;
    late Directory webDir;
    late File indexFile;
    late File backupFile;
    late Logger logger;

    setUp(() async {
      tempDir = await createTempDirAsync();
      webDir = createWebDirectory(tempDir);
      indexFile = File(path.join(webDir.path, 'index.html'));
      backupFile = File(path.join(webDir.path, 'index.html.bak'));
      logger = Logger(level: Level.quiet);
    });

    test(
      'restores original index.html if setup fails after creating a backup',
      () async {
        const originalContent = '<html><body>Original</body></html>';
        await indexFile.writeAsString(originalContent);
        var sawBackupBeforeFailure = false;

        await expectLater(
          setupCustomIndexHtml(
            logger,
            repoDir: tempDir.path,
            exampleDir: '.',
            isDryRun: false,
            writeFile: (file, content) async {
              sawBackupBeforeFailure = backupFile.existsSync();
              throw StateError('write failed');
            },
          ),
          throwsStateError,
        );

        expect(sawBackupBeforeFailure, isTrue);
        expect(await indexFile.readAsString(), originalContent);
        expect(backupFile.existsSync(), isFalse);
      },
    );

    test(
      'restores original index.html when publication action fails',
      () async {
        const originalContent = '<html><body>Original</body></html>';
        await indexFile.writeAsString(originalContent);

        await expectLater(
          withTemporaryCustomIndexHtml<void>(
            logger,
            repoDir: tempDir.path,
            exampleDir: '.',
            isDryRun: false,
            action: () async {
              expect(
                await indexFile.readAsString(),
                contains('loading-container'),
              );
              expect(backupFile.existsSync(), isTrue);
              throw StateError('publish failed');
            },
          ),
          throwsStateError,
        );

        expect(await indexFile.readAsString(), originalContent);
        expect(backupFile.existsSync(), isFalse);
      },
    );
  });
}
