import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/prompts/composition_example_library.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_element_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selects one relevant example and hydrates the exact planned source',
    () async {
      final library = AssetCompositionExampleLibrary();
      await library.load();
      final current = DeckPlanSlideType.parse(
        _planSlide(
          composition: 'imageRight',
          elements: const [
            {
              'type': 'image',
              'purpose': 'Show the supplied system map',
              'source': 'assets/exact-system-map.png',
            },
          ],
        ),
      );

      final example = library.buildFor(
        current: current,
        elementCatalog: GenerationElementCatalog.builtIn(),
      );
      final serialized = example.toString();

      expect(example['key'], current.key);
      expect(serialized, contains('assets/exact-system-map.png'));
      expect(serialized, contains('image'));
      expect(serialized, isNot(contains('__SOURCE__')));
      expect(serialized, isNot(contains('example.com')));
    },
  );

  test('provides a distinct template for every composition intent', () async {
    final library = AssetCompositionExampleLibrary();
    await library.load();

    expect(
      library.supportedCompositions,
      containsAll(deckPlanCompositionIntents),
    );
  });

  test('hydrates metric examples only from the current plan', () async {
    final library = AssetCompositionExampleLibrary();
    await library.load();
    final data = _planSlide(composition: 'metric');
    data['contentUnits'] = ['19% faster experiment decisions'];
    final current = DeckPlanSlideType.parse(data);

    final example = library.buildFor(
      current: current,
      elementCatalog: GenerationElementCatalog.builtIn(),
    );
    final serialized = example.toString();

    expect(serialized, contains('19%'));
    expect(serialized, isNot(contains('42%')));
    expect(serialized, isNot(contains('__PLANNED_METRIC__')));
  });

  test(
    'every selected example satisfies the model-facing slide schema',
    () async {
      final library = AssetCompositionExampleLibrary();
      await library.load();
      final elementCatalog = GenerationElementCatalog.builtIn();
      final schema = buildAiSlideSchema(
        widgetArgumentProperties: elementCatalog.argumentProperties,
        nestWidgetArguments: true,
      );

      for (final composition in deckPlanCompositionIntents) {
        final current = DeckPlanSlideType.parse(
          _planSlide(
            composition: composition,
            elements: _elementsFor(composition),
          ),
        );
        final example = library.buildFor(
          current: current,
          elementCatalog: elementCatalog,
        );

        expect(
          schema.safeParse(example).isOk,
          isTrue,
          reason: '$composition example must satisfy the generation schema',
        );
      }
    },
  );
}

List<Map<String, Object?>> _elementsFor(String composition) =>
    switch (composition) {
      'imageLeft' || 'imageRight' || 'imageFullBleed' => const [
        {
          'type': 'image',
          'purpose': 'Use the supplied visual',
          'source': 'assets/example.png',
        },
      ],
      'qrcode' => const [
        {
          'type': 'qrcode',
          'purpose': 'Continue to the supplied destination',
          'source': 'https://example.test/continue',
        },
      ],
      'webview' => const [
        {
          'type': 'webview',
          'purpose': 'Show the supplied live product',
          'source': 'https://example.test/product',
        },
      ],
      'dartpad' => const [
        {
          'type': 'dartpad',
          'purpose': 'Run the supplied DartPad example',
          'source': 'example-gist-id',
        },
      ],
      'custom' => const [
        {
          'type': 'custom',
          'purpose': 'Show an application-registered visual',
          'widgetName': 'brand-chart',
        },
      ],
      _ => const [],
    };

Map<String, Object?> _planSlide({
  required String composition,
  List<Map<String, Object?>> elements = const [],
}) => {
  'key': 'current-slide',
  'title': 'Current slide',
  'purpose': 'Advance the narrative.',
  'sectionKey': 'main',
  'assertion': 'The system is visible end to end.',
  'contentUnits': ['One evidence point', 'One implication'],
  'narrativeRole': 'insight',
  'contentBrief': 'Use the planned information clearly.',
  'continuity': 'Connect the surrounding ideas.',
  'composition': composition,
  'treatment': 'visual',
  'density': 'balanced',
  'elements': elements,
};
