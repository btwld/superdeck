import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/deck/navigation_events.dart';

import '../../helpers/mock_deck_loader.dart';

Future<void> _waitForInitialLoad() {
  return Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  group('DeckController navigation', () {
    late MockDeckLoader loader;
    late DeckController controller;

    setUp(() async {
      loader = MockDeckLoader();
      controller = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
        transitionDuration: Duration.zero,
      );
      await _waitForInitialLoad();
    });

    tearDown(() async {
      controller.dispose();
      await loader.dispose();
    });

    test('nextSlide advances currentIndex when canGoNext', () async {
      expect(controller.canGoNext.value, isTrue);

      await controller.nextSlide();

      expect(controller.currentIndex.value, 1);
    });

    test('nextSlide is a no-op at the last slide', () async {
      await controller.goToSlide(2);
      expect(controller.canGoNext.value, isFalse);

      await controller.nextSlide();

      expect(controller.currentIndex.value, 2);
    });

    test('previousSlide decrements currentIndex when canGoPrevious', () async {
      await controller.goToSlide(2);
      expect(controller.canGoPrevious.value, isTrue);

      await controller.previousSlide();

      expect(controller.currentIndex.value, 1);
    });

    test('previousSlide is a no-op at the first slide', () async {
      expect(controller.canGoPrevious.value, isFalse);

      await controller.previousSlide();

      expect(controller.currentIndex.value, 0);
    });

    test('handleNavigationEvent dispatches NextSlideEvent forwards', () async {
      await controller.handleNavigationEvent(NextSlideEvent());

      expect(controller.currentIndex.value, 1);
    });

    test(
      'handleNavigationEvent dispatches PreviousSlideEvent backwards',
      () async {
        await controller.goToSlide(2);

        await controller.handleNavigationEvent(PreviousSlideEvent());

        expect(controller.currentIndex.value, 1);
      },
    );

    test('handleNavigationEvent dispatches GoToSlideEvent by index', () async {
      await controller.handleNavigationEvent(GoToSlideEvent(2));

      expect(controller.currentIndex.value, 2);
    });
  });

  group('DeckController options', () {
    test('updateOptions updates slides only when options change', () async {
      final initialOptions = DeckOptions();
      final loader = MockDeckLoader();
      final controller = DeckController(
        deckLoader: loader,
        options: initialOptions,
        transitionDuration: Duration.zero,
      );
      addTearDown(() async {
        controller.dispose();
        await loader.dispose();
      });

      await _waitForInitialLoad();
      final initialSlides = controller.slides.value;
      expect(initialSlides.first.debug, isFalse);

      controller.updateOptions(initialOptions);

      expect(controller.slides.value, same(initialSlides));

      controller.updateOptions(DeckOptions(debug: true));

      expect(controller.slides.value, isNot(same(initialSlides)));
      expect(controller.slides.value.first.debug, isTrue);
    });
  });
}
