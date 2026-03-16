import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'package:superdeck_example/src/parts/background.dart';
import 'package:superdeck_example/src/parts/footer.dart';
import 'package:superdeck_example/src/parts/header.dart';
import 'package:superdeck_example/src/style.dart';
import 'package:superdeck_example/src/templates.dart';
import 'package:superdeck_example/src/widgets/demo_widgets.dart';

final _renderOverflowPattern = RegExp(r'A Render\w+ overflowed by');

void assertOnlyLayoutOverflowOrNoException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) return;

  final message = exception.toString();
  if (_renderOverflowPattern.hasMatch(message)) {
    debugPrint('[Integration Test] Layout overflow accepted: $message');
    return;
  }

  fail('Unexpected exception: $exception');
}

String describeDeckControllerState(DeckController? controller) {
  if (controller == null) {
    return 'DeckController: null';
  }

  return [
    'DeckController state:',
    '  isLoading=${controller.isLoading.value}',
    '  hasError=${controller.hasError.value}',
    '  error=${controller.error.value}',
    '  totalSlides=${controller.totalSlides.value}',
    '  currentIndex=${controller.currentIndex.value}',
    '  isMenuOpen=${controller.isMenuOpen.value}',
    '  isNotesOpen=${controller.isNotesOpen.value}',
  ].join('\n');
}

/// Returns the smaller of [target] and [controller.totalSlides - 1].
int clampSlideIndex(DeckController controller, int target) {
  return math.min(target, controller.totalSlides.value - 1);
}

/// Test app widget that mirrors the production app configuration.
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  static bool _initialized = false;

  /// Initializes dependencies for testing. Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
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
    String Function()? onTimeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (condition()) {
        return;
      }
      await pump(step);
    }

    final diagnostics = onTimeout?.call();
    if (diagnostics == null || diagnostics.isEmpty) {
      fail('Timed out waiting for $debugLabel after ${timeout.inSeconds}s');
    }

    fail(
      'Timed out waiting for $debugLabel after ${timeout.inSeconds}s\n'
      'Diagnostics:\n$diagnostics',
    );
  }

  /// Pumps the test app, waits for it to fully load, and returns the controller.
  ///
  /// Fails the test if the controller cannot be found or slides fail to load.
  Future<DeckController> pumpTestApp() async {
    await pumpWidget(const TestApp());
    await pumpFor(const Duration(milliseconds: 200));

    await pumpUntil(
      () => findDeckController(this) != null,
      timeout: const Duration(seconds: 15),
      debugLabel: 'DeckController to mount',
      onTimeout: () => _startupDiagnostics(),
    );

    final controller = findDeckController(this)!;
    await waitForSlidesLoaded(controller);
    return controller;
  }

  /// Waits for the app to finish loading slides.
  Future<void> waitForSlidesLoaded(DeckController controller) async {
    await pumpUntil(
      () => !controller.isLoading.value,
      timeout: const Duration(seconds: 20),
      debugLabel: 'slides to finish loading',
      onTimeout: () => describeDeckControllerState(controller),
    );

    if (controller.hasError.value) {
      fail(
        'Presentation failed to load: ${controller.error.value}\n'
        '${describeDeckControllerState(controller)}',
      );
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
      onTimeout: () => describeDeckControllerState(controller),
    );
    await pumpFor(const Duration(milliseconds: 200));
  }

  /// Taps a widget found by [finder], scrolling it into view first if needed.
  /// Uses `warnIfMissed: false` to handle edge-of-screen widgets (e.g. bottom bar).
  Future<void> tapByLabel(String label) async {
    final finder = find.bySemanticsLabel(label);
    expect(
      finder,
      findsWidgets,
      reason: 'Could not find widget with label "$label"',
    );
    await ensureVisible(finder.first);
    await pumpFor(const Duration(milliseconds: 100));
    await tap(finder.first, warnIfMissed: false);
  }

  Future<void> sendMetaKey(LogicalKeyboardKey key) async {
    await sendKeyDownEvent(LogicalKeyboardKey.meta);
    await sendKeyDownEvent(key);
    await sendKeyUpEvent(key);
    await sendKeyUpEvent(LogicalKeyboardKey.meta);
    await pumpFor(const Duration(milliseconds: 200));
  }

  String _startupDiagnostics() {
    final controller = findDeckController(this);
    return [
      describeDeckControllerState(controller),
      'Scaffold count=${find.byType(Scaffold).evaluate().length}',
      'Error text count=${find.textContaining('Error loading presentation').evaluate().length}',
    ].join('\n');
  }
}
