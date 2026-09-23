import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/features/ai/wizard/core/ui/components/sd_feedback.dart';

void main() {
  testWidgets('long status text wraps within a narrow callout', (tester) async {
    const message =
        'The presentation could not be exported because the destination is '
        'unavailable. Choose another location and try again.';

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            HeroTheme(data: HeroThemeData.dark(), child: child!),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: SdCallout(text: message, icon: Icons.error_outline),
            ),
          ),
        ),
      ),
    );

    expect(find.text(message), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(SdCallout)).height, greaterThan(60));
  });
}
