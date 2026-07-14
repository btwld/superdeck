import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_progress.dart';
import 'package:playground/features/ai/wizard/presentation/generation_progress_view.dart';

void main() {
  testWidgets('shows the current pipeline phase and completed steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            HeroTheme(data: HeroThemeData.light(), child: child!),
        home: const Scaffold(
          body: GenerationProgressView(
            phase: GenerationPhase.generatingFinalDeck,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Generating your presentation'), findsOneWidget);
    expect(find.text('Writing the slides…'), findsOneWidget);
    expect(find.text('Plan the outline'), findsOneWidget);
    expect(find.text('Write the slides'), findsOneWidget);
    expect(find.text('Finalize the deck'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  testWidgets('marks outline and slide writing complete while finalizing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            HeroTheme(data: HeroThemeData.light(), child: child!),
        home: const Scaffold(
          body: GenerationProgressView(phase: GenerationPhase.finalizing),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Finalizing…'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
  });
}
