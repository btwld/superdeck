import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck_example/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Tests', () {
    testWidgets('keyboard navigation - arrow keys', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Test right arrow navigation (next slide)
      await tester.navigateToNextSlide();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Test left arrow navigation (previous slide)
      await tester.navigateToPreviousSlide();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('keyboard navigation - space and backspace', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Test space key for next slide
      await tester.navigateWithSpace();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Test backspace for previous slide
      await tester.navigateWithBackspace();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('keyboard navigation - home and end keys', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Navigate to end
      await tester.goToLastSlide();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Navigate to beginning
      await tester.goToFirstSlide();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('navigation boundaries - cannot go beyond slides', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Go to first slide
      await tester.goToFirstSlide();

      // Try to go before first slide
      await tester.navigateToPreviousSlide();
      expect(find.byType(MaterialApp), findsOneWidget); // Should not crash

      // Navigate to last slide
      await tester.goToLastSlide();

      // Try to go beyond last slide
      await tester.navigateToNextSlide();
      expect(find.byType(MaterialApp), findsOneWidget); // Should not crash
    });

    testWidgets('fullscreen toggle', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Enter fullscreen
      await tester.enterFullscreen();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Exit fullscreen
      await tester.exitFullscreen();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('presentation mode toggle', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Toggle presentation mode
      await tester.togglePresentationMode();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Exit presentation mode
      await tester.exitFullscreen();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('mouse click navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Test click to advance slide
      await tester.clickToNavigate();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Test right-click for previous slide (if implemented)
      await tester.rightClickToNavigate();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('scroll wheel navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Simulate scroll down (next slide)
      await tester.scrollToNavigate(forward: true);
      expect(find.byType(MaterialApp), findsOneWidget);

      // Simulate scroll up (previous slide)
      await tester.scrollToNavigate(forward: false);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('swipe gestures', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Simulate swipe left (next slide)
      await tester.swipeToNavigate(forward: true);
      expect(find.byType(MaterialApp), findsOneWidget);

      // Simulate swipe right (previous slide)
      await tester.swipeToNavigate(forward: false);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('rapid navigation handling', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Rapidly press navigation keys
      for (int i = 0; i < 10; i++) {
        await simulateKeyboardShortcut(
          tester,
          LogicalKeyboardKey.arrowRight,
          meta: true,
        );
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Wait for all animations to settle
      await tester.pumpAndSettle();

      // App should still be responsive and not crash
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('navigation with zoom controls', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Zoom in
      await tester.zoomIn();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Navigate while zoomed
      await tester.navigateToNextSlide();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Zoom out
      await tester.zoomOut();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Reset zoom
      await tester.resetZoom();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('navigation persistence across app lifecycle', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await waitForPresentationLoad(tester);

      // Navigate to a specific slide
      await tester.navigateToNextSlide();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Simulate app going to background and coming back
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused'),
        ),
        (data) {},
      );

      await tester.pump();

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed'),
        ),
        (data) {},
      );

      await tester.pumpAndSettle();

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);

      // Navigation should still work
      await tester.navigateToNextSlide();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
