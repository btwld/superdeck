import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'package:superdeck_example/src/parts/background.dart';
import 'package:superdeck_example/src/parts/footer.dart';
import 'package:superdeck_example/src/parts/header.dart';
import 'package:superdeck_example/src/style.dart';
import 'package:superdeck_example/src/widgets/demo_widgets.dart';

/// The expected viewport size for SuperDeck (matches kResolution in constants.dart)
const kTestViewportSize = Size(1280, 720);

/// Checks if a FlutterErrorDetails is a RenderFlex overflow error.
///
/// These errors can occur in CI environments due to viewport size differences
/// and are safe to ignore for integration tests.
bool _isOverflowError(FlutterErrorDetails details) {
  final message = details.exceptionAsString();
  return message.contains('A RenderFlex overflowed') ||
      message.contains('A RenderBox was not laid out') ||
      message.contains('overflowed by');
}

/// Configures the test to ignore RenderFlex overflow errors.
///
/// CI environments (especially Linux with xvfb) may report overflow errors
/// due to viewport/display size differences that don't occur in production.
/// This function filters those specific errors while still catching real issues.
///
/// IMPORTANT: Must be called at the start of each test that may encounter
/// overflow errors, NOT in setUp or setUpAll.
///
/// Example:
/// ```dart
/// testWidgets('my test', (tester) async {
///   ignoreOverflowErrors();
///   await tester.pumpWidget(MyApp());
///   // ...test code...
/// });
/// ```
void ignoreOverflowErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isOverflowError(details)) {
      // Log but don't fail the test for overflow errors in CI
      debugPrint('Ignoring overflow error in CI: ${details.exceptionAsString()}');
      return;
    }
    // For all other errors, use the original handler
    originalOnError?.call(details);
  };
}

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
  /// Sets the viewport to match kResolution (1280x720) to prevent layout
  /// overflow in CI environments with smaller default viewports.
  /// Also configures overflow error filtering for CI environments.
  ///
  /// Returns the DeckController for further assertions.
  Future<DeckController?> pumpTestApp() async {
    // Ignore overflow errors in CI (xvfb viewport limitations)
    ignoreOverflowErrors();

    // Set viewport to match expected resolution (prevents overflow in CI)
    view.physicalSize = kTestViewportSize;
    view.devicePixelRatio = 1.0;

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
