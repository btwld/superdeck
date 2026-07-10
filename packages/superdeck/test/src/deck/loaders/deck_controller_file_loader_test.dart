import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

const _validSlidesJson = '[]';

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
    late DeckWorkspace config;
    late FileDeckLoader loader;
    late DeckController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'superdeck_ctrl_file_test_',
      );
      config = DeckWorkspace(projectDir: tempDir.path);
      loader = FileDeckLoader(workspace: config);
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
    });

    DeckController createController() {
      controller = DeckController(deckLoader: loader, options: DeckOptions());
      addTearDown(controller.dispose);
      return controller;
    }

    test(
      'surfaces missing build output at startup and clears on reload',
      () async {
        createController();

        await _waitUntil(() => controller.session.hasFatalError.value);
        expect(controller.session.isLoading.value, isFalse);
        expect(controller.session.hasFatalError.value, isTrue);
        expect(
          controller.session.error.value,
          contains('No SuperDeck build output found'),
        );

        await controller.reloadDeck();

        await config.superdeckDir.create(recursive: true);
        await config.deckJson.writeAsString(_validSlidesJson);
        await config.buildStatusJson.writeAsString(
          _buildStatusJson('success', seq: 1),
        );

        await _waitUntil(
          () =>
              !controller.session.isLoading.value &&
              !controller.session.hasFatalError.value,
        );

        expect(controller.session.isLoading.value, isFalse);
        expect(controller.session.hasFatalError.value, isFalse);
        expect(controller.session.error.value, isNull);
      },
    );

    test(
      'clears startup error automatically when build output appears',
      () async {
        createController();

        await _waitUntil(() => controller.session.hasFatalError.value);
        expect(
          controller.session.error.value,
          contains('No SuperDeck build output found'),
        );

        await config.superdeckDir.create(recursive: true);
        await config.deckJson.writeAsString(_validSlidesJson);
        await config.buildStatusJson.writeAsString(
          _buildStatusJson('success', seq: 2),
        );

        await _waitUntil(
          () =>
              !controller.session.isLoading.value &&
              !controller.session.hasFatalError.value,
        );

        expect(controller.session.isLoading.value, isFalse);
        expect(controller.session.hasFatalError.value, isFalse);
        expect(controller.session.error.value, isNull);
      },
    );

    test('reloadDeck() stays healthy after a prior successful load', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validSlidesJson);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 0),
      );

      createController();

      await _waitUntil(() => !controller.session.isLoading.value);
      expect(controller.session.hasFatalError.value, isFalse);

      await controller.reloadDeck();
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 3),
      );

      await _waitUntil(() => !controller.session.isLoading.value);

      expect(controller.session.isLoading.value, isFalse);
      expect(controller.session.hasFatalError.value, isFalse);
      expect(controller.session.error.value, isNull);
    });

    test('exits loading when build status payload is not a map', () async {
      await config.superdeckDir.create(recursive: true);
      await config.buildStatusJson.writeAsString('[]');

      createController();

      await _waitUntil(
        () =>
            !controller.session.isLoading.value &&
            controller.session.hasFatalError.value,
      );

      expect(controller.session.isLoading.value, isFalse);
      expect(controller.session.hasFatalError.value, isTrue);
      expect(
        controller.session.error.value,
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Expected JSON object'),
        ),
      );
    });
  });
}
