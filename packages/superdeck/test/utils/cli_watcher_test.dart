import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/cli_watcher.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('CliWatcher', () {
    late Directory tempDir;
    late DeckConfiguration configuration;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cli_watcher_test_');
      configuration = DeckConfiguration(projectDir: tempDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initial status is idle', () {
      final watcher = CliWatcher(configuration: configuration);

      expect(watcher.status, CliWatcherStatus.idle);
      expect(watcher.lastError, isNull);
      expect(watcher.lastBuildStatus, 'unknown');

      watcher.dispose();
    });

    test('start initialises file watcher and emits status', () async {
      final watcher = CliWatcher(configuration: configuration);
      await watcher.start();

      expect(watcher.status, CliWatcherStatus.running);
      expect(watcher.lastBuildStatus, isNotEmpty);

      watcher.dispose();
    });

    test('updates when build_status.json changes', () async {
      final watcher = CliWatcher(configuration: configuration);
      await watcher.start();

      final statusFile = configuration.buildStatusJson;
      await statusFile.ensureWrite('''
{
  "status": "building",
  "timestamp": "${DateTime.now().toUtc().toIso8601String()}",
  "slideCount": 1
}
''');

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await watcher.refresh();
      expect(watcher.lastBuildStatus, 'building');
      expect(watcher.isBuilding, isTrue);

      await statusFile.ensureWrite('''
{
  "status": "success",
  "timestamp": "${DateTime.now().add(const Duration(seconds: 1)).toUtc().toIso8601String()}",
  "slideCount": 2
}
''');

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await watcher.refresh();
      expect(watcher.lastBuildStatus, 'success');
      expect(watcher.isBuilding, isFalse);
      expect(watcher.currentStatus?.slideCount, 2);
      expect(watcher.currentStatus?.type, BuildStatusType.success);
      expect(watcher.previousStatus?.type, BuildStatusType.building);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      watcher.dispose();
    });

    test('dispose stops watcher safely', () async {
      final watcher = CliWatcher(configuration: configuration);
      await watcher.start();
      watcher.dispose();

      expect(watcher.status, CliWatcherStatus.stopped);
    });
  });
}
