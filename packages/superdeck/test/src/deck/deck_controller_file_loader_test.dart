import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_loader.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck_core/superdeck_core.dart';

const _validDeckJson = '{"slides":[],"configuration":{}}';

String _buildStatusJson(String status, {required int seq}) {
  return '{"status":"$status","timestamp":"2026-03-10T10:00:0$seq.000Z"}';
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 3),
  Duration step = const Duration(milliseconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(step);
  }
}

void main() {
  group('DeckController with real FileDeckLoader', () {
    late Directory tempDir;
    late DeckConfiguration config;
    late FileDeckLoader loader;
    late DeckController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'superdeck_ctrl_file_test_',
      );
      config = DeckConfiguration(projectDir: tempDir.path);
      loader = FileDeckLoader(configuration: config);
      controller = DeckController(
        configuration: config,
        deckLoader: loader,
        options: const DeckOptions(),
      );

      addTearDown(() async {
        controller.dispose();
      });
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
    });

    test(
      'reloadDeck() succeeds after initial load with no .superdeck/',
      () async {
        // Controller starts with load(), which waits for .superdeck/ dir.
        // It should be in loading state.
        await _waitUntil(() => controller.isLoading.value);
        expect(controller.isLoading.value, isTrue);
        expect(controller.hasError.value, isFalse);

        // Reload while still waiting — this replaces the active cycle.
        await controller.reloadDeck();

        // Now create the output directory and files.
        await config.superdeckDir.create(recursive: true);
        await config.deckJson.writeAsString(_validDeckJson);
        await config.buildStatusJson.writeAsString(
          _buildStatusJson('success', seq: 1),
        );

        // Controller should reach a loaded, non-error state.
        await _waitUntil(() => !controller.isLoading.value);

        expect(controller.isLoading.value, isFalse);
        expect(controller.hasError.value, isFalse);
        expect(controller.error.value, isNull);
      },
    );

    test('reloadDeck() does not surface a fatal loader-stream error', () async {
      // Create files for an initial successful load.
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validDeckJson);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 0),
      );

      await _waitUntil(() => !controller.isLoading.value);
      expect(controller.hasError.value, isFalse);

      // Reload.
      await controller.reloadDeck();

      // Write a new success status.
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 2),
      );

      await _waitUntil(() => !controller.isLoading.value);

      expect(controller.isLoading.value, isFalse);
      expect(controller.hasError.value, isFalse);
      expect(controller.error.value, isNull);
    });
  });
}
