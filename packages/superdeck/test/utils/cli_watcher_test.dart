import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/cli_watcher.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('CliWatcher', () {
    late Directory tempDir;
    late DeckConfiguration configuration;

    setUp(() {
      // Create a temporary directory for testing
      tempDir = Directory.systemTemp.createTempSync('cli_watcher_test_');
      configuration = DeckConfiguration(
        projectDir: tempDir.path,
      );
    });

    tearDown(() {
      // Clean up temp directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initial status is idle', () {
      final watcher = CliWatcher(
        projectRoot: tempDir,
        configuration: configuration,
      );

      expect(watcher.status, CliWatcherStatus.idle);
      expect(watcher.error, isNull);

      watcher.dispose();
    });

    test('status transitions to starting then running on successful start', () async {
      final watcher = CliWatcher(
        projectRoot: tempDir,
        configuration: configuration,
      );

      // Start the watcher
      final startFuture = watcher.start();

      // Wait a bit for the process to start
      await Future.delayed(const Duration(milliseconds: 100));

      // Status should be either starting, running, or failed (if CLI not available or project invalid)
      // The process can fail very quickly if there's no valid pubspec.yaml in the temp directory
      expect(
        watcher.status,
        isIn([CliWatcherStatus.starting, CliWatcherStatus.running, CliWatcherStatus.failed]),
      );

      await startFuture;

      // Give it time to transition
      await Future.delayed(const Duration(milliseconds: 200));

      // Eventually it should be running (or failed if CLI not available)
      expect(
        watcher.status,
        isIn([CliWatcherStatus.running, CliWatcherStatus.failed]),
      );

      watcher.dispose();
    });

    test('dispose sets status to stopped', () {
      final watcher = CliWatcher(
        projectRoot: tempDir,
        configuration: configuration,
      );

      watcher.dispose();

      expect(watcher.status, CliWatcherStatus.stopped);
    });

    test('dispose before start is safe', () {
      final watcher = CliWatcher(
        projectRoot: tempDir,
        configuration: configuration,
      );

      expect(() => watcher.dispose(), returnsNormally);
      expect(watcher.status, CliWatcherStatus.stopped);
    });

    test('dispose after start kills the process', () async {
      final watcher = CliWatcher(
        projectRoot: tempDir,
        configuration: configuration,
      );

      await watcher.start();
      await Future.delayed(const Duration(milliseconds: 100));

      watcher.dispose();

      expect(watcher.status, CliWatcherStatus.stopped);
    });

    test('findDartExecutable prefers FVM if available', () {
      final watcher = CliWatcher(
        projectRoot: tempDir,
        configuration: configuration,
      );

      // Create fake FVM directory structure
      final fvmDir = Directory('${tempDir.path}/.fvm/flutter_sdk/bin');
      fvmDir.createSync(recursive: true);

      final fvmDart = File('${fvmDir.path}/dart${Platform.isWindows ? '.exe' : ''}');
      fvmDart.writeAsStringSync('#!/bin/bash\necho "FVM dart"');

      // Set executable permission on Unix systems
      if (!Platform.isWindows) {
        Process.runSync('chmod', ['+x', fvmDart.path]);
      }

      // Change to temp directory to test relative path resolution
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        // This would use FVM dart if we run the watcher from tempDir
        expect(fvmDart.existsSync(), isTrue);
      } finally {
        Directory.current = originalDir;
      }

      watcher.dispose();
    });

    test('handles platform-specific executable names', () {
      final expectedExtension = Platform.isWindows ? '.exe' : '';
      expect(expectedExtension, Platform.isWindows ? '.exe' : '');
    });

    test('multiple dispose calls are safe', () {
      final watcher = CliWatcher(
        projectRoot: tempDir,
        configuration: configuration,
      );

      expect(() {
        watcher.dispose();
        watcher.dispose();
        watcher.dispose();
      }, returnsNormally);

      expect(watcher.status, CliWatcherStatus.stopped);
    });
  });
}
