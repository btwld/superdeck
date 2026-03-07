import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_genui/src/presentation/thumbnail_preview_service.dart';

void main() {
  group('ThumbnailPreviewService', () {
    late List<(SlideData, BuildContext)> capturedCalls;
    late ThumbnailPreviewService service;

    /// Fake capture function that records calls and returns deterministic bytes.
    Future<Uint8List> fakeCapture(
      SlideData slide,
      BuildContext context,
    ) async {
      capturedCalls.add((slide, context));
      return Uint8List.fromList([slide.slideIndex]);
    }

    setUp(() {
      capturedCalls = [];
      service = ThumbnailPreviewService(captureSlide: fakeCapture);
    });

    testWidgets('returns empty list for empty slides', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return const SizedBox.shrink();
          },
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final result = await service.generatePreviews(
        context: context,
        slides: [],
      );

      expect(result, isEmpty);
      expect(capturedCalls, isEmpty);
    });

    testWidgets('captures each slide and returns thumbnails', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return const SizedBox.shrink();
          },
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final slides = [
        const Slide(key: 'slide_0'),
        const Slide(key: 'slide_1'),
        const Slide(key: 'slide_2'),
      ];

      final result = await service.generatePreviews(
        context: context,
        slides: slides,
      );

      expect(result, hasLength(3));
      expect(capturedCalls, hasLength(3));
      // Each thumbnail contains the slide index byte
      expect(result[0].$1, 0);
      expect(result[0].$2, Uint8List.fromList([0]));
      expect(result[1].$1, 1);
      expect(result[1].$2, Uint8List.fromList([1]));
      expect(result[2].$1, 2);
      expect(result[2].$2, Uint8List.fromList([2]));
    });

    testWidgets('calls onThumbnailCaptured for each slide', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return const SizedBox.shrink();
          },
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final slides = [const Slide(key: 'slide_0'), const Slide(key: 'slide_1')];
      final captured = <(int, Uint8List)>[];

      await service.generatePreviews(
        context: context,
        slides: slides,
        onThumbnailCaptured: (index, bytes) => captured.add((index, bytes)),
      );

      expect(captured, hasLength(2));
      expect(captured[0].$1, 0);
      expect(captured[0].$2, Uint8List.fromList([0]));
      expect(captured[1].$1, 1);
      expect(captured[1].$2, Uint8List.fromList([1]));
    });

    testWidgets('stops when isCancelled returns true', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return const SizedBox.shrink();
          },
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final slides = [
        const Slide(key: 'slide_0'),
        const Slide(key: 'slide_1'),
        const Slide(key: 'slide_2'),
      ];

      var cancelAfter = 1;
      final result = await service.generatePreviews(
        context: context,
        slides: slides,
        isCancelled: () => capturedCalls.length >= cancelAfter,
      );

      // Only first slide captured before cancellation check fires
      expect(result, hasLength(1));
      expect(capturedCalls, hasLength(1));
    });

    testWidgets('continues past failed captures', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return const SizedBox.shrink();
          },
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final slides = [
        const Slide(key: 'slide_0'),
        const Slide(key: 'slide_1'),
        const Slide(key: 'slide_2'),
      ];

      var callCount = 0;
      final failingService = ThumbnailPreviewService(
        captureSlide: (slide, ctx) async {
          callCount++;
          if (slide.slideIndex == 1) {
            throw Exception('Capture failed');
          }
          return Uint8List.fromList([slide.slideIndex]);
        },
      );

      final result = await failingService.generatePreviews(
        context: context,
        slides: slides,
      );

      // Slide 1 failed but 0 and 2 succeeded
      expect(result, hasLength(2));
      expect(callCount, 3);
      expect(result[0].$1, 0);
      expect(result[0].$2, Uint8List.fromList([0]));
      expect(result[1].$1, 2);
      expect(result[1].$2, Uint8List.fromList([2]));
    });

    testWidgets('does not call onThumbnailCaptured for failed captures', (
      tester,
    ) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return const SizedBox.shrink();
          },
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final slides = [const Slide(key: 'slide_0'), const Slide(key: 'slide_1')];
      final captured = <(int, Uint8List)>[];

      final failingService = ThumbnailPreviewService(
        captureSlide: (slide, ctx) async {
          if (slide.slideIndex == 0) throw Exception('Fail');
          return Uint8List.fromList([slide.slideIndex]);
        },
      );

      await failingService.generatePreviews(
        context: context,
        slides: slides,
        onThumbnailCaptured: (index, bytes) => captured.add((index, bytes)),
      );

      // Only slide 1 was captured successfully
      expect(captured, hasLength(1));
      expect(captured[0].$1, 1);
      expect(captured[0].$2, Uint8List.fromList([1]));
    });
  });
}
