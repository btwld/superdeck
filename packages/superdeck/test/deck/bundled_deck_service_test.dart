import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/bundled_deck_service.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledDeckService', () {
    test('watchBuildStatus is always empty', () async {
      final service = BundledDeckService(configuration: DeckConfiguration());

      final events = await service.watchBuildStatus().toList();

      expect(events, isEmpty);
    });

    test(
      'loadDeck returns error slide when bundled asset is missing',
      () async {
        final configuration = DeckConfiguration();
        final service = BundledDeckService(configuration: configuration);

        final deck = await service.loadDeck();

        expect(deck.slides, hasLength(1));
        expect(deck.slides.first.key, 'error');
        expect(
          (deck.slides.first.sections.first.blocks.first as ContentBlock)
              .content,
          contains(configuration.bundledDeckJsonPath),
        );
      },
    );
  });
}
