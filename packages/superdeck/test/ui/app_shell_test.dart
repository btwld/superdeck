import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/ui/app_shell.dart';
import 'package:superdeck/src/ui/tokens/colors.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('AppShell', () {
    late _FakeDeckService deckService;
    late _SpyDeckController controller;

    setUp(() {
      deckService = _FakeDeckService(_buildDeck(slidesCount: 1));
      controller = _SpyDeckController(deckService: deckService);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('slide updates do not trigger thumbnail generation API', (
      tester,
    ) async {
      await tester.pumpWidget(
        MixScope(
          colors: SDColors.colorMap,
          child: MaterialApp(
            home: InheritedData<DeckController>(
              data: controller,
              child: const AppShell(child: SizedBox.shrink()),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.generateCalls, 0);

      deckService.deck = _buildDeck(slidesCount: 3);
      await controller.reloadDeck();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.generateCalls, 0);
    });
  });
}

class _FakeDeckService extends DeckService {
  Deck _deck;

  _FakeDeckService(this._deck) : super(configuration: DeckConfiguration());

  set deck(Deck value) => _deck = value;

  @override
  Future<Deck> loadDeck() async {
    return _deck;
  }
}

class _SpyDeckController extends DeckController {
  int generateCalls = 0;

  _SpyDeckController({required super.deckService})
    : super(options: const DeckOptions(), enableDeckStream: false);

  @override
  void generateThumbnails(BuildContext context, {bool force = false}) {
    generateCalls++;
    super.generateThumbnails(context, force: force);
  }
}

Deck _buildDeck({required int slidesCount}) {
  final slides = List.generate(
    slidesCount,
    (index) => Slide(
      key: 'slide-$index',
      sections: [
        SectionBlock([ContentBlock('Slide $index')]),
      ],
    ),
  );

  return Deck(slides: slides, configuration: DeckConfiguration());
}
