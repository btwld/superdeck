import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_ai/core/ai/schemas/deck_schemas.dart';
import 'package:superdeck_ai/core/utils/deck_style_service.dart';
import 'package:superdeck_ai/presentation/view/presentation_deck_host.dart';

void main() {
  setUp(() {
    DeckStyleService.clearCache();
  });

  tearDown(() {
    DeckStyleService.clearCache();
  });

  testWidgets('rebuilds deck options when style notifier changes', (
    tester,
  ) async {
    final seenOptions = <DeckOptions>[];

    await tester.pumpWidget(
      MaterialApp(
        home: PresentationDeckHost(
          deckAppBuilder: (options) {
            seenOptions.add(options);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(seenOptions, hasLength(1));
    expect(seenOptions.last.baseStyle, isNull);

    DeckStyleService.setStyle(DeckStyleType.parse(_styleMap()));
    await tester.pump();

    expect(seenOptions.length, greaterThan(1));
    expect(seenOptions.last.baseStyle, isNotNull);
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
