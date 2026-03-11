import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/commands/publish/build_support.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

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
}
