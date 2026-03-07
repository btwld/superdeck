import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck/src/utils/deck_watcher_io.dart';
import 'package:superdeck/src/utils/deck_watcher_types.dart';
import 'package:superdeck_core/superdeck_core.dart';

class _FakeDeckBuilder extends DeckBuilder {
  final Stream<BuildEvent> _events;
  bool disposed = false;

  _FakeDeckBuilder({
    required super.configuration,
    required super.store,
    required Stream<BuildEvent> events,
  }) : _events = events,
       super(tasks: const []);

  @override
  Stream<BuildEvent> watchAndBuild() => _events;

  @override
  Future<Iterable<Slide>> build() async => const [];

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('DeckWatcher', () {
    late Directory tempDir;
    late DeckWorkspace configuration;
    late DeckService store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('deck_watcher_test_');
      configuration = DeckWorkspace(projectDir: tempDir.path);
      store = DeckService(configuration: configuration);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('initial status is idle', () {
      final watcher = DeckWatcher(configuration: configuration, store: store);

      expect(watcher.status.value, DeckWatcherStatus.idle);
      expect(watcher.error.value, isNull);
      expect(watcher.isRebuilding.value, isFalse);

      watcher.dispose();
    });

    test(
      'start reacts to build events and updates rebuilding signal',
      () async {
        final events = StreamController<BuildEvent>();
        var builderFactoryCalls = 0;
        _FakeDeckBuilder? fakeBuilder;

        final watcher = DeckWatcher(
          configuration: configuration,
          store: store,
          builderFactory:
              ({
                required DeckWorkspace configuration,
                required DeckService store,
              }) {
                builderFactoryCalls++;
                fakeBuilder = _FakeDeckBuilder(
                  configuration: configuration,
                  store: store,
                  events: events.stream,
                );
                return fakeBuilder!;
              },
        );

        await watcher.start();
        expect(builderFactoryCalls, 1);
        expect(watcher.status.value, DeckWatcherStatus.running);

        events.add(const BuildStarted());
        await _flushEvents();
        expect(watcher.isRebuilding.value, isTrue);
        expect(watcher.status.value, DeckWatcherStatus.running);

        events.add(const BuildCompleted([]));
        await _flushEvents();
        expect(watcher.isRebuilding.value, isFalse);
        expect(watcher.status.value, DeckWatcherStatus.running);

        watcher.dispose();
        await _flushEvents();
        expect(fakeBuilder!.disposed, isTrue);
        await events.close();
      },
    );

    test('build failure sets status to failed and captures error', () async {
      final events = StreamController<BuildEvent>();
      final watcher = DeckWatcher(
        configuration: configuration,
        store: store,
        builderFactory:
            ({
              required DeckWorkspace configuration,
              required DeckService store,
            }) {
              return _FakeDeckBuilder(
                configuration: configuration,
                store: store,
                events: events.stream,
              );
            },
      );

      await watcher.start();

      final error = Exception('build failure');
      events.add(BuildFailed(error));
      await _flushEvents();

      expect(watcher.status.value, DeckWatcherStatus.failed);
      expect(watcher.error.value, error);
      expect(watcher.isRebuilding.value, isFalse);

      watcher.dispose();
      await events.close();
    });

    test('double start is a no-op', () async {
      final events = StreamController<BuildEvent>();
      var builderFactoryCalls = 0;

      final watcher = DeckWatcher(
        configuration: configuration,
        store: store,
        builderFactory:
            ({
              required DeckWorkspace configuration,
              required DeckService store,
            }) {
              builderFactoryCalls++;
              return _FakeDeckBuilder(
                configuration: configuration,
                store: store,
                events: events.stream,
              );
            },
      );

      await watcher.start();
      await watcher.start();

      expect(builderFactoryCalls, 1);
      expect(watcher.status.value, DeckWatcherStatus.running);

      watcher.dispose();
      await events.close();
    });

    test('stream error sets status to failed', () async {
      final events = StreamController<BuildEvent>();
      final watcher = DeckWatcher(
        configuration: configuration,
        store: store,
        builderFactory:
            ({
              required DeckWorkspace configuration,
              required DeckService store,
            }) {
              return _FakeDeckBuilder(
                configuration: configuration,
                store: store,
                events: events.stream,
              );
            },
      );

      await watcher.start();
      events.addError(Exception('stream error'));
      await _flushEvents();

      expect(watcher.status.value, DeckWatcherStatus.failed);
      expect(watcher.isRebuilding.value, isFalse);

      watcher.dispose();
      await events.close();
    });

    test('can restart after stream error failure', () async {
      final firstEvents = StreamController<BuildEvent>();
      final secondEvents = StreamController<BuildEvent>();
      final eventStreams = [firstEvents.stream, secondEvents.stream];
      var builderFactoryCalls = 0;
      final builders = <_FakeDeckBuilder>[];

      final watcher = DeckWatcher(
        configuration: configuration,
        store: store,
        builderFactory:
            ({
              required DeckWorkspace configuration,
              required DeckService store,
            }) {
              final builder = _FakeDeckBuilder(
                configuration: configuration,
                store: store,
                events: eventStreams[builderFactoryCalls],
              );
              builderFactoryCalls++;
              builders.add(builder);
              return builder;
            },
      );

      await watcher.start();
      expect(builderFactoryCalls, 1);

      firstEvents.addError(Exception('stream error'));
      await _flushEvents();
      expect(watcher.status.value, DeckWatcherStatus.failed);

      await watcher.start();
      expect(builderFactoryCalls, 2);
      expect(builders.first.disposed, isTrue);
      expect(watcher.status.value, DeckWatcherStatus.running);
      expect(watcher.error.value, isNull);

      secondEvents.add(const BuildStarted());
      await _flushEvents();
      expect(watcher.isRebuilding.value, isTrue);

      watcher.dispose();
      await _flushEvents();
      expect(builders.last.disposed, isTrue);

      await firstEvents.close();
      await secondEvents.close();
    });

    test('can restart after stream completion stop', () async {
      final firstEvents = StreamController<BuildEvent>();
      final secondEvents = StreamController<BuildEvent>();
      final eventStreams = [firstEvents.stream, secondEvents.stream];
      var builderFactoryCalls = 0;
      final builders = <_FakeDeckBuilder>[];

      final watcher = DeckWatcher(
        configuration: configuration,
        store: store,
        builderFactory:
            ({
              required DeckWorkspace configuration,
              required DeckService store,
            }) {
              final builder = _FakeDeckBuilder(
                configuration: configuration,
                store: store,
                events: eventStreams[builderFactoryCalls],
              );
              builderFactoryCalls++;
              builders.add(builder);
              return builder;
            },
      );

      await watcher.start();
      expect(builderFactoryCalls, 1);

      await firstEvents.close();
      await _flushEvents();
      expect(watcher.status.value, DeckWatcherStatus.stopped);

      await watcher.start();
      expect(builderFactoryCalls, 2);
      expect(builders.first.disposed, isTrue);
      expect(watcher.status.value, DeckWatcherStatus.running);

      watcher.dispose();
      await _flushEvents();
      expect(builders.last.disposed, isTrue);

      await secondEvents.close();
    });

    test('multiple dispose calls are safe', () {
      final watcher = DeckWatcher(configuration: configuration, store: store);

      expect(() {
        watcher.dispose();
        watcher.dispose();
        watcher.dispose();
      }, returnsNormally);
    });
  });
}
