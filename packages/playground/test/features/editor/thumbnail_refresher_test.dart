import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/features/editor/thumbnail_refresher.dart';
import 'package:playground/stores/editor_state.dart';
import 'package:playground/utils/memory_deck_loader.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

const _twoSlides = '# Slide one\n\n---\n\n# Slide two';

void main() {
  // Keep deck building offline: never fetch fonts over the network in tests.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late MemoryDeckLoader loader;
  late DeckController controller;
  late EditorState editorState;
  late List<bool> forceCalls;

  setUp(() {
    loader = MemoryDeckLoader();
    controller = DeckController(deckLoader: loader, options: DeckOptions());
    editorState = EditorState();
    forceCalls = <bool>[];
  });

  tearDown(() async {
    controller.dispose();
    editorState.dispose();
    await loader.dispose();
  });

  // Records the `force` flag of every regeneration the refresher requests.
  void record(
    BuildContext context,
    List<SlideConfiguration> slides, {
    bool force = false,
  }) {
    forceCalls.add(force);
  }

  Future<void> pumpRefresher(WidgetTester tester) {
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DeckController>.value(value: controller),
          Provider<EditorState>.value(value: editorState),
        ],
        child: ThumbnailRefresher(
          regenerate: record,
          child: const SizedBox(),
        ),
      ),
    );
  }

  // Runs the refresher's pending post-frame regeneration. `addPostFrameCallback`
  // never schedules a frame, so an isolated test must request one itself.
  Future<void> settle(WidgetTester tester) async {
    tester.binding.scheduleFrame();
    await tester.pump();
  }

  // Delivers the SlidesLoadedEvent, then runs the initial regeneration.
  Future<void> loadDeck(WidgetTester tester) async {
    loader.updateMarkdown(_twoSlides);
    await tester.pump(); // deliver the event; the effect schedules a pass
    await settle(tester);
  }

  testWidgets('does not regenerate before the deck has slides', (
    tester,
  ) async {
    await pumpRefresher(tester);
    await settle(tester);

    expect(forceCalls, isEmpty);
  });

  testWidgets('initial deck load regenerates without force', (tester) async {
    await pumpRefresher(tester);
    await loadDeck(tester);

    expect(forceCalls, [false]);
  });

  testWidgets('a style change force-regenerates every thumbnail', (
    tester,
  ) async {
    await pumpRefresher(tester);
    await loadDeck(tester);
    expect(forceCalls, [false]);

    controller.options.value = DeckOptions(debug: true);
    await settle(tester);

    expect(forceCalls, [false, true]);
  });

  testWidgets('style changes within one frame coalesce into one pass', (
    tester,
  ) async {
    await pumpRefresher(tester);
    await loadDeck(tester);
    expect(forceCalls, [false]);

    // Three option writes before the next frame collapse to a single pass.
    controller.options.value = DeckOptions(debug: true);
    controller.options.value = DeckOptions(debug: false);
    controller.options.value = DeckOptions(debug: true);
    await settle(tester);

    expect(forceCalls, [false, true]);
  });

  testWidgets('a style change before the deck loads is ignored', (
    tester,
  ) async {
    await pumpRefresher(tester);

    // No slides yet: the options effect must not request a pass.
    controller.options.value = DeckOptions(debug: true);
    await settle(tester);
    expect(forceCalls, isEmpty);

    // The deck then loads and captures once with the current options.
    await loadDeck(tester);
    expect(forceCalls, [false]);
  });
}
