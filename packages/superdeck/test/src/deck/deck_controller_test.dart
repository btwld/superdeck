import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/mock_deck_loader.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('DeckController', () {
    late MockDeckLoader mockDeckLoader;
    late DeckController controller;

    setUp(() {
      mockDeckLoader = MockDeckLoader();
      controller = DeckController(
        deckLoader: mockDeckLoader,
        options: DeckOptions(),
      );
    });

    tearDown(() async {
      controller.dispose();
      await mockDeckLoader.dispose();
    });

    test('initializes router and default UI state', () {
      expect(controller.presentation.router, isNotNull);
      expect(controller.presentation.isMenuOpen.value, isFalse);
      expect(controller.presentation.isNotesOpen.value, isFalse);
      expect(controller.session.isBuildActive.value, isFalse);
    });

    test('goToSlide ignores out of range indexes', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await controller.presentation.goToSlide(-1);
      expect(controller.presentation.currentIndex.value, 0);

      await controller.presentation.goToSlide(99);
      expect(controller.presentation.currentIndex.value, 0);
    });

    test('goToSlide updates current slide when index is valid', () async {
      final loader = MockDeckLoader();
      final ctrl = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
        transitionDuration: Duration.zero,
      );
      addTearDown(() async {
        ctrl.dispose();
        await loader.dispose();
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await ctrl.presentation.goToSlide(2);

      expect(ctrl.presentation.currentIndex.value, 2);
      expect(ctrl.presentation.currentSlide.value?.slideIndex, 2);
    });

    test(
      'dispose during an active transition does not surface an error',
      () async {
        final loader = MockDeckLoader();
        final ctrl = DeckController(
          deckLoader: loader,
          options: DeckOptions(),
          transitionDuration: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          await loader.dispose();
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final navigation = ctrl.presentation.goToSlide(1);
        ctrl.dispose();

        await expectLater(navigation, completes);
      },
    );

    test('initial load transitions to loaded state', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.session.isLoading.value, isFalse);
      expect(controller.session.hasFatalError.value, isFalse);
      expect(controller.presentation.totalSlides.value, 3);
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

        expect(controller.session.hasFatalError.value, isFalse);
        expect(controller.session.isLoading.value, isFalse);
        expect(controller.session.isBuildActive.value, isFalse);
        expect(controller.session.buildFailure.value?.message, 'boom');
      },
    );

    test(
      'SlidesErrorEvent is fatal when no slides have been loaded yet',
      () async {
        final loader = MockDeckLoader();
        loader.disableAutoLoad();

        final ctrl = DeckController(deckLoader: loader, options: DeckOptions());
        addTearDown(() async {
          ctrl.dispose();
          await loader.dispose();
        });

        // Emit loading then error (no deck loaded yet)
        loader.emitEvent(SlidesLoadingEvent('Loading…'));
        loader.emitEvent(SlidesErrorEvent('boom', error: StateError('boom')));

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(ctrl.session.hasFatalError.value, isTrue);
        expect(ctrl.session.error.value, isA<StateError>());
      },
    );

    test('building status toggles rebuilding without fatal error', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      mockDeckLoader.emitEvent(SlidesRebuildingEvent());

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.session.isBuildActive.value, isTrue);
      expect(controller.session.hasFatalError.value, isFalse);
    });

    test('rebuilding clears stale build failure', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      mockDeckLoader.emitEvent(
        SlidesErrorEvent('Old failure', error: Exception('Old failure')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.session.buildFailure.value?.message, 'Old failure');

      mockDeckLoader.emitEvent(SlidesRebuildingEvent());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.session.isBuildActive.value, isTrue);
      expect(controller.session.buildFailure.value, isNull);
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

        expect(controller.session.isBuildActive.value, isFalse);
        expect(
          controller.session.buildFailure.value?.message,
          'Syntax error in slides.md',
        );
        expect(controller.session.hasFatalError.value, isFalse);
      },
    );

    test('success event clears build failure', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // First, create a build failure
      mockDeckLoader.emitEvent(
        SlidesErrorEvent('Failed', error: Exception('Failed')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.session.buildFailure.value, isNotNull);

      // Then success clears it
      mockDeckLoader.emitEvent(SlidesLoadedEvent(createTestSlidesPayload()));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.session.isBuildActive.value, isFalse);
      expect(controller.session.buildFailure.value, isNull);
      expect(controller.session.hasFatalError.value, isFalse);
    });

    test('stale success after newer failure leaves failure state', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Emit a failure
      mockDeckLoader.emitEvent(
        SlidesErrorEvent('Newest failure', error: Exception('Newest failure')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.session.isBuildActive.value, isFalse);
      expect(controller.session.buildFailure.value?.message, 'Newest failure');
    });

    test('empty slide list is a valid successful load', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      mockDeckLoader.disableAutoLoad();
      mockDeckLoader.emitEvent(SlidesLoadedEvent(const []));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.session.hasFatalError.value, isFalse);
      expect(controller.presentation.totalSlides.value, 0);
      expect(controller.presentation.currentSlide.value, isNull);
    });

    test(
      'stream error sets hasError when no slides have been loaded',
      () async {
        final loader = MockDeckLoader();
        loader.disableAutoLoad();

        final ctrl = DeckController(deckLoader: loader, options: DeckOptions());
        addTearDown(() async {
          ctrl.dispose();
          await loader.dispose();
        });

        loader.emitError(StateError('stream broke'));

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(ctrl.session.hasFatalError.value, isTrue);
        expect(ctrl.session.error.value, isA<StateError>());
        expect(ctrl.session.isLoading.value, isFalse);
        expect(ctrl.session.isBuildActive.value, isFalse);
        expect(ctrl.session.buildFailure.value, isNull);
      },
    );

    test(
      'stream error sets buildFailure when slides are already loaded',
      () async {
        // Wait for initial auto-load to complete
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(controller.presentation.totalSlides.value, 3);

        mockDeckLoader.emitError(StateError('stream broke'));

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(controller.session.hasFatalError.value, isFalse);
        expect(controller.session.isBuildActive.value, isFalse);
        expect(controller.session.buildFailure.value, isNotNull);
        expect(
          controller.session.buildFailure.value?.message,
          contains('stream broke'),
        );
      },
    );

    test(
      'stream error with DeckBuildError preserves it as buildFailure',
      () async {
        // Wait for initial auto-load to complete
        await Future<void>.delayed(const Duration(milliseconds: 10));

        mockDeckLoader.emitError(DeckBuildError(message: 'build failed'));

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(controller.session.buildFailure.value, isA<DeckBuildError>());
        expect(controller.session.buildFailure.value?.message, 'build failed');
      },
    );
  });
}
