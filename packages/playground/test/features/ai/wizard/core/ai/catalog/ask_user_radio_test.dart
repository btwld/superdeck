import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_question_cards.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_radio.dart';

void main() {
  testWidgets('radio option cards in a row share the tallest card height', (
    tester,
  ) async {
    final catalog = Catalog([askUserRadio]);
    final data = _radioData(
      question: 'What other angles would be effective?',
      options: ['Monitoring', 'Comparative analysis', 'Future projections'],
      descriptions: [
        'A short description.',
        'Benchmarking conservation outcomes across regions with enough detail '
            'to wrap onto several lines in the option card.',
        'Brief outlook.',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: Builder(
              builder: (context) =>
                  catalog.buildWidget(_itemContext(context, data)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(RadioOptionCard);
    expect(cards, findsNWidgets(3));
    final heights = [
      for (var index = 0; index < 3; index++)
        tester.getSize(cards.at(index)).height,
    ];

    expect(heights.toSet(), hasLength(1));
  });

  testWidgets('selection resets when the radio question changes', (
    tester,
  ) async {
    final catalog = Catalog([askUserRadio]);
    var data = _radioData(
      question: 'Who is the audience?',
      options: ['Leaders', 'Practitioners', 'Advocates'],
    );
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return catalog.buildWidget(_itemContext(context, data));
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Advocates'));
    await tester.pumpAndSettle();
    expect(_canContinue(tester), isTrue);

    rebuild(() {
      data = _radioData(
        question: 'What is the approach?',
        options: ['Evidence', 'Storytelling', 'Call to action'],
      );
    });
    await tester.pumpAndSettle();

    expect(_canContinue(tester), isFalse);
  });
}

CatalogItemContext _itemContext(
  BuildContext context,
  Map<String, Object?> data,
) => CatalogItemContext(
  data: data,
  id: 'root',
  type: 'AskUserRadio',
  buildChild: (_, [_]) => const SizedBox.shrink(),
  dispatchEvent: (_) {},
  buildContext: context,
  dataContext: DataContext(InMemoryDataModel(), DataPath.root),
  getComponent: (_) => null,
  getCatalogItem: (_) => null,
  surfaceId: 'wizard',
  reportError: (_, _) {},
);

Map<String, Object?> _radioData({
  required String question,
  required List<String> options,
  List<String>? descriptions,
}) => {
  'question': question,
  'options': [
    for (final (index, title) in options.indexed)
      {
        'title': title,
        if (descriptions != null) 'description': descriptions[index],
      },
  ],
  'action': {'name': 'submit_answer', 'context': <Object?>[]},
};

bool _canContinue(WidgetTester tester) {
  final button = tester.widget<HeroButton>(
    find.widgetWithText(HeroButton, 'Continue'),
  );
  return button.onPressed != null;
}
