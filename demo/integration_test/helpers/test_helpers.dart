import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'package:superdeck_example/src/parts/background.dart';
import 'package:superdeck_example/src/parts/footer.dart';
import 'package:superdeck_example/src/parts/header.dart';
import 'package:superdeck_example/src/style.dart';
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
        styles: {
          'announcement': announcementStyle(),
          'quote': quoteStyle(),
        },
        parts: const SlideParts(
          header: HeaderPart(),
          footer: FooterPart(),
          background: BackgroundPart(),
        ),
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
  /// Pumps the test app and waits for it to fully load.
  ///
  /// Returns the DeckController for further assertions.
  Future<DeckController?> pumpTestApp() async {
    await pumpWidget(const TestApp());
    await pumpAndSettle(const Duration(seconds: 5));
    return findDeckController(this);
  }

  /// Waits for the app to finish loading slides.
  Future<void> waitForSlidesLoaded(DeckController controller) async {
    while (controller.isLoading.value) {
      await pump(const Duration(milliseconds: 100));
    }
    await pumpAndSettle();
  }

  /// Navigates to a specific slide and waits for transition to complete.
  Future<void> navigateToSlide(DeckController controller, int index) async {
    await controller.goToSlide(index);
    await pumpAndSettle(const Duration(seconds: 2));
  }
}
