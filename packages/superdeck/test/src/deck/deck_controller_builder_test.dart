import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller_builder.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/mock_deck_loader.dart';

void main() {
  group('DeckControllerBuilder', () {
    // This test runs first because it does not corrupt widget tree state.
    testWidgets('options change propagates without assertion error', (
      tester,
    ) async {
      final loader = MockDeckLoader();

      // Intercept FlutterErrors to check for assertion errors
      final loaderAssertErrors = <FlutterErrorDetails>[];
      final originalHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final ex = details.exception;
        if (ex is AssertionError &&
            ex.message.toString().contains('must not change after mount')) {
          loaderAssertErrors.add(details);
        }
        // Suppress all errors (overflow, etc.)
      };

      await tester.pumpWidget(
        _TestApp(deckLoader: loader, options: DeckOptions()),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Update with new options — should not fire the loader assert
      await tester.pumpWidget(
        _TestApp(deckLoader: loader, options: DeckOptions(debug: true)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Restore handler before any assertions
      FlutterError.onError = originalHandler;

      // Drain any queued test framework exceptions
      while (tester.takeException() != null) {}

      // No loader-change assertion errors should have been captured
      expect(
        loaderAssertErrors,
        isEmpty,
        reason: 'Changing options should not fire the deckLoader assert',
      );

      await loader.dispose();
    });

    // This test intentionally corrupts the widget tree, so it runs last.
    testWidgets('assert fires when deckLoader changes', (tester) async {
      final loader1 = MockDeckLoader();
      final loader2 = MockDeckLoader();

      // Intercept all FlutterErrors to prevent cascading failures
      final errors = <FlutterErrorDetails>[];
      final originalHandler = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);

      await tester.pumpWidget(
        _TestApp(deckLoader: loader1, options: DeckOptions()),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Swap the loader — the assert fires during rebuild
      await tester.pumpWidget(
        _TestApp(deckLoader: loader2, options: DeckOptions()),
      );

      // Restore handler before any assertions
      FlutterError.onError = originalHandler;

      // Drain any queued test framework exceptions
      while (tester.takeException() != null) {}

      // Find our specific assertion among all captured errors
      final loaderAssertErrors = errors.where((e) {
        final ex = e.exception;
        return ex is AssertionError &&
            ex.message.toString().contains('must not change after mount');
      }).toList();

      expect(
        loaderAssertErrors,
        isNotEmpty,
        reason: 'Expected an AssertionError about deckLoader changing',
      );

      await loader1.dispose();
      await loader2.dispose();
    });
  });
}

class _TestApp extends StatelessWidget {
  final DeckLoader deckLoader;
  final DeckOptions options;

  const _TestApp({required this.deckLoader, required this.options});

  @override
  Widget build(BuildContext context) {
    return DeckControllerBuilder(
      deckLoader: deckLoader,
      options: options,
      builder: (context, router) {
        return MaterialApp.router(routerConfig: router);
      },
    );
  }
}
