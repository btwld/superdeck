import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

class _InMemoryDeckLoader extends DeckLoader {
  const _InMemoryDeckLoader(this.slides);

  final List<Slide> slides;

  @override
  Stream<SlidesEvent> load() => Stream<SlidesEvent>.value(
    SlidesLoadedEvent(List<Slide>.unmodifiable(slides)),
  );

  @override
  Future<void> reload() async {}

  @override
  Future<void> dispose() async {}
}

Future<List<SlideConfiguration>> buildRuntimeSlideConfigurations({
  required List<Slide> slides,
  required DeckOptions options,
}) async {
  if (slides.isEmpty) return const <SlideConfiguration>[];

  final controller = DeckController(
    deckLoader: _InMemoryDeckLoader(slides),
    options: options,
  );

  try {
    for (var attempt = 0; attempt < 4; attempt++) {
      await Future<void>.value();
      final configurations = controller.slides.value;
      if (configurations.length == slides.length) {
        return List<SlideConfiguration>.unmodifiable(configurations);
      }
    }
    return List<SlideConfiguration>.unmodifiable(controller.slides.value);
  } finally {
    controller.dispose();
  }
}
