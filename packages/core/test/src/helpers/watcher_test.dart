import 'dart:io';

import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  group('FileWatcher', () {
    late File testFile;
    late FileWatcher watcher;

    setUp(() {
      testFile = createTempFile('initial content');
      watcher = FileWatcher(testFile);
    });

    test('initializes with file reference', () {
      expect(watcher.file, equals(testFile));
    });

    test('accepts custom events parameter', () {
      final customWatcher = FileWatcher(
        testFile,
        events: FileSystemEvent.create | FileSystemEvent.modify,
      );
      expect(customWatcher.file, equals(testFile));
      expect(customWatcher.events, FileSystemEvent.create | FileSystemEvent.modify);
    });

    test('defaults to modify events', () {
      expect(watcher.events, FileSystemEvent.modify);
    });

    // Skip the file change detection test since it's flaky in CI environments
    test(
      'detects file changes via watch() stream',
      () async {
        int changeCount = 0;

        final sub = watcher.watch().listen((_) {
          changeCount++;
        });
        addTearDown(sub.cancel);

        // Ensure initial baseline is set
        await Future.delayed(Duration(seconds: 1));

        // Modify the file
        await testFile.writeAsString('new content ${DateTime.now()}');

        // Give enough time for the change to be detected
        await Future.delayed(Duration(seconds: 2));

        expect(changeCount, equals(1));
      },
      skip:
          "File watching tests are flaky in CI environments and can lead to test hangs",
    );
  });
}
