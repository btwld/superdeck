import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Creates a test DeckDataState with controllable signals.
({
  DeckDataState dataState,
  Signal<Deck?> deck,
  Signal<DeckLoadingState> loadingState,
  Signal<Object?> error,
  Signal<bool> isRebuilding,
  int Function() reloadCount,
}) createTestDataState({Deck? initialDeck}) {
  final deck = signal<Deck?>(initialDeck);
  final loadingState = signal<DeckLoadingState>(
    initialDeck != null ? DeckLoadingState.loaded : DeckLoadingState.loading,
  );
  final error = signal<Object?>(null);
  final isRebuilding = signal<bool>(false);
  var reloads = 0;

  final dataState = DeckDataState(
    deck: deck,
    loadingState: loadingState,
    error: error,
    isRebuilding: isRebuilding,
    workspace: DeckWorkspace(),
    reload: () async {
      reloads++;
    },
  );

  return (
    dataState: dataState,
    deck: deck,
    loadingState: loadingState,
    error: error,
    isRebuilding: isRebuilding,
    reloadCount: () => reloads,
  );
}

void main() {
  group('DeckController', () {
    late DeckController controller;
    late Signal<DeckLoadingState> loadingStateSignal;
    late Signal<Object?> errorSignal;
    late Signal<bool> isRebuildingSignal;
    late int Function() reloadCount;

    setUp(() {
      final testState = createTestDataState();
      loadingStateSignal = testState.loadingState;
      errorSignal = testState.error;
      isRebuildingSignal = testState.isRebuilding;
      reloadCount = testState.reloadCount;
      controller = DeckController(
        dataState: testState.dataState,
        theme: const DeckTheme(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('reflects loading state from DeckDataState', () {
        expect(controller.isLoading.value, isTrue);
        expect(controller.hasError.value, isFalse);
      });

      test('initializes with default navigation values', () {
        expect(controller.currentIndex.value, 0);
        expect(controller.isTransitioning.value, isFalse);
      });

      test('initializes with default UI state', () {
        expect(controller.isMenuOpen.value, isFalse);
        expect(controller.isNotesOpen.value, isFalse);
        expect(controller.isRebuilding.value, isFalse);
      });

      test('router is initialized', () {
        expect(controller.router, isNotNull);
      });
    });

    group('Reactive Data State', () {
      test('transitions to loaded when data state changes', () {
        loadingStateSignal.value = DeckLoadingState.loaded;
        expect(controller.isLoading.value, isFalse);
        expect(controller.hasError.value, isFalse);
      });

      test('transitions to error when data state has error', () {
        errorSignal.value = Exception('Test error');
        loadingStateSignal.value = DeckLoadingState.error;
        expect(controller.hasError.value, isTrue);
        expect(controller.error.value, isNotNull);
      });

      test('isRebuilding reflects data state signal', () {
        expect(controller.isRebuilding.value, isFalse);
        isRebuildingSignal.value = true;
        expect(controller.isRebuilding.value, isTrue);
        isRebuildingSignal.value = false;
        expect(controller.isRebuilding.value, isFalse);
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
        expect(
          () => controller.updateTheme(newTheme),
          returnsNormally,
        );
      });

      test('updateTheme does not trigger if theme is unchanged', () {
        const theme = DeckTheme();
        expect(() {
          controller.updateTheme(theme);
          controller.updateTheme(theme);
        }, returnsNormally);
      });
    });

    group('Reload', () {
      test('reload delegates to DeckDataState', () async {
        expect(reloadCount(), 0);
        await controller.reload();
        expect(reloadCount(), 1);
        await controller.reload();
        expect(reloadCount(), 2);
      });
    });

    group('Disposal', () {
      test('dispose completes without error', () {
        final testState = createTestDataState();
        final disposableController = DeckController(
          dataState: testState.dataState,
          theme: const DeckTheme(),
        );

        expect(() => disposableController.dispose(), returnsNormally);
      });
    });
  });
}
