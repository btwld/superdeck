import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  testWidgets(
    'rebuilds bootstrap state when a new runtime instance is provided',
    (tester) async {
      final sharedHandle = SuperDeckHandle();
      final initialRuntime = SuperDeckRuntime.forTesting(
        handle: sharedHandle,
        runtimeConfig: const DeckRuntimeConfig(outputDir: '.superdeck-a'),
      );

      await tester.pumpWidget(SuperDeckApp(runtime: initialRuntime));
      await tester.pump();

      final initialIndexSignal = sharedHandle.currentIndex;

      final replacementRuntime = SuperDeckRuntime.forTesting(
        handle: sharedHandle,
        runtimeConfig: const DeckRuntimeConfig(outputDir: '.superdeck-b'),
      );

      await tester.pumpWidget(SuperDeckApp(runtime: replacementRuntime));
      await tester.pump();

      expect(identical(sharedHandle.currentIndex, initialIndexSignal), isFalse);
      expect(sharedHandle.currentIndex.value, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
