import 'dart:async';
import 'dart:io';

import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/testing_utils.dart';

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
      expect(
        customWatcher.events,
        FileSystemEvent.create | FileSystemEvent.modify,
      );
    });

    test('defaults to modify events', () {
      expect(watcher.events, FileSystemEvent.modify);
    });

    test('detects file changes via watch() stream', () async {
      final events = StreamIterator(watcher.watch());
      addTearDown(events.cancel);
      final nextEvent = events.moveNext();

      await testFile.writeAsString('new content ${DateTime.now()}');

      expect(await nextEvent.timeout(const Duration(seconds: 2)), isTrue);
    });
  });
}
