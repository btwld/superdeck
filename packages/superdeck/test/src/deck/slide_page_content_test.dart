import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/deck/slide_page_content.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';

import '../../helpers/mock_deck_loader.dart';

void main() {
  testWidgets('empty state is generic and does not mention builder paths', (
    tester,
  ) async {
    final loader = MockDeckLoader(slides: const []);
    final controller = DeckController(
      deckLoader: loader,
      options: DeckOptions(),
    );

    addTearDown(() async {
      controller.dispose();
      await loader.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: InheritedData(
          data: controller,
          child: const SlidePageContent(index: 0),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('No slides available'), findsOneWidget);
    expect(
      find.text("This presentation doesn't have any slides to show yet."),
      findsOneWidget,
    );
    expect(find.textContaining('slides.md'), findsNothing);
    expect(find.textContaining('rebuild'), findsNothing);
  });
}
