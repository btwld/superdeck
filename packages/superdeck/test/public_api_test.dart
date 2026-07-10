import 'package:superdeck/superdeck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('superdeck public api', () {
    test('exports the supported app surface', () {
      expect(SuperDeckApp, isNotNull);
      expect(SlideConfiguration, isNotNull);
      expect(SlideCaptureService, isNotNull);
      expect(SlideCaptureQuality, isNotNull);
      expect(SlideRenderView, isNotNull);
      expect(AsyncThumbnail, isNotNull);
      expect(ThumbnailService, isNotNull);
      expect(superDeckSlideSize, isNotNull);
      expect(superDeckAspectRatio, isNotNull);
      expect(DeckLoader, isNotNull);
      expect(DeckWorkspace, isNotNull);
      expect(FileDeckLoader, isNotNull);
      expect(BundledDeckLoader, isNotNull);
      expect(DeckPlugin, isNotNull);
      expect(DeckAction, isNotNull);
      expect(DeckRuntimePlugin, isNotNull);
    });
  });
}
