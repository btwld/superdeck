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

SuperDeckRuntime? _runtime;

String describeDeckState(SuperDeckHandle? handle) {
  if (handle == null) {
    return 'SuperDeckHandle: null';
  }

  return [
    'SuperDeckHandle state:',
    '  isLoading=${handle.isLoading.value}',
    '  hasError=${handle.hasError.value}',
    '  error=${handle.error.value}',
    '  totalSlides=${handle.totalSlides.value}',
    '  currentIndex=${handle.currentIndex.value}',
    '  isMenuOpen=${handle.isMenuOpen.value}',
    '  isNotesOpen=${handle.isNotesOpen.value}',
  ].join('\n');
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
    _runtime = await SuperDeckRuntime.create(
      config: const DeckConfig.local(
        slidesPath: 'slides.md',
        watch: false,
        projectDir: '.',
        outputDir: '.superdeck',
        assetsPath: 'assets',
      ),
      theme: DeckTheme(
        baseStyle: borderedStyle(),
        widgets: demoWidgets,
        styles: {'announcement': announcementStyle(), 'quote': quoteStyle()},
        templates: {
          'corporate': corporateTemplate(),
          'minimal': minimalTemplate(),
        },
        frame: const SlideFrame(
          header: HeaderPart(),
          footer: FooterPart(),
          background: BackgroundPart(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runtime = _runtime;
    if (runtime == null) {
      throw StateError('Test runtime was not initialized');
    }
    return SuperDeckApp(runtime: runtime);
  }
}

/// Finds the SuperDeckHandle from the widget tree.
///
/// Returns null if the handle cannot be found.
SuperDeckHandle? findDeckHandle(WidgetTester tester) {
  try {
    final scaffoldFinder = find.byType(Scaffold);
    if (scaffoldFinder.evaluate().isEmpty) return null;

    final element = tester.element(scaffoldFinder.first);
    return SuperDeck.of(element);
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

  /// Pumps the test app and waits for it to fully load.
  ///
  /// Returns the SuperDeckHandle for further assertions.
  Future<SuperDeckHandle?> pumpTestApp() async {
    await pumpWidget(const TestApp());
    await pumpFor(const Duration(milliseconds: 200));

    await pumpUntil(
      () => findDeckHandle(this) != null,
      timeout: const Duration(seconds: 15),
      debugLabel: 'SuperDeckHandle to mount',
      onTimeout: () => _startupDiagnostics(),
    );

    final controller = findDeckHandle(this);
    expect(
      controller,
      isNotNull,
      reason:
          'SuperDeckHandle was not found after startup.\n'
          'Diagnostics:\n${_startupDiagnostics()}',
    );
    if (controller == null) return null;

    await waitForSlidesLoaded(controller);
    return controller;
  }

  /// Waits for the app to finish loading slides.
  Future<void> waitForSlidesLoaded(SuperDeckHandle controller) async {
    await pumpUntil(
      () => !controller.isLoading.value,
      timeout: const Duration(seconds: 20),
      debugLabel: 'slides to finish loading',
      onTimeout: () => describeDeckState(controller),
    );

    if (controller.hasError.value) {
      fail(
        'Deck failed to load: ${controller.error.value}\n'
        '${describeDeckState(controller)}',
      );
    }

    await pumpFor(const Duration(milliseconds: 200));
  }

  /// Navigates to a specific slide and waits for transition to complete.
  Future<void> navigateToSlide(SuperDeckHandle controller, int index) async {
    await controller.goToSlide(index);
    await pumpUntil(
      () => controller.currentIndex.value == index,
      timeout: const Duration(seconds: 5),
      debugLabel: 'navigation to slide $index',
      onTimeout: () => describeDeckState(controller),
    );
    await pumpFor(const Duration(milliseconds: 200));
  }

  String _startupDiagnostics() {
    final controller = findDeckHandle(this);
    return [
      describeDeckState(controller),
      'Scaffold count=${find.byType(Scaffold).evaluate().length}',
      'Error text count=${find.textContaining('Error loading presentation').evaluate().length}',
    ].join('\n');
  }
}
