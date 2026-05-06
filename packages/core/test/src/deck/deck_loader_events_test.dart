import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('SlidesEvent', () {
    test('is the common base type for loader events', () {
      final events = <SlidesEvent>[
        SlidesLoadingEvent('Loading slides'),
        SlidesLoadedEvent([Slide(key: 'intro')]),
        SlidesErrorEvent('Failed to load slides'),
        SlidesRebuildingEvent(),
      ];

      expect(events, everyElement(isA<SlidesEvent>()));
    });

    test('supports exhaustive switching across current variants', () {
      String eventName(SlidesEvent event) {
        return switch (event) {
          SlidesLoadingEvent() => 'loading',
          SlidesLoadedEvent() => 'loaded',
          SlidesErrorEvent() => 'error',
          SlidesRebuildingEvent() => 'rebuilding',
        };
      }

      expect(eventName(SlidesLoadingEvent('Loading slides')), 'loading');
      expect(eventName(SlidesLoadedEvent([])), 'loaded');
      expect(eventName(SlidesErrorEvent('Failed to load slides')), 'error');
      expect(eventName(SlidesRebuildingEvent()), 'rebuilding');
    });
  });

  group('SlidesLoadingEvent', () {
    test('exposes the loading message payload', () {
      final event = SlidesLoadingEvent('Loading slides');

      expect(event.message, 'Loading slides');
    });
  });

  group('SlidesLoadedEvent', () {
    test('exposes the loaded slides payload', () {
      final slides = [Slide(key: 'intro'), Slide(key: 'summary')];
      final event = SlidesLoadedEvent(slides);

      expect(event.slides, same(slides));
    });
  });

  group('SlidesErrorEvent', () {
    test('constructs with a message and no error payload', () {
      final event = SlidesErrorEvent('Failed to load slides');

      expect(event.message, 'Failed to load slides');
      expect(event.error, isNull);
    });

    test('exposes the provided error payload', () {
      final error = StateError('missing slides.md');
      final event = SlidesErrorEvent(
        'Failed to load slides',
        error: error,
      );

      expect(event.error, same(error));
    });
  });

  group('SlidesRebuildingEvent', () {
    test('constructs without a payload', () {
      final event = SlidesRebuildingEvent();

      expect(event, isA<SlidesEvent>());
    });
  });

  group('DeckLoader', () {
    test('declares the event stream and lifecycle API shape', () {
      final DeckLoader loader = _TypedDeckLoader();

      final Stream<SlidesEvent> Function() load = loader.load;
      final Future<void> Function() reload = loader.reload;
      final Future<void> Function() dispose = loader.dispose;

      expect(loader, isA<DeckLoader>());
      expect(load, isA<Stream<SlidesEvent> Function()>());
      expect(reload, isA<Future<void> Function()>());
      expect(dispose, isA<Future<void> Function()>());
    });
  });
}

class _TypedDeckLoader extends DeckLoader {
  @override
  Stream<SlidesEvent> load() => Stream<SlidesEvent>.empty();

  @override
  Future<void> reload() async {}

  @override
  Future<void> dispose() async {}
}
