import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/deck_watcher.dart';
import 'package:superdeck_core/superdeck_core.dart';

Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed >= timeout) {
      throw TimeoutException(
        'Condition was not met within ${timeout.inMilliseconds}ms',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void main() {
  group('DeckWatcher', () {
    late Directory tempDir;
    late DeckConfiguration configuration;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('deck_watcher_test_');
      configuration = DeckConfiguration(projectDir: tempDir.path);

      final slidesFile = File('${tempDir.path}/slides.md');
      await slidesFile.writeAsString('# Title\n\nHello world\n');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('initial status is idle', () {
      final watcher = DeckWatcher(configuration: configuration);

      expect(watcher.status.value, DeckWatcherStatus.idle);
      expect(watcher.error.value, isNull);

      watcher.dispose();
    });

    test('start transitions watcher to running state', () async {
      final watcher = DeckWatcher(configuration: configuration);
      await watcher.start();

      await _waitFor(
        () =>
            watcher.status.value == DeckWatcherStatus.running ||
            watcher.status.value == DeckWatcherStatus.failed,
      );

      expect(
        watcher.status.value,
        isIn([DeckWatcherStatus.running, DeckWatcherStatus.failed]),
      );
      expect(
        watcher.lastBuildStatus.value,
        isIn(['building', 'success', 'failure']),
      );

      watcher.dispose();
    });

    test('updates build payload after file changes', () async {
      final watcher = DeckWatcher(configuration: configuration);
      await watcher.start();

      await _waitFor(
        () =>
            watcher.lastBuildStatusPayload != null &&
            watcher.lastBuildStatusPayload!['status'] != 'building',
      );

      final initialPayload = watcher.lastBuildStatusPayload;
      final initialTimestamp = initialPayload?['timestamp'] as String?;

      final slidesFile = File('${tempDir.path}/slides.md');
      await slidesFile.writeAsString('# Updated\n\nSecond build\n');

      await _waitFor(() {
        final payload = watcher.lastBuildStatusPayload;
        if (payload == null) return false;
        final status = payload['status'] as String?;
        final timestamp = payload['timestamp'] as String?;
        if (status == 'building') return false;
        if (timestamp == null) return false;
        return initialTimestamp == null || timestamp != initialTimestamp;
      });

      expect(watcher.lastBuildStatus.value, isIn(['success', 'failure']));

      watcher.dispose();
    });

    test('dispose is idempotent', () {
      final watcher = DeckWatcher(configuration: configuration);

      expect(() {
        watcher.dispose();
        watcher.dispose();
      }, returnsNormally);
    });
  });
}
