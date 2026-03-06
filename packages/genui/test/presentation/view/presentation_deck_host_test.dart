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

  testWidgets('rebuilds deck presentation when style notifier changes', (
    tester,
  ) async {
    final seenRuntimes = <SuperDeckRuntime>[];

    await tester.pumpWidget(
      MaterialApp(
        home: PresentationDeckHost(
          deckAppBuilder: (runtime) {
            seenRuntimes.add(runtime);
            return const SizedBox.shrink();
          },
          runtimeLoader: (presentation) async =>
              SuperDeckRuntime.forTesting(presentation: presentation),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(seenRuntimes, hasLength(1));
    expect(seenRuntimes.last.presentation.baseStyle, isNull);

    DeckStyleService.setStyle(DeckStyleType.parse(_styleMap()));
    await tester.pumpAndSettle();

    expect(seenRuntimes.length, greaterThan(1));
    expect(seenRuntimes.last.presentation.baseStyle, isNotNull);
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
