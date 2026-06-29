import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';
import 'keyboard_navigation_test.dart' as keyboard_navigation;
import 'layout_matrix_test.dart' as layout_matrix;
import 'live_reload_test.dart' as live_reload;
import 'navigation_test.dart' as navigation;
import 'plugin_visual_test.dart' as plugin_visual;
import 'slide_content_test.dart' as slide_content;
import 'startup_test.dart' as startup;
import 'ui_controls_test.dart' as ui_controls;

/// Single entry point for all integration tests.
///
/// macOS desktop integration tests can only launch one app instance per run.
/// This file aggregates all test suites so they share a single app lifecycle.
///
/// Individual test files can still be run standalone for focused debugging:
///   fvm flutter test integration_test/navigation_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TestApp.initialize();
  });

  startup.main();
  navigation.main();
  ui_controls.main();
  keyboard_navigation.main();
  slide_content.main();
  layout_matrix.main();
  live_reload.main();
  plugin_visual.main();
}
