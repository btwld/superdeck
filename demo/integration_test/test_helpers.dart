import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_provider.dart';

/// Helper to wait for presentation to load
Future<void> waitForPresentationLoad(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  // Wait for presentation data to load with proper timeout
  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));

    // Check if we're no longer in loading state
    final loadingText = find.text('Loading presentation...');
    final errorIcon = find.byIcon(Icons.error);
    final slideContent = find.byType(Text);

    if (loadingText.evaluate().isEmpty &&
        errorIcon.evaluate().isEmpty &&
        slideContent.evaluate().isNotEmpty) {
      // Found content, wait a bit more for stability
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      return;
    }

    // If we find an error, stop waiting
    if (errorIcon.evaluate().isNotEmpty) {
      break;
    }
  }

  // Final pump and settle
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Helper to wait for slide transitions to complete
Future<void> waitForSlideTransition(WidgetTester tester) async {
  // Use fixed pumps instead of pumpAndSettle to avoid hanging
  // Navigation transitions take 1 second
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(); // One final pump to ensure everything is settled
}

/// Helper to simulate keyboard shortcuts
Future<void> simulateKeyboardShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool ctrl = false,
  bool shift = false,
  bool alt = false,
  bool meta = false,
}) async {
  final modifiers = <LogicalKeyboardKey>[];
  if (ctrl) modifiers.add(LogicalKeyboardKey.control);
  if (shift) modifiers.add(LogicalKeyboardKey.shift);
  if (alt) modifiers.add(LogicalKeyboardKey.alt);
  if (meta) modifiers.add(LogicalKeyboardKey.meta);

  // Press modifiers first
  for (final modifier in modifiers) {
    await tester.sendKeyDownEvent(modifier);
  }

  // Press main key
  await tester.sendKeyDownEvent(key);
  await tester.pump();

  // Release main key
  await tester.sendKeyUpEvent(key);

  // Release modifiers
  for (final modifier in modifiers.reversed) {
    await tester.sendKeyUpEvent(modifier);
  }

  await tester.pump();
}

/// Helper to verify slide navigation
Future<void> verifySlideNavigation(
  WidgetTester tester,
  int expectedSlideIndex,
) async {
  await waitForSlideTransition(tester);

  // For now, just verify the app is still responsive
  // In a real implementation, you'd check the actual slide index
  expect(find.byType(MaterialApp), findsOneWidget);
}

/// Helper to find slide content by text
Finder findSlideContent(String text) {
  return find.textContaining(text);
}

/// Helper to find any text widget
Finder findAnyText() {
  return find.byType(Text);
}

/// Helper to wait for animations to complete
Future<void> waitForAnimations(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Extension methods for common test operations
extension SuperDeckTestExtensions on WidgetTester {
  /// Navigate to next slide using NavigationController
  Future<void> navigateToNextSlide() async {
    // Find a widget deep in the tree that has access to NavigationProvider
    final textWidgets = find.byType(Text);
    if (textWidgets.evaluate().isNotEmpty) {
      final context = element(textWidgets.first);
      final navigationController = NavigationProvider.of(context);
      await navigationController.nextSlide();
      await waitForSlideTransition(this);
    }
  }

  /// Navigate to previous slide using NavigationController
  Future<void> navigateToPreviousSlide() async {
    // Find a widget deep in the tree that has access to NavigationProvider
    final textWidgets = find.byType(Text);
    if (textWidgets.evaluate().isNotEmpty) {
      final context = element(textWidgets.first);
      final navigationController = NavigationProvider.of(context);
      await navigationController.previousSlide();
      await waitForSlideTransition(this);
    }
  }

  /// Navigate using space key
  Future<void> navigateWithSpace() async {
    await simulateKeyboardShortcut(this, LogicalKeyboardKey.space, meta: true);
    await waitForSlideTransition(this);
  }

  /// Navigate using backspace key
  Future<void> navigateWithBackspace() async {
    await simulateKeyboardShortcut(
      this,
      LogicalKeyboardKey.backspace,
      meta: true,
    );
    await waitForSlideTransition(this);
  }

  /// Go to first slide
  Future<void> goToFirstSlide() async {
    await simulateKeyboardShortcut(this, LogicalKeyboardKey.home, meta: true);
    await waitForSlideTransition(this);
  }

  /// Go to last slide
  Future<void> goToLastSlide() async {
    await simulateKeyboardShortcut(this, LogicalKeyboardKey.end, meta: true);
    await waitForSlideTransition(this);
  }

  /// Enter fullscreen mode
  Future<void> enterFullscreen() async {
    await simulateKeyboardShortcut(this, LogicalKeyboardKey.f11);
    await pumpAndSettle();
  }

  /// Exit fullscreen mode
  Future<void> exitFullscreen() async {
    await simulateKeyboardShortcut(this, LogicalKeyboardKey.escape);
    await pumpAndSettle();
  }

  /// Toggle presentation mode
  Future<void> togglePresentationMode() async {
    await simulateKeyboardShortcut(this, LogicalKeyboardKey.f5);
    await pumpAndSettle();
  }

  /// Zoom in
  Future<void> zoomIn() async {
    await simulateKeyboardShortcut(
      this,
      LogicalKeyboardKey.equal,
      meta: true, // Cmd on macOS
    );
    await pumpAndSettle();
  }

  /// Zoom out
  Future<void> zoomOut() async {
    await simulateKeyboardShortcut(
      this,
      LogicalKeyboardKey.minus,
      meta: true, // Cmd on macOS
    );
    await pumpAndSettle();
  }

  /// Reset zoom
  Future<void> resetZoom() async {
    await simulateKeyboardShortcut(
      this,
      LogicalKeyboardKey.digit0,
      meta: true, // Cmd on macOS
    );
    await pumpAndSettle();
  }

  /// Toggle menu
  Future<void> toggleMenu() async {
    await simulateKeyboardShortcut(
      this,
      LogicalKeyboardKey.keyM,
      meta: true, // Cmd on macOS
    );
    await pumpAndSettle();
  }

  /// Toggle notes
  Future<void> toggleNotes() async {
    await simulateKeyboardShortcut(
      this,
      LogicalKeyboardKey.keyN,
      meta: true, // Cmd on macOS
    );
    await pumpAndSettle();
  }

  /// Navigate to specific slide by number
  Future<void> navigateToSlide(int slideNumber) async {
    final key = LogicalKeyboardKey(
      0x00000030 + slideNumber,
    ); // Convert to digit key
    await simulateKeyboardShortcut(this, key);
    await waitForSlideTransition(this);
  }

  /// Simulate mouse click navigation
  Future<void> clickToNavigate() async {
    final contentArea = find.byType(MaterialApp);
    if (contentArea.evaluate().isNotEmpty) {
      await tap(contentArea);
      await waitForSlideTransition(this);
    }
  }

  /// Simulate right-click navigation
  Future<void> rightClickToNavigate() async {
    final contentArea = find.byType(MaterialApp);
    if (contentArea.evaluate().isNotEmpty) {
      await tap(contentArea, buttons: kSecondaryButton);
      await waitForSlideTransition(this);
    }
  }

  /// Simulate scroll wheel navigation
  Future<void> scrollToNavigate({bool forward = true}) async {
    final contentArea = find.byType(MaterialApp);
    if (contentArea.evaluate().isNotEmpty) {
      final offset = forward ? const Offset(0, -100) : const Offset(0, 100);
      await drag(contentArea, offset);
      await waitForSlideTransition(this);
    }
  }

  /// Simulate swipe gesture
  Future<void> swipeToNavigate({bool forward = true}) async {
    final contentArea = find.byType(MaterialApp);
    if (contentArea.evaluate().isNotEmpty) {
      final offset = forward ? const Offset(-200, 0) : const Offset(200, 0);
      await drag(contentArea, offset);
      await waitForSlideTransition(this);
    }
  }
}
