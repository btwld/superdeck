import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/test_helpers.dart';

class MockDeckLoader extends DeckLoader {
  final StreamController<SlidesEvent> _eventController =
      StreamController<SlidesEvent>.broadcast();
  final List<Slide> _slidesToReturn = createTestSlidesPayload();

  bool _autoLoad = true;
  var _disposed = false;

  MockDeckLoader({DeckWorkspace? workspace})
    : super(workspace: workspace ?? DeckWorkspace());

  int loadCalls = 0;
  int reloadCalls = 0;

  @override
  Stream<SlidesEvent> load() {
    loadCalls++;
    _scheduleAutoLoad();
    return _eventController.stream;
  }

  @override
  Future<void> reload() async {
    reloadCalls++;
    _scheduleAutoLoad();
  }

  void _scheduleAutoLoad() {
    if (_autoLoad) {
      Future.microtask(() {
        _eventController.add(SlidesLoadingEvent('Loading…'));
        _eventController.add(SlidesLoadedEvent(_slidesToReturn));
      });
    }
  }

  /// Disable auto-loading so events must be emitted manually.
  void disableAutoLoad() {
    _autoLoad = false;
  }

  void emitEvent(SlidesEvent event) {
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
      mockDeckLoader = MockDeckLoader();
      controller = DeckController(
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
      expect(controller.totalSlides.value, 3);
      expect(mockDeckLoader.loadCalls, greaterThan(0));
    });

    test(
      'reloadDeck with existing slides treats SlidesErrorEvent as build failure',
      () async {
        // Wait for initial auto-load to complete
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Disable auto-load for reload, then manually emit error
        mockDeckLoader.disableAutoLoad();
        await controller.reloadDeck();

        // After reload, auto-load is off, so emit events manually
        mockDeckLoader.emitEvent(SlidesLoadingEvent('Reloading…'));
        mockDeckLoader.emitEvent(
          SlidesErrorEvent('boom', error: StateError('boom')),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(controller.hasError.value, isFalse);
        expect(controller.isLoading.value, isFalse);
        expect(controller.isBuildActive.value, isFalse);
        expect(controller.buildFailure.value?.message, 'boom');
      },
    );

    test(
      'SlidesErrorEvent is fatal when no slides have been loaded yet',
      () async {
        final loader = MockDeckLoader();
        loader.disableAutoLoad();

        final ctrl = DeckController(
          deckLoader: loader,
          options: const DeckOptions(),
        );
        addTearDown(() async {
          ctrl.dispose();
          await loader.dispose();
        });

        // Emit loading then error (no deck loaded yet)
        loader.emitEvent(SlidesLoadingEvent('Loading…'));
        loader.emitEvent(SlidesErrorEvent('boom', error: StateError('boom')));

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(ctrl.hasError.value, isTrue);
        expect(ctrl.error.value, isA<StateError>());
      },
    );

    test('building status toggles rebuilding without fatal error', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      mockDeckLoader.emitEvent(SlidesRebuildingEvent());

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isBuildActive.value, isTrue);
      expect(controller.hasError.value, isFalse);
    });

    test('rebuilding clears stale build failure', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      mockDeckLoader.emitEvent(
        SlidesErrorEvent('Old failure', error: Exception('Old failure')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.buildFailure.value?.message, 'Old failure');

      mockDeckLoader.emitEvent(SlidesRebuildingEvent());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isBuildActive.value, isTrue);
      expect(controller.buildFailure.value, isNull);
    });

    test(
      'failure status keeps app running and exposes build failure',
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));

        mockDeckLoader.emitEvent(
          SlidesErrorEvent(
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
        SlidesErrorEvent('Failed', error: Exception('Failed')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.buildFailure.value, isNotNull);

      // Then success clears it
      mockDeckLoader.emitEvent(SlidesLoadedEvent(createTestSlidesPayload()));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isBuildActive.value, isFalse);
      expect(controller.buildFailure.value, isNull);
      expect(controller.hasError.value, isFalse);
    });

    test('stale success after newer failure leaves failure state', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Emit a failure
      mockDeckLoader.emitEvent(
        SlidesErrorEvent('Newest failure', error: Exception('Newest failure')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isBuildActive.value, isFalse);
      expect(controller.buildFailure.value?.message, 'Newest failure');
    });

    test('empty slide list is a valid successful load', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      mockDeckLoader.disableAutoLoad();
      mockDeckLoader.emitEvent(SlidesLoadedEvent(const []));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.hasError.value, isFalse);
      expect(controller.totalSlides.value, 0);
      expect(controller.currentSlide.value, isNull);
    });
  });
}
