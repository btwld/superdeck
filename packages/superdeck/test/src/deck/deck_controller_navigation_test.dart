import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';

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
      final pres = controller.presentation;
      expect(pres.canGoNext.value, isTrue);

      await pres.nextSlide();

      expect(pres.currentIndex.value, 1);
    });

    test('nextSlide is a no-op at the last slide', () async {
      final pres = controller.presentation;
      await pres.goToSlide(2);
      expect(pres.canGoNext.value, isFalse);

      await pres.nextSlide();

      expect(pres.currentIndex.value, 2);
    });

    test('previousSlide decrements currentIndex when canGoPrevious', () async {
      final pres = controller.presentation;
      await pres.goToSlide(2);
      expect(pres.canGoPrevious.value, isTrue);

      await pres.previousSlide();

      expect(pres.currentIndex.value, 1);
    });

    test('previousSlide is a no-op at the first slide', () async {
      final pres = controller.presentation;
      expect(pres.canGoPrevious.value, isFalse);

      await pres.previousSlide();

      expect(pres.currentIndex.value, 0);
    });
  });

  group('DeckController options', () {
    test('options signal updates slides only when value changes', () async {
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

      controller.options.value = initialOptions;

      expect(controller.slides.value, same(initialSlides));

      controller.options.value = DeckOptions(debug: true);

      expect(controller.slides.value, isNot(same(initialSlides)));
      expect(controller.slides.value.first.debug, isTrue);
    });
  });
}
