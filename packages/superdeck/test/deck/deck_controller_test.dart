import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../testing_utils.dart';

class MockDeckLoader extends DeckLoader {
  MockDeckLoader({DeckConfiguration? configuration})
    : super(configuration: configuration ?? DeckConfiguration());

  final StreamController<DeckEvent> _eventController =
      StreamController<DeckEvent>.broadcast();

  int loadCalls = 0;

  @override
  Stream<DeckEvent> load() {
    loadCalls++;
    // Immediately emit loading + loaded for default behavior
    if (_autoLoad) {
      Future.microtask(() {
        _eventController.add(DeckLoadingEvent('Loading…'));
        _eventController.add(DeckLoadedEvent(_deckToReturn));
      });
    }
    return _eventController.stream;
  }

  bool _autoLoad = true;
  final Deck _deckToReturn = createTestDeck();
  var _disposed = false;

  /// Disable auto-loading so events must be emitted manually.
  void disableAutoLoad() {
    _autoLoad = false;
  }

  void emitEvent(DeckEvent event) {
    _eventController.add(event);
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    return _eventController.close();
  }
}

void main() {
  group('DeckController', () {
    late MockDeckLoader mockDeckLoader;
    late DeckController controller;

    setUp(() {
      final configuration = DeckConfiguration();
      mockDeckLoader = MockDeckLoader(configuration: configuration);
      controller = DeckController(
        configuration: configuration,
        deckLoader: mockDeckLoader,
        options: const DeckOptions(),
      );
    });

    tearDown(() async {
      controller.dispose();
      await mockDeckLoader.dispose();
    });

    test('initializes router and default UI state', () {
      expect(controller.router, isNotNull);
      expect(controller.isMenuOpen.value, isFalse);
      expect(controller.isNotesOpen.value, isFalse);
      expect(controller.isBuildActive.value, isFalse);
    });

    test('initial load transitions to loaded state', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isLoading.value, isFalse);
      expect(controller.hasError.value, isFalse);
      expect(mockDeckLoader.loadCalls, greaterThan(0));
    });

    test(
      'reloadDeck with existing deck treats DeckErrorEvent as build failure',
      () async {
        // Wait for initial auto-load to complete
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Disable auto-load for reload, then manually emit error
        mockDeckLoader.disableAutoLoad();
        await controller.reloadDeck();

        // After reload, auto-load is off, so emit events manually
        mockDeckLoader.emitEvent(DeckLoadingEvent('Reloading…'));
        mockDeckLoader.emitEvent(
          DeckErrorEvent('boom', error: StateError('boom')),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(controller.hasError.value, isFalse);
        expect(controller.isLoading.value, isFalse);
        expect(controller.isBuildActive.value, isFalse);
        expect(controller.buildFailure.value?.message, 'boom');
      },
    );

    test('DeckErrorEvent is fatal when no deck has been loaded yet', () async {
      final configuration = DeckConfiguration();
      final loader = MockDeckLoader(configuration: configuration);
      loader.disableAutoLoad();

      final ctrl = DeckController(
        configuration: configuration,
        deckLoader: loader,
        options: const DeckOptions(),
      );
      addTearDown(() async {
        ctrl.dispose();
        await loader.dispose();
      });

      // Emit loading then error (no deck loaded yet)
      loader.emitEvent(DeckLoadingEvent('Loading…'));
      loader.emitEvent(DeckErrorEvent('boom', error: StateError('boom')));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(ctrl.hasError.value, isTrue);
      expect(ctrl.error.value, isA<StateError>());
    });

    test('building status toggles rebuilding without fatal error', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      mockDeckLoader.emitEvent(DeckRebuildingEvent());

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isBuildActive.value, isTrue);
      expect(controller.hasError.value, isFalse);
    });

    test(
      'failure status keeps app running and exposes build failure',
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));

        mockDeckLoader.emitEvent(
          DeckErrorEvent(
            'Syntax error in slides.md',
            error: Exception('Syntax error in slides.md'),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(controller.isBuildActive.value, isFalse);
        expect(
          controller.buildFailure.value?.message,
          'Syntax error in slides.md',
        );
        expect(controller.hasError.value, isFalse);
      },
    );

    test('success event clears build failure', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // First, create a build failure
      mockDeckLoader.emitEvent(
        DeckErrorEvent('Failed', error: Exception('Failed')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.buildFailure.value, isNotNull);

      // Then success clears it
      mockDeckLoader.emitEvent(DeckLoadedEvent(createTestDeck()));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isBuildActive.value, isFalse);
      expect(controller.buildFailure.value, isNull);
      expect(controller.hasError.value, isFalse);
    });

    test('stale success after newer failure leaves failure state', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Emit a failure
      mockDeckLoader.emitEvent(
        DeckErrorEvent('Newest failure', error: Exception('Newest failure')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isBuildActive.value, isFalse);
      expect(controller.buildFailure.value?.message, 'Newest failure');
    });
  });
}
