import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

import '../testing_utils.dart';

void main() {
  group('DeckController', () {
    late DeckController controller;

    setUp(() {
      controller = DeckController(
        deck: createTestDeck(),
        theme: const DeckTheme(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('initializes with deck-backed slide data', () {
        expect(controller.totalSlides.value, 3);
        expect(controller.currentSlide.value, isNotNull);
      });

      test('initializes with default navigation values', () {
        expect(controller.currentIndex.value, 0);
        expect(controller.isTransitioning.value, isFalse);
      });

      test('initializes with default UI state', () {
        expect(controller.isMenuOpen.value, isFalse);
        expect(controller.isNotesOpen.value, isFalse);
      });

      test('router is initialized', () {
        expect(controller.router, isNotNull);
      });
    });

    group('Reactive Deck State', () {
      test('updates slides when deck changes', () {
        controller.updateDeck(createTestDeck(slides: [
          createSlideFromBlocks([createContentBlock('Single slide')]),
        ]));

        expect(controller.totalSlides.value, 1);
        expect(controller.currentSlide.value, isNotNull);
      });
    });

    group('UI State Toggles', () {
      test('openMenu sets isMenuOpen to true', () {
        expect(controller.isMenuOpen.value, isFalse);
        controller.openMenu();
        expect(controller.isMenuOpen.value, isTrue);
      });

      test('closeMenu sets isMenuOpen to false', () {
        controller.openMenu();
        expect(controller.isMenuOpen.value, isTrue);
        controller.closeMenu();
        expect(controller.isMenuOpen.value, isFalse);
      });

      test('toggleNotes toggles isNotesOpen', () {
        expect(controller.isNotesOpen.value, isFalse);
        controller.toggleNotes();
        expect(controller.isNotesOpen.value, isTrue);
        controller.toggleNotes();
        expect(controller.isNotesOpen.value, isFalse);
      });
    });

    group('Theme Updates', () {
      test('updateTheme updates internal theme', () {
        const newTheme = DeckTheme(debug: true);
        expect(() => controller.updateTheme(newTheme), returnsNormally);
      });

      test('updateTheme does not throw when unchanged', () {
        const theme = DeckTheme();
        expect(() {
          controller.updateTheme(theme);
          controller.updateTheme(theme);
        }, returnsNormally);
      });
    });

    group('Disposal', () {
      test('dispose completes without error', () {
        final disposableController = DeckController(
          deck: createTestDeck(),
          theme: const DeckTheme(),
        );

        expect(() => disposableController.dispose(), returnsNormally);
      });
    });
  });
}

