import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_genui/src/ai/schemas/deck_schemas.dart';
import 'package:superdeck_genui/src/presentation/view/presentation_deck_host.dart';
import 'package:superdeck_genui/src/utils/deck_style_service.dart';

void main() {
  setUp(() {
    DeckStyleService.clearCache();
  });

  tearDown(() {
    DeckStyleService.clearCache();
  });

  testWidgets('does not rebuild app when presentation is unchanged', (
    tester,
  ) async {
    var buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PresentationDeckHost(
          config: const DeckConfig.bundle(),
          appBuilder: (theme) {
            buildCount++;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialCount = buildCount;

    // Pump without rebuilding the widget tree — signals unchanged,
    // so the Watch builder should not fire again.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(buildCount, equals(initialCount));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rebuilds deck presentation when style notifier changes', (
    tester,
  ) async {
    final seenThemes = <DeckTheme>[];

    await tester.pumpWidget(
      MaterialApp(
        home: PresentationDeckHost(
          config: const DeckConfig.bundle(),
          appBuilder: (theme) {
            seenThemes.add(theme);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(seenThemes, hasLength(1));
    expect(seenThemes.last.baseStyle, isNull);

    DeckStyleService.setStyle(DeckStyleType.parse(_styleMap()));
    await tester.pumpAndSettle();

    expect(seenThemes.length, greaterThan(1));
    expect(seenThemes.last.baseStyle, isNotNull);

    await tester.pumpWidget(const SizedBox());
  });
}

Map<String, Object?> _styleMap() {
  return {
    'name': 'Updated',
    'colors': {
      'background': '#FFFFFF',
      'heading': '#112233',
      'body': '#445566',
    },
    'fonts': {'headline': 'montserrat', 'body': 'openSans'},
  };
}
