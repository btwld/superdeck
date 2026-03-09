import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  testWidgets('rebuilds controller when SuperDeckProvider config changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      SuperDeckProvider(
        config: const DeckConfig.bundle(outputDir: '.superdeck-a'),
        builder: (context, deck) => SuperDeckApp(deck: deck),
      ),
    );
    await tester.pump();

    // Use a context inside SuperDeckApp's build tree (below InheritedData).
    final controllerA = SuperDeck.of(
      tester.element(find.byType(MaterialApp).first),
    );
    final initialIndexSignal = controllerA.currentIndex;

    await tester.pumpWidget(
      SuperDeckProvider(
        key: const ValueKey('b'),
        config: const DeckConfig.bundle(outputDir: '.superdeck-b'),
        builder: (context, deck) => SuperDeckApp(deck: deck),
      ),
    );
    await tester.pump();

    final controllerB = SuperDeck.of(
      tester.element(find.byType(MaterialApp).first),
    );

    expect(identical(controllerB.currentIndex, initialIndexSignal), isFalse);
    expect(controllerB.currentIndex.value, 0);
    expect(tester.takeException(), isNull);
  });
}
