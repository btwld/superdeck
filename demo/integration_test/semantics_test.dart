import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck_example/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Semantics Tests', () {
    testWidgets('app has proper semantic labels for slides', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for presentation to load
      await waitForPresentationLoad(tester,
          timeout: const Duration(seconds: 15));

      // Verify semantic label for first slide exists
      expect(find.bySemanticsLabel('Slide 1'), findsOneWidget);

      // Navigate to next slide
      await tester.navigateToNextSlide();

      // Verify semantic label for second slide
      expect(find.bySemanticsLabel('Slide 2'), findsOneWidget);

      // Navigate to previous slide
      await tester.navigateToPreviousSlide();

      // Back to first slide
      expect(find.bySemanticsLabel('Slide 1'), findsOneWidget);
    });

    testWidgets('app is accessible with screen reader support', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for presentation to load
      await waitForPresentationLoad(tester,
          timeout: const Duration(seconds: 15));

      // Check that semantic tree is built correctly
      final SemanticsHandle handle = tester.ensureSemantics();

      // Verify we have semantic nodes
      expect(tester.getSemantics(find.byType(MaterialApp)), isNotNull);

      // Clean up
      handle.dispose();
    });
  });
}
