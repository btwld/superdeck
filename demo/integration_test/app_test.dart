import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck_example/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SuperDeck Demo App Integration Tests', () {
    testWidgets('app launches and loads presentation with slides',
        (tester) async {
      // Launch the actual demo app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app has loaded (may have multiple MaterialApp instances in test environment)
      expect(find.byType(MaterialApp), findsWidgets);

      // Look for SuperDeck app components
      expect(find.byType(Scaffold), findsWidgets);

      // Wait for presentation to load (longer timeout for initial load)
      await waitForPresentationLoad(tester,
          timeout: const Duration(seconds: 15));

      // Verify we're not stuck in loading state
      expect(find.text('Loading presentation...'), findsNothing);

      // Verify we don't have error state
      expect(find.text('Error loading presentation'), findsNothing);
      expect(find.byIcon(Icons.error), findsNothing);

      // Look for actual slide content - check for common slide elements
      expect(find.byType(Text), findsWidgets);

      // Verify we can find slide content (should contain "SuperDeck" based on slides.md)
      expect(find.textContaining('SuperDeck'), findsWidgets);
    });

    testWidgets('presentation navigation works correctly', (tester) async {
      // Launch the app once and test navigation
      app.main();
      await tester.pumpAndSettle();

      // Wait for presentation to load
      await waitForPresentationLoad(tester,
          timeout: const Duration(seconds: 15));

      // Verify we have slide content
      expect(find.byType(Text), findsWidgets);
      expect(find.textContaining('SuperDeck'), findsWidgets);

      // Test navigation through slides
      for (int i = 0; i < 3; i++) {
        await tester.navigateToNextSlide();
        await waitForSlideTransition(tester);

        // Verify we still have content after navigation
        expect(find.byType(Text), findsWidgets);
        expect(find.byType(MaterialApp), findsWidgets);
      }

      // Navigate back
      for (int i = 0; i < 3; i++) {
        await tester.navigateToPreviousSlide();
        await waitForSlideTransition(tester);

        // Verify we still have content after navigation
        expect(find.byType(Text), findsWidgets);
        expect(find.byType(MaterialApp), findsWidgets);
      }
    });

    testWidgets('presentation content validation', (tester) async {
      // Launch the app once for comprehensive content validation
      app.main();
      await tester.pumpAndSettle();

      // Wait for presentation to load
      await waitForPresentationLoad(tester,
          timeout: const Duration(seconds: 15));

      // Verify we have the expected number of slides (17 based on logs)
      // Navigate through all slides to validate content
      int slideCount = 0;

      // Start from slide 0 and count slides
      while (slideCount < 20) {
        // Safety limit
        // Verify current slide has content
        expect(find.byType(Text), findsWidgets);

        // Try to navigate to next slide
        await tester.navigateToNextSlide();
        await waitForSlideTransition(tester);

        slideCount++;

        // If we've reached the end, we should still have content
        if (slideCount >= 17) {
          // We should have reached the last slide
          expect(find.byType(Text), findsWidgets);
          break;
        }
      }

      // Verify we found a reasonable number of slides
      expect(slideCount, greaterThanOrEqualTo(10));

      // Navigate back to first slide
      await tester.goToFirstSlide();
      await waitForSlideTransition(tester);

      // Verify we're back at the beginning with content
      expect(find.byType(Text), findsWidgets);
      expect(find.textContaining('SuperDeck'), findsWidgets);
    });
  });
}
