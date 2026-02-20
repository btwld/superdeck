import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'package:superdeck_example/src/parts/background.dart';
import 'package:superdeck_example/src/parts/footer.dart';
import 'package:superdeck_example/src/parts/header.dart';
import 'package:superdeck_example/src/style.dart';
import 'package:superdeck_example/src/templates.dart';
import 'package:superdeck_example/src/widgets/demo_widgets.dart';

/// Test app widget that mirrors the production app configuration.
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  /// Initializes dependencies for testing.
  ///
  /// Should be called in setUpAll() before any tests run.
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    SignalsObserver.instance = null;
    WidgetsBinding.instance.ensureSemantics();
    await SuperDeckApp.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return SuperDeckApp(
      options: DeckOptions(
        baseStyle: borderedStyle(),
        widgets: demoWidgets,
        styles: {'announcement': announcementStyle(), 'quote': quoteStyle()},
        templates: {
          'corporate': corporateTemplate(),
          'minimal': minimalTemplate(),
        },
        parts: const SlideParts(
          header: HeaderPart(),
          footer: FooterPart(),
          background: BackgroundPart(),
        ),
        // Integration tests validate runtime behavior, not live file watching.
        watchForChanges: false,
      ),
    );
  }
}

/// Finds the DeckController from the widget tree.
///
/// Returns null if the controller cannot be found.
DeckController? findDeckController(WidgetTester tester) {
  try {
    final scaffoldFinder = find.byType(Scaffold);
    if (scaffoldFinder.evaluate().isEmpty) return null;

    final element = tester.element(scaffoldFinder.first);
    return DeckController.of(element);
  } catch (e) {
    return null;
  }
}

/// Extension on WidgetTester for common integration test operations.
extension IntegrationTestExtensions on WidgetTester {
  /// Pumps frames for a bounded amount of test time.
  Future<void> pumpFor(
    Duration duration, {
    Duration step = const Duration(milliseconds: 50),
  }) async {
    final steps = duration.inMicroseconds ~/ step.inMicroseconds;
    for (var i = 0; i < steps; i++) {
      await pump(step);
    }
  }

  /// Pumps until [condition] is true or [timeout] is reached.
  Future<void> pumpUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration step = const Duration(milliseconds: 50),
    String debugLabel = 'condition',
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (condition()) {
        return;
      }
      await pump(step);
    }

    fail('Timed out waiting for $debugLabel after ${timeout.inSeconds}s');
  }

  /// Pumps the test app and waits for it to fully load.
  ///
  /// Returns the DeckController for further assertions.
  Future<DeckController?> pumpTestApp() async {
    await pumpWidget(const TestApp());
    await pumpFor(const Duration(milliseconds: 200));

    final controller = findDeckController(this);
    if (controller == null) {
      return null;
    }

    await waitForSlidesLoaded(controller);
    return controller;
  }

  /// Waits for the app to finish loading slides.
  Future<void> waitForSlidesLoaded(DeckController controller) async {
    await pumpUntil(
      () => !controller.isLoading.value,
      timeout: const Duration(seconds: 20),
      debugLabel: 'slides to finish loading',
    );

    if (controller.hasError.value) {
      fail('Deck failed to load: ${controller.error.value}');
    }

    await pumpFor(const Duration(milliseconds: 200));
  }

  /// Navigates to a specific slide and waits for transition to complete.
  Future<void> navigateToSlide(DeckController controller, int index) async {
    await controller.goToSlide(index);
    await pumpUntil(
      () => controller.currentIndex.value == index,
      timeout: const Duration(seconds: 5),
      debugLabel: 'navigation to slide $index',
    );
    await pumpFor(const Duration(milliseconds: 200));
  }
}
