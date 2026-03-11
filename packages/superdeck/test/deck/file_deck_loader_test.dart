import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_loader.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  Future<void> waitUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 1),
    Duration step = const Duration(milliseconds: 20),
  }) async {
    final startedAt = DateTime.now();
    while (DateTime.now().difference(startedAt) < timeout) {
      if (condition()) return;
      await Future<void>.delayed(step);
    }
  }

  group('FileDeckLoader status-only stream API', () {
    late Directory tempDir;
    late DeckConfiguration config;
    late FileDeckLoader deckLoader;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('superdeck_loader_test_');
      config = DeckConfiguration(projectDir: tempDir.path);
      deckLoader = FileDeckLoader(configuration: config);

      addTearDown(() async {
        await deckLoader.dispose();
      });
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
    });

    test('emits DeckLoadingEvent first', () async {
      final events = <DeckEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(events, hasLength(1));
      expect(events.first, isA<DeckLoadingEvent>());
    });

    test('does not load deck at startup without success status', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString('{"slides":[],"configuration":{}}');

      final events = <DeckEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(events.first, isA<DeckLoadingEvent>());
      expect(events.whereType<DeckLoadedEvent>(), isEmpty);
    });

    test('processes existing startup success status', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString('{"slides":[],"configuration":{}}');
      await config.buildStatusJson.writeAsString(
        '{"status":"success","timestamp":"2026-03-10T10:00:00.000Z"}',
      );

      final events = <DeckEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(events.first, isA<DeckLoadingEvent>());
      expect(events.whereType<DeckLoadedEvent>(), hasLength(1));
    });

    test('processes existing startup building status', () async {
      await config.superdeckDir.create(recursive: true);
      await config.buildStatusJson.writeAsString(
        '{"status":"building","timestamp":"2026-03-10T10:00:00.000Z"}',
      );

      final events = <DeckEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(events.whereType<DeckRebuildingEvent>(), isNotEmpty);
      expect(events.whereType<DeckLoadedEvent>(), isEmpty);
    });

    test('does not dedupe updates that share the same timestamp', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString('{"slides":[],"configuration":{}}');

      final events = <DeckEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await config.buildStatusJson.writeAsString(
        '{"status":"building","timestamp":"2026-03-10T12:00:00.000Z"}',
      );
      await waitUntil(() => events.whereType<DeckRebuildingEvent>().isNotEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 180));
      await config.buildStatusJson.writeAsString(
        '{"status":"failure","timestamp":"2026-03-10T12:00:00.000Z",'
        '"error":{"type":"BuildFailure","message":"same timestamp failure"}}',
      );

      await waitUntil(
        () => events.whereType<DeckErrorEvent>().any(
          (event) => event.message == 'same timestamp failure',
        ),
      );

      final rebuildEvents = events.whereType<DeckRebuildingEvent>().toList();
      final failureEvents = events
          .whereType<DeckErrorEvent>()
          .where((event) => event.message == 'same timestamp failure')
          .toList();

      expect(rebuildEvents, isNotEmpty);
      expect(failureEvents, isNotEmpty);
    });

    test('invalid status json emits DeckErrorEvent with Exception', () async {
      await config.superdeckDir.create(recursive: true);

      final events = <DeckEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await config.buildStatusJson.writeAsString('{"status":');

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final errorEvents = events.whereType<DeckErrorEvent>().toList();
      expect(errorEvents, isNotEmpty);
      expect(errorEvents.last.message, 'Build status error');
      expect(errorEvents.last.error, isA<Exception>());
    });

    test('failure status emits DeckErrorEvent with Exception', () async {
      await config.superdeckDir.create(recursive: true);

      final events = <DeckEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await config.buildStatusJson.writeAsString(
        '{"status":"failure","timestamp":"2026-03-10T10:00:01.000Z",'
        '"error":{"type":"BuildFailure","message":"Syntax error"}}',
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final syntaxErrors = events
          .whereType<DeckErrorEvent>()
          .where((event) => event.message == 'Syntax error')
          .toList();

      expect(syntaxErrors, isNotEmpty);
      expect(syntaxErrors.last.error, isA<Exception>());
      expect(syntaxErrors.last.error, isNot(isA<DeckBuildError>()));
    });

    test('success status invalid deck emits error and then recovers', () async {
      await config.superdeckDir.create(recursive: true);

      final events = <DeckEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await config.deckJson.writeAsString('[]');
      await config.buildStatusJson.writeAsString(
        '{"status":"success","timestamp":"2026-03-10T10:00:01.000Z"}',
      );

      await Future<void>.delayed(const Duration(milliseconds: 180));

      await config.deckJson.writeAsString('{"slides":[],"configuration":{}}');
      await config.buildStatusJson.writeAsString(
        '{"status":"success","timestamp":"2026-03-10T10:00:02.000Z"}',
      );

      await Future<void>.delayed(const Duration(milliseconds: 220));

      final referenceErrors = events
          .whereType<DeckErrorEvent>()
          .where((event) => event.message == 'Superdeck reference error')
          .toList();
      final loaded = events.whereType<DeckLoadedEvent>().toList();

      expect(referenceErrors, isNotEmpty);
      expect(referenceErrors.last.error, isA<Exception>());
      expect(loaded, hasLength(1));
    });

    test('dispose stops watching and closes the stream', () async {
      final events = <DeckEvent>[];
      final streamDone = Completer<void>();
      final subscription = deckLoader.load().listen(
        events.add,
        onDone: () {
          if (!streamDone.isCompleted) {
            streamDone.complete();
          }
        },
      );
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      final eventCountAtDispose = events.length;

      await deckLoader.dispose();
      await streamDone.future.timeout(const Duration(seconds: 1));

      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString('{"slides":[],"configuration":{}}');
      await config.buildStatusJson.writeAsString(
        '{"status":"success","timestamp":"2026-03-10T11:30:00.000Z"}',
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(events, hasLength(eventCountAtDispose));
    });
  });
}
