import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/features/ai/deck_editor/data/deck_slide_reader.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_tool_error.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('captures and describes one immutable live slide snapshot', (
    tester,
  ) async {
    final loader = MemoryDeckLoader();
    final cache = MemoryAssetCacheStore();
    final controller = DeckController(
      deckLoader: loader,
      options: DeckOptions(),
      assetCacheStore: cache,
    );
    addTearDown(controller.dispose);
    loader.updateMarkdown('---\ntitle: First\n---\n\n# First\n');
    await tester.pump();
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    SlideConfiguration? capturedSlide;
    SlideCaptureQuality? capturedQuality;
    final reader = DeckSlideReader(
      context: context,
      deckController: controller,
      capture: ({required context, required quality, required slide}) async {
        capturedSlide = slide;
        capturedQuality = quality;
        return Uint8List.fromList([137, 80, 78, 71]);
      },
    );

    final result = await reader.read(0);

    expect(capturedSlide, same(controller.slides.value.single));
    expect(capturedSlide?.assetCacheStore, same(cache));
    expect(capturedQuality, SlideCaptureQuality.thumbnail);
    expect(result['index'], 0);
    expect(result['title'], 'First');
    expect(result['thumbnailBase64'], 'iVBORw==');
    expect((result['slide'] as Map), isNot(contains('key')));
    expect((result['deck'] as Map)['totalSlides'], 1);
  });

  testWidgets('unmounted context maps to context_unavailable', (tester) async {
    final harness = await _ReaderHarness.create(tester);
    addTearDown(harness.dispose);
    var captured = false;
    final reader = DeckSlideReader(
      context: harness.context,
      deckController: harness.controller,
      capture: ({required context, required quality, required slide}) async {
        captured = true;
        return Uint8List(1);
      },
    );
    await tester.pumpWidget(const SizedBox());

    await expectLater(
      reader.read(0),
      throwsA(
        isA<DeckToolError>().having(
          (error) => error.code,
          'code',
          DeckToolErrorCode.contextUnavailable,
        ),
      ),
    );
    expect(captured, isFalse);
  });

  testWidgets('render failures map to capture_failed', (tester) async {
    final harness = await _ReaderHarness.create(tester);
    addTearDown(harness.dispose);
    final reader = DeckSlideReader(
      context: harness.context,
      deckController: harness.controller,
      capture: ({required context, required quality, required slide}) async {
        throw StateError('render failed');
      },
    );

    await expectLater(
      reader.read(0),
      throwsA(
        isA<DeckToolError>().having(
          (error) => error.code,
          'code',
          DeckToolErrorCode.captureFailed,
        ),
      ),
    );
  });
}

class _ReaderHarness {
  _ReaderHarness._({required this.context, required this.controller});

  final BuildContext context;
  final DeckController controller;

  static Future<_ReaderHarness> create(WidgetTester tester) async {
    final loader = MemoryDeckLoader();
    final controller = DeckController(
      deckLoader: loader,
      options: DeckOptions(),
    );
    loader.updateMarkdown('# Slide');
    await tester.pump();
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    return _ReaderHarness._(context: context, controller: controller);
  }

  void dispose() => controller.dispose();
}
