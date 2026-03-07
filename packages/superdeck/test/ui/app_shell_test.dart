import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/runtime/deck_controller.dart';
import 'package:superdeck/src/ui/app_shell.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../testing_utils.dart';

class _StaticDeckService extends DeckService {
  _StaticDeckService() : super(configuration: DeckWorkspace());

  @override
  Future<Deck> loadDeck() async => createTestDeck();
}

void main() {
  testWidgets('rebinds menu effect when the inherited handle changes', (
    tester,
  ) async {
    final deckService = _StaticDeckService();
    final controller = DeckController(
      deckService: deckService,
      theme: const DeckTheme(),
      enableDeckStream: false,
    );
    final initialHandle = SuperDeckHandle()..attach(controller);
    final replacementHandle = SuperDeckHandle();

    addTearDown(() {
      initialHandle.detach(controller);
      replacementHandle.detach(controller);
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MixScope(
          colors: SDColors.colorMap,
          child: InheritedData<SuperDeckHandle>(
            data: initialHandle,
            child: const AppShell(child: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();

    initialHandle.detach(controller);
    replacementHandle.attach(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: MixScope(
          colors: SDColors.colorMap,
          child: InheritedData<SuperDeckHandle>(
            data: replacementHandle,
            child: const AppShell(child: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();

    controller.openMenu();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
