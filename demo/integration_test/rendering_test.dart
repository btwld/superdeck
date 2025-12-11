import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck_example/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Rendering', () {
    setUpAll(() async {
      // Disable frame policy to speed up tests a bit.
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    });

    testWidgets('first slide renders without errors', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('can navigate forward and back through slides', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      for (int i = 0; i < 3; i++) {
        await tester.navigateToNextSlide();
      }
      for (int i = 0; i < 3; i++) {
        await tester.navigateToPreviousSlide();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('slide content is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      final textWidgets = find.byType(Text);
      expect(textWidgets, findsWidgets);
      final visible = textWidgets.evaluate().where((e) {
        final box = e.renderObject as RenderBox?;
        return box != null && box.hasSize && box.size.width > 0 && box.size.height > 0;
      });
      expect(visible.isNotEmpty, true);
    });

    testWidgets('no overflow errors when navigating quickly', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      for (int i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }, skip: 'Platform smoke is optional and macOS desktop device/arch is not available in this environment.');
}
