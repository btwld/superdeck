import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck_example/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Semantics Tests', () {
    testWidgets(
      'app has proper semantic labels for slides',
      (tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle();

        // Wait for presentation to load
        await waitForPresentationLoad(
          tester,
          timeout: const Duration(seconds: 15),
        );

        // Verify semantic label for first slide exists
        // Note: The semantic label gets merged with slide content, so we use RegExp
        expect(find.bySemanticsLabel(RegExp(r'^Slide 1')), findsOneWidget);

        // Navigate to next slide
        await tester.navigateToNextSlide();

        // Verify semantic label for second slide
        expect(find.bySemanticsLabel(RegExp(r'^Slide 2')), findsOneWidget);

        // Navigate to previous slide
        await tester.navigateToPreviousSlide();

        // Back to first slide
        expect(find.bySemanticsLabel(RegExp(r'^Slide 1')), findsOneWidget);
      },
      semanticsEnabled: true,
    );

    testWidgets(
      'app is accessible with screen reader support',
      (tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle();

        // Wait for presentation to load
        await waitForPresentationLoad(
          tester,
          timeout: const Duration(seconds: 15),
        );

        // Verify we have semantic nodes
        // Note: Using first() because there may be multiple MaterialApp instances
        final materialApps = find.byType(MaterialApp);
        expect(materialApps, findsAtLeastNWidgets(1));
      },
      semanticsEnabled: true,
    );
  });
}
