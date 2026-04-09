import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals.dart';
import 'package:superdeck/src/deck/deck_presentation_state.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/deck/superdeck_plugin.dart';
import 'package:superdeck/src/export/async_thumbnail.dart';
import 'package:superdeck/src/export/thumbnail_service.dart';

import '../../helpers/test_helpers.dart';

class _TrackableAsyncThumbnail extends AsyncThumbnail {
  bool disposed = false;

  _TrackableAsyncThumbnail({required super.thumbnailKey})
    : super(
        generator: (context, {required force}) async =>
            Uri.parse('file:///tmp/$thumbnailKey'),
      );

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class _RecordingThumbnailService extends ThumbnailService {
  _RecordingThumbnailService() : super(cacheStore: NoopAssetCacheStore());

  int callCount = 0;
  final List<Set<String>> receivedCacheKeys = <Set<String>>[];
  final Map<String, _TrackableAsyncThumbnail> trackedThumbnails =
      <String, _TrackableAsyncThumbnail>{};

  @override
  void generateThumbnails({
    required List<SlideConfiguration> slides,
    required BuildContext context,
    required Map<String, AsyncThumbnail> cache,
    required void Function(Map<String, AsyncThumbnail>) onCacheUpdate,
    bool force = false,
  }) {
    callCount++;
    receivedCacheKeys.add(cache.keys.toSet());

    final updatedCache = Map<String, AsyncThumbnail>.from(cache);
    for (final slide in slides) {
      final existing = updatedCache[slide.key];
      if (existing case _TrackableAsyncThumbnail()
          when existing.thumbnailKey == slide.thumbnailKey) {
        continue;
      }

      existing?.dispose();
      final thumbnail = _TrackableAsyncThumbnail(
        thumbnailKey: slide.thumbnailKey,
      );
      trackedThumbnails[slide.key] = thumbnail;
      updatedCache[slide.key] = thumbnail;
    }

    onCacheUpdate(updatedCache);
  }
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(key: key),
    ),
  );
  return key.currentContext!;
}

void main() {
  group('DeckPresentationState', () {
    testWidgets('manual generation removes stale thumbnails', (tester) async {
      final slides = signal<List<SlideConfiguration>>(createTestSlides(2));
      final service = _RecordingThumbnailService();
      final state = DeckPresentationState(
        thumbnailService: service,
        slides: slides,
        plugins: const <SuperDeckPlugin>[],
        transitionDuration: Duration.zero,
      );
      addTearDown(state.dispose);

      final context = await _pumpContext(tester);
      state.generateThumbnails(context, slides.value);

      final staleThumbnail = service.trackedThumbnails['slide-1']!;

      slides.value = [slides.value.first];
      state.generateThumbnails(context, slides.value, force: true);

      expect(state.getThumbnail('slide-0'), isNotNull);
      expect(state.getThumbnail('slide-1'), isNull);
      expect(staleThumbnail.disposed, isTrue);
      expect(service.receivedCacheKeys.last, equals({'slide-0'}));
    });

    testWidgets('dispose tears down thumbnail cache and blocks later updates', (
      tester,
    ) async {
      final slides = signal<List<SlideConfiguration>>(createTestSlides(1));
      addTearDown(slides.dispose);

      final service = _RecordingThumbnailService();
      final state = DeckPresentationState(
        thumbnailService: service,
        slides: slides,
        plugins: const <SuperDeckPlugin>[],
        transitionDuration: Duration.zero,
      );

      final context = await _pumpContext(tester);
      state.generateThumbnails(context, slides.value);
      expect(service.trackedThumbnails.keys, contains('slide-0'));
      final thumbnail = service.trackedThumbnails['slide-0']!;

      final callsBeforeDispose = service.callCount;

      state.dispose();

      slides.value = createTestSlides(2);
      state.generateThumbnails(context, slides.value);
      await tester.pump();
      await tester.pump();

      expect(service.callCount, callsBeforeDispose);
      expect(thumbnail.disposed, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
