import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/tools/deck_tools_runtime.dart';
import 'package:playground/features/ai/core/tools/deck_tools_schemas.dart';
import 'package:playground/features/ai/core/tools/deck_tools_service.dart';
import 'package:playground/features/ai/core/tools/in_memory_deck_store.dart';
import 'package:playground/utils/memory_deck_loader.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';

void main() {
  test('back-to-back mutations observe live DeckController state', () async {
    final loader = MemoryDeckLoader();
    final controller = DeckController(
      deckLoader: loader,
      options: DeckOptions(),
    );
    addTearDown(controller.dispose);

    final store = InMemoryDeckStore(
      loader: loader,
      slidesProvider: () => controller.slides.value
          .map((configuration) => configuration.slide)
          .toList(),
    );
    final runtime = DeckToolsRuntime(
      slideConfigurationsProvider: () => controller.slides.value,
      captureSlide: (_) async => throw StateError('capture not expected'),
      applyStyle: (_) {},
      isAvailable: () => true,
    );
    final service = DeckToolsService(documentStore: store, runtime: runtime);
    addTearDown(service.dispose);

    await store.writeCanonicalMarkdown('---\ntitle: Seed\n---\n\n# Seed\n');
    expect(controller.slides.value, hasLength(1));

    final first = service.createSlide(
      CreateSlideRequestType.parse({'slide': _deckToolSlide(title: 'First')}),
    );
    final second = service.createSlide(
      CreateSlideRequestType.parse({'slide': _deckToolSlide(title: 'Second')}),
    );

    await Future.wait([first, second]);

    final liveSlides = controller.slides.value
        .map((configuration) => configuration.slide)
        .toList();
    final canonical = const SlideSerializer().serialize(liveSlides);

    expect(liveSlides, hasLength(3));
    expect(canonical, contains('First'));
    expect(canonical, contains('Second'));
  });

  test(
    'raw markdown helper returns canonical markdown after live observation',
    () async {
      final loader = MemoryDeckLoader();
      final controller = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
      );
      addTearDown(controller.dispose);

      final store = InMemoryDeckStore(
        loader: loader,
        slidesProvider: () => controller.slides.value
            .map((configuration) => configuration.slide)
            .toList(),
      );

      final canonical = await store.writeCanonicalMarkdown(
        '---\ntitle: Intro\n---\n\n# Intro\n',
      );

      expect(controller.slides.value.single.slide.options?.title, 'Intro');
      expect(
        const SlideSerializer().serialize(
          controller.slides.value
              .map((configuration) => configuration.slide)
              .toList(),
        ),
        canonical,
      );
    },
  );
}

Map<String, Object?> _deckToolSlide({String title = 'Slide'}) {
  return {
    'options': {'title': title},
    'sections': [
      {
        'type': 'section',
        'blocks': [
          {'type': 'block', 'content': 'Body'},
        ],
      },
    ],
  };
}
