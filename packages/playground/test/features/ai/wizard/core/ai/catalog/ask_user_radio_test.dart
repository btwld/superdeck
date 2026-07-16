import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_radio.dart';

void main() {
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
}) => {
  'question': question,
  'options': [
    for (final title in options) {'title': title},
  ],
  'action': {'name': 'submit_answer', 'context': <Object?>[]},
};

bool _canContinue(WidgetTester tester) {
  final button = tester.widget<HeroButton>(
    find.widgetWithText(HeroButton, 'Continue'),
  );
  return button.onPressed != null;
}
