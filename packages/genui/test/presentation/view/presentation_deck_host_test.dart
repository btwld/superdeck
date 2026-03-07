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

  testWidgets('does not recreate runtime when presentation is unchanged', (
    tester,
  ) async {
    var loadCount = 0;

    Future<SuperDeckRuntime> loadRuntime(DeckTheme theme) async {
      loadCount++;
      return SuperDeckRuntime.forTesting(theme: theme);
    }

    Widget buildHost() {
      return MaterialApp(
        home: PresentationDeckHost(
          deckAppBuilder: (_) => const SizedBox.shrink(),
          runtimeLoader: loadRuntime,
        ),
      );
    }

    await tester.pumpWidget(buildHost());
    await tester.pumpAndSettle();

    expect(loadCount, equals(1));

    await tester.pumpWidget(buildHost());
    await tester.pumpAndSettle();

    expect(loadCount, equals(1));
  });

  testWidgets('rebuilds deck presentation when style notifier changes', (
    tester,
  ) async {
    final seenRuntimes = <SuperDeckRuntime>[];
    var loadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PresentationDeckHost(
          deckAppBuilder: (runtime) {
            seenRuntimes.add(runtime);
            return const SizedBox.shrink();
          },
          runtimeLoader: (theme) async {
            loadCount++;
            return SuperDeckRuntime.forTesting(theme: theme);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(seenRuntimes, hasLength(1));
    expect(loadCount, equals(1));
    expect(seenRuntimes.last.theme.baseStyle, isNull);

    DeckStyleService.setStyle(DeckStyleType.parse(_styleMap()));
    await tester.pumpAndSettle();

    expect(seenRuntimes.length, greaterThan(1));
    expect(loadCount, equals(2));
    expect(seenRuntimes.last.theme.baseStyle, isNotNull);
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
