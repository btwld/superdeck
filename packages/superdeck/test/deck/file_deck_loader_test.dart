import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_loader.dart';
import 'package:superdeck_core/superdeck_core.dart';

const _validSlidesJson = '[]';
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

Future<void> _waitForEvent<T extends SlidesEvent>(
  List<SlidesEvent> events, {
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

    test('emits SlidesLoadingEvent first', () async {
      final events = <SlidesEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(events, hasLength(1));
      expect(events.first, isA<SlidesLoadingEvent>());
    });

    test('does not load slides at startup without success status', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validSlidesJson);

      final events = <SlidesEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(events.first, isA<SlidesLoadingEvent>());
      expect(events.whereType<SlidesLoadedEvent>(), isEmpty);
    });

    test('processes existing startup success status', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validSlidesJson);
      await config.buildStatusJson.writeAsString(
        '{"status":"success","timestamp":"2026-03-10T10:00:00.000Z"}',
      );

      final events = <SlidesEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(events.first, isA<SlidesLoadingEvent>());
      expect(events.whereType<SlidesLoadedEvent>(), hasLength(1));
      expect(events.whereType<SlidesLoadedEvent>().single.slides, isEmpty);
    });

    test('processes existing startup building status', () async {
      await config.superdeckDir.create(recursive: true);
      await config.buildStatusJson.writeAsString(
        '{"status":"building","timestamp":"2026-03-10T10:00:00.000Z"}',
      );

      final events = <SlidesEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(events.whereType<SlidesRebuildingEvent>(), isNotEmpty);
      expect(events.whereType<SlidesLoadedEvent>(), isEmpty);
    });

    test('does not dedupe updates that share the same timestamp', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validSlidesJson);

      final events = <SlidesEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await config.buildStatusJson.writeAsString(
        '{"status":"building","timestamp":"2026-03-10T12:00:00.000Z"}',
      );
      await _waitForEvent<SlidesRebuildingEvent>(events);

      await Future<void>.delayed(const Duration(milliseconds: 180));
      await config.buildStatusJson.writeAsString(
        '{"status":"failure","timestamp":"2026-03-10T12:00:00.000Z",'
        '"error":{"type":"BuildFailure","message":"same timestamp failure"}}',
      );

      await _waitForEvent<SlidesErrorEvent>(
        events,
        where: (e) => e.message == 'same timestamp failure',
      );

      final rebuildEvents = events.whereType<SlidesRebuildingEvent>().toList();
      final failureEvents = events
          .whereType<SlidesErrorEvent>()
          .where((event) => event.message == 'same timestamp failure')
          .toList();

      expect(rebuildEvents, isNotEmpty);
      expect(failureEvents, isNotEmpty);
    });

    test('invalid status json emits SlidesErrorEvent with Exception', () async {
      await config.superdeckDir.create(recursive: true);

      final events = <SlidesEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await config.buildStatusJson.writeAsString('{"status":');

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final errorEvents = events.whereType<SlidesErrorEvent>().toList();
      expect(errorEvents, isNotEmpty);
      expect(errorEvents.last.message, 'Build status error');
      expect(errorEvents.last.error, isA<Exception>());
    });

    test('failure status emits SlidesErrorEvent with DeckBuildError', () async {
      await config.superdeckDir.create(recursive: true);

      final events = <SlidesEvent>[];
      final subscription = deckLoader.load().listen(events.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await config.buildStatusJson.writeAsString(
        '{"status":"failure","timestamp":"2026-03-10T10:00:01.000Z",'
        '"error":{"type":"BuildFailure","message":"Syntax error"}}',
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final syntaxErrors = events
          .whereType<SlidesErrorEvent>()
          .where((event) => event.message == 'Syntax error')
          .toList();

      expect(syntaxErrors, isNotEmpty);
      expect(syntaxErrors.last.error, isA<DeckBuildError>());
    });

    test('dispose stops watching and closes the stream', () async {
      final events = <SlidesEvent>[];
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
      await config.deckJson.writeAsString(_validSlidesJson);
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
      'reload() picks up files created after the previous cycle is canceled',
      () async {
        final events = <SlidesEvent>[];
        final sub = deckLoader.load().listen(events.add);
        addTearDown(sub.cancel);

        await _waitForEvent<SlidesLoadingEvent>(events);
        expect(events.whereType<SlidesLoadingEvent>(), hasLength(1));

        await deckLoader.reload();

        await _waitUntil(
          () => events.whereType<SlidesLoadingEvent>().length == 2,
        );

        await config.superdeckDir.create(recursive: true);
        await config.deckJson.writeAsString(_validSlidesJson);
        await config.buildStatusJson.writeAsString(
          _buildStatusJson('success', seq: 1),
        );

        await _waitForEvent<SlidesLoadedEvent>(events);
        expect(events.whereType<SlidesLoadedEvent>(), hasLength(1));
      },
    );

    test('reload after prior successful load: '
        'reload() starts cleanly and processes new status', () async {
      // Set up files for a successful first load.
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validSlidesJson);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 0),
      );

      final events = <SlidesEvent>[];
      final sub = deckLoader.load().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvent<SlidesLoadedEvent>(events);
      expect(events.whereType<SlidesLoadedEvent>(), hasLength(1));

      await deckLoader.reload();
      await _waitUntil(
        () => events.whereType<SlidesLoadingEvent>().length == 2,
      );

      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 2),
      );

      await _waitUntil(() => events.whereType<SlidesLoadedEvent>().length >= 2);
      expect(
        events.whereType<SlidesLoadedEvent>().length,
        greaterThanOrEqualTo(2),
      );
    });

    test('dispose after reload: stops watching, no late events', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validSlidesJson);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 0),
      );

      final events = <SlidesEvent>[];
      final streamDone = Completer<void>();
      final sub = deckLoader.load().listen(
        events.add,
        onDone: () {
          if (!streamDone.isCompleted) streamDone.complete();
        },
      );
      addTearDown(sub.cancel);

      await _waitForEvent<SlidesLoadedEvent>(events);
      await deckLoader.reload();
      await _waitUntil(
        () => events.whereType<SlidesLoadingEvent>().length == 2,
      );

      await deckLoader.dispose();
      await streamDone.future.timeout(const Duration(seconds: 2));

      final snapshot = events.length;

      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 3),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(events, hasLength(snapshot));
    });

    test('event ordering: loading before loaded', () async {
      await config.superdeckDir.create(recursive: true);
      await config.deckJson.writeAsString(_validSlidesJson);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('success', seq: 0),
      );

      final events = <SlidesEvent>[];
      final sub = deckLoader.load().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvent<SlidesLoadedEvent>(events);

      final loadingIdx = events.indexWhere((e) => e is SlidesLoadingEvent);
      final loadedIdx = events.indexWhere((e) => e is SlidesLoadedEvent);
      expect(loadingIdx, lessThan(loadedIdx));
    });

    test('event ordering: loading before rebuilding', () async {
      await config.superdeckDir.create(recursive: true);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('building', seq: 0),
      );

      final events = <SlidesEvent>[];
      final sub = deckLoader.load().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvent<SlidesRebuildingEvent>(events);

      final loadingIdx = events.indexWhere((e) => e is SlidesLoadingEvent);
      final rebuildIdx = events.indexWhere((e) => e is SlidesRebuildingEvent);
      expect(loadingIdx, lessThan(rebuildIdx));
    });

    test('event ordering: loading before error', () async {
      await config.superdeckDir.create(recursive: true);
      await config.buildStatusJson.writeAsString(
        _buildStatusJson('failure', seq: 0, errorMessage: 'bad'),
      );

      final events = <SlidesEvent>[];
      final sub = deckLoader.load().listen(events.add);
      addTearDown(sub.cancel);

      await _waitForEvent<SlidesErrorEvent>(events);

      final loadingIdx = events.indexWhere((e) => e is SlidesLoadingEvent);
      final errorIdx = events.indexWhere((e) => e is SlidesErrorEvent);
      expect(loadingIdx, lessThan(errorIdx));
    });
  });
}
