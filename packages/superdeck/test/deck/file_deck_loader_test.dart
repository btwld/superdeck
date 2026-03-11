import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_loader.dart';
import 'package:superdeck_core/superdeck_core.dart';

const _validDeckJson = '{"slides":[],"configuration":{}}';

String _buildStatusJson(
  String status, {
  required int seq,
  String? errorMessage,
}) {
  final ts = '2026-03-10T10:00:0$seq.000Z';
  final buf = StringBuffer('{"status":"$status","timestamp":"$ts"');
  if (errorMessage != null) {
    buf.write(',"error":{"type":"BuildFailure","message":"$errorMessage"}');
  }
  buf.write('}');
  return buf.toString();
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(step);
  }
}

Future<void> _waitForEvent<T extends DeckEvent>(
  List<DeckEvent> events, {
  bool Function(T)? where,
  Duration timeout = const Duration(seconds: 2),
}) {
  return _waitUntil(
    () => events.whereType<T>().any(where ?? (_) => true),
    timeout: timeout,
  );
}

void main() {
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
      await _waitForEvent<DeckRebuildingEvent>(events);

      await Future<void>.delayed(const Duration(milliseconds: 180));
      await config.buildStatusJson.writeAsString(
        '{"status":"failure","timestamp":"2026-03-10T12:00:00.000Z",'
        '"error":{"type":"BuildFailure","message":"same timestamp failure"}}',
      );

      await _waitForEvent<DeckErrorEvent>(
        events,
        where: (e) => e.message == 'same timestamp failure',
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

  group('FileDeckLoader reload cycle', () {
    late Directory tempDir;
    late DeckConfiguration config;
    late FileDeckLoader deckLoader;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('superdeck_reload_test_');
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

    test(
      'reload when .superdeck/ does not exist yet: '
      'second load() picks up files created after first was canceled',
      () async {
        // First cycle — no .superdeck/ dir, so it just emits loading.
        final events1 = <DeckEvent>[];
        final sub1 = deckLoader.load().listen(events1.add);

        await _waitForEvent<DeckLoadingEvent>(events1);
        expect(events1, hasLength(1));

        // Cancel first subscription before starting second cycle.
        await sub1.cancel();

        // Second cycle — still no .superdeck/ dir initially.
        final events2 = <DeckEvent>[];
        final sub2 = deckLoader.load().listen(events2.add);
        addTearDown(sub2.cancel);

        await _waitForEvent<DeckLoadingEvent>(events2);

        // Now create the output files — only the second cycle should see them.
        await config.superdeckDir.create(recursive: true);
        await config.deckJson.writeAsString(_validDeckJson);
        await config.buildStatusJson.writeAsString(
          _buildStatusJson('success', seq: 1),
        );

        await _waitForEvent<DeckLoadedEvent>(events2);
        expect(events2.whereType<DeckLoadedEvent>(), hasLength(1));

        // The first cycle's events should NOT have received anything extra.
        expect(events1.whereType<DeckLoadedEvent>(), isEmpty);
      },
    );

    test('reload after prior successful load: '
        'second load() starts cleanly and processes new status', () async {
      // Set up files for a successful first load.
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validDeckJson);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 0),
      );

      final events1 = <DeckEvent>[];
      final sub1 = deckLoader.load().listen(events1.add);

      await _waitForEvent<DeckLoadedEvent>(events1);
      expect(events1.whereType<DeckLoadedEvent>(), hasLength(1));

      await sub1.cancel();

      // Second cycle.
      final events2 = <DeckEvent>[];
      final sub2 = deckLoader.load().listen(events2.add);
      addTearDown(sub2.cancel);

      await _waitForEvent<DeckLoadingEvent>(events2);

      // Write a new status update to trigger a reload in the second cycle.
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 2),
      );

      await _waitForEvent<DeckLoadedEvent>(events2);
      expect(events2.whereType<DeckLoadedEvent>(), isNotEmpty);
    });

    test('dispose after reload: stops watching, no late events', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validDeckJson);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 0),
      );

      // First cycle — loads successfully.
      final events1 = <DeckEvent>[];
      final sub1 = deckLoader.load().listen(events1.add);
      await _waitForEvent<DeckLoadedEvent>(events1);
      await sub1.cancel();

      // Second cycle.
      final events2 = <DeckEvent>[];
      final streamDone = Completer<void>();
      final sub2 = deckLoader.load().listen(
        events2.add,
        onDone: () {
          if (!streamDone.isCompleted) streamDone.complete();
        },
      );
      addTearDown(sub2.cancel);

      await _waitForEvent<DeckLoadingEvent>(events2);

      // Dispose while second cycle is active.
      await deckLoader.dispose();
      await streamDone.future.timeout(const Duration(seconds: 2));

      final snapshot = events2.length;

      // Write new status — should NOT produce any more events.
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 3),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(events2, hasLength(snapshot));
    });

    test('event ordering: loading before loaded', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validDeckJson);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 0),
      );

      final events = <DeckEvent>[];
      final sub = deckLoader.load().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvent<DeckLoadedEvent>(events);

      final loadingIdx = events.indexWhere((e) => e is DeckLoadingEvent);
      final loadedIdx = events.indexWhere((e) => e is DeckLoadedEvent);
      expect(loadingIdx, lessThan(loadedIdx));
    });

    test('event ordering: loading before rebuilding', () async {
      await config.superdeckDir.create(recursive: true);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('building', seq: 0),
      );

      final events = <DeckEvent>[];
      final sub = deckLoader.load().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvent<DeckRebuildingEvent>(events);

      final loadingIdx = events.indexWhere((e) => e is DeckLoadingEvent);
      final rebuildIdx = events.indexWhere((e) => e is DeckRebuildingEvent);
      expect(loadingIdx, lessThan(rebuildIdx));
    });

    test('event ordering: loading before error', () async {
      await config.superdeckDir.create(recursive: true);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('failure', seq: 0, errorMessage: 'bad'),
      );

      final events = <DeckEvent>[];
      final sub = deckLoader.load().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvent<DeckErrorEvent>(events);

      final loadingIdx = events.indexWhere((e) => e is DeckLoadingEvent);
      final errorIdx = events.indexWhere((e) => e is DeckErrorEvent);
      expect(loadingIdx, lessThan(errorIdx));
    });
  });
}
