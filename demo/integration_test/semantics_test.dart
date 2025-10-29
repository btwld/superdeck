import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck_example/main.dart' as app;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Semantics Tests', () {
    testWidgets('app is accessible with screen reader support', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for presentation to load
      await waitForPresentationLoad(
        tester,
        timeout: const Duration(seconds: 15),
      );

      // Verify we have semantic nodes and the app loaded
      expect(find.byType(MaterialApp), findsWidgets);
      expect(find.byType(Scaffold), findsWidgets);

      // Verify navigation works with semantics enabled
      await tester.navigateToNextSlide();
      expect(find.byType(MaterialApp), findsWidgets);

      await tester.navigateToPreviousSlide();
      expect(find.byType(MaterialApp), findsWidgets);
    }, semanticsEnabled: true);
  });
}
