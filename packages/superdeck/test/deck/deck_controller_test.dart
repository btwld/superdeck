import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../testing_utils.dart';

class MockDeckService extends DeckService {
  MockDeckService({DeckConfiguration? configuration})
    : super(configuration: configuration ?? DeckConfiguration());

  final StreamController<DeckBuildStatus> _statusController =
      StreamController<DeckBuildStatus>.broadcast();

  Deck deckToReturn = createTestDeck();
  Completer<Deck>? nextLoadDeckCompleter;
  Object? errorToThrow;
  int loadDeckCalls = 0;

  @override
  Future<Deck> loadDeck() async {
    loadDeckCalls++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    final completer = nextLoadDeckCompleter;
    if (completer != null) {
      nextLoadDeckCompleter = null;
      return completer.future;
    }
    return deckToReturn;
  }

  @override
  Stream<DeckBuildStatus> watchBuildStatus() {
    return _statusController.stream;
  }

  void emitStatus(DeckBuildStatus status) {
    _statusController.add(status);
  }

  Future<void> disposeService() async {
    await _statusController.close();
  }
}

void main() {
  group('DeckController', () {
    late MockDeckService mockDeckService;
    late DeckController controller;

    setUp(() {
      mockDeckService = MockDeckService();
      controller = DeckController(
        deckService: mockDeckService,
        options: const DeckOptions(),
        enableBuildStatusWatch: true,
      );
    });

    tearDown(() async {
      controller.dispose();
      await mockDeckService.disposeService();
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
      expect(mockDeckService.loadDeckCalls, greaterThan(0));
    });

    test('reloadDeck sets fatal error state when load throws', () async {
      mockDeckService.errorToThrow = StateError('boom');

      await controller.reloadDeck();

      expect(controller.hasError.value, isTrue);
      expect(controller.error.value, isA<StateError>());
    });

    test('building status toggles rebuilding without fatal error', () async {
      mockDeckService.emitStatus(
        DeckBuildStatus(
          phase: DeckBuildPhase.building,
          timestamp: DateTime.parse('2026-03-10T12:00:00.000Z'),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isBuildActive.value, isTrue);
      expect(controller.hasError.value, isFalse);
    });

    test(
      'failure status keeps app running and exposes build failure',
      () async {
        mockDeckService.emitStatus(
          DeckBuildStatus(
            phase: DeckBuildPhase.failure,
            timestamp: DateTime.parse('2026-03-10T12:00:00.000Z'),
            error: const DeckBuildError(
              type: 'BuildFailure',
              message: 'Syntax error in slides.md',
            ),
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

    test(
      'success status triggers background reload and clears build failure',
      () async {
        mockDeckService.emitStatus(
          DeckBuildStatus(
            phase: DeckBuildPhase.failure,
            timestamp: DateTime.parse('2026-03-10T12:00:00.000Z'),
            error: const DeckBuildError(
              type: 'BuildFailure',
              message: 'Failed',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final beforeSuccessCalls = mockDeckService.loadDeckCalls;

        mockDeckService.emitStatus(
          DeckBuildStatus(
            phase: DeckBuildPhase.success,
            timestamp: DateTime.parse('2026-03-10T12:00:01.000Z'),
            slideCount: 3,
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(mockDeckService.loadDeckCalls, greaterThan(beforeSuccessCalls));
        expect(controller.isBuildActive.value, isFalse);
        expect(controller.buildFailure.value, isNull);
        expect(controller.hasError.value, isFalse);
      },
    );

    test('stale success reload does not clear newer failure state', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final reloadCompleter = Completer<Deck>();
      mockDeckService.nextLoadDeckCompleter = reloadCompleter;

      mockDeckService.emitStatus(
        DeckBuildStatus(
          phase: DeckBuildPhase.success,
          timestamp: DateTime.parse('2026-03-10T12:00:01.000Z'),
          slideCount: 3,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      mockDeckService.emitStatus(
        DeckBuildStatus(
          phase: DeckBuildPhase.failure,
          timestamp: DateTime.parse('2026-03-10T12:00:02.000Z'),
          error: const DeckBuildError(
            type: 'BuildFailure',
            message: 'Newest failure',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      reloadCompleter.complete(createTestDeck());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.isBuildActive.value, isFalse);
      expect(controller.buildFailure.value?.message, 'Newest failure');
    });
  });
}
