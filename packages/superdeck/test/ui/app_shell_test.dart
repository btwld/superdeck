import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:signals/signals.dart';
import 'package:superdeck/src/ui/app_shell.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../testing_utils.dart';

DeckDataState _createTestDataState() {
  final deck = createTestDeck();
  return DeckDataState(
    deck: signal<Deck?>(deck),
    loadingState: signal<DeckLoadingState>(DeckLoadingState.loaded),
    error: signal<Object?>(null),
    isRebuilding: signal<bool>(false),
    workspace: DeckWorkspace(),
    reload: () async {},
  );
}

void main() {
  testWidgets('rebinds menu effect when the inherited controller changes', (
    tester,
  ) async {
    final dataState = _createTestDataState();
    final controllerA = DeckController(
      dataState: dataState,
      theme: const DeckTheme(),
    );
    final controllerB = DeckController(
      dataState: dataState,
      theme: const DeckTheme(),
    );

    addTearDown(() {
      controllerA.dispose();
      controllerB.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MixScope(
          colors: SDColors.colorMap,
          child: InheritedData<DeckController>(
            data: controllerA,
            child: const AppShell(child: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        home: MixScope(
          colors: SDColors.colorMap,
          child: InheritedData<DeckController>(
            data: controllerB,
            child: const AppShell(child: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();

    controllerB.openMenu();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
