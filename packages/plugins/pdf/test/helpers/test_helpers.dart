import 'dart:async';

import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

class NoopAssetCacheStore implements AssetCacheStore {
  @override
  Future<void> delete(String assetKey) async {}

  @override
  Future<Uri?> resolve(String assetKey) async => null;

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async => null;
}

class TestDeckLoader extends DeckLoader {
  TestDeckLoader({List<Slide>? slides})
    : _slidesToReturn = slides ?? createTestSlidesPayload(),
      super();

  final StreamController<SlidesEvent> _eventController =
      StreamController<SlidesEvent>.broadcast();
  final List<Slide> _slidesToReturn;

  var _disposed = false;

  @override
  Stream<SlidesEvent> load() {
    Future.microtask(() {
      _eventController.add(SlidesLoadingEvent('Loading...'));
      _eventController.add(SlidesLoadedEvent(_slidesToReturn));
    });
    return _eventController.stream;
  }

  @override
  Future<void> reload() async {
    _eventController.add(SlidesLoadedEvent(_slidesToReturn));
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    return _eventController.close();
  }
}

List<SlideConfiguration> createTestSlides(int count) {
  return List.generate(count, (index) {
    final slideKey = 'slide-$index';
    return SlideConfiguration(
      slideIndex: index,
      style: SlideStyle(),
      slide: Slide(
        key: slideKey,
        sections: [
          SectionBlock([ContentBlock('Test slide $index content')]),
        ],
      ),
      thumbnailKey: buildThumbnailKey(slideKey),
    );
  });
}

List<Slide> createTestSlidesPayload({List<Slide>? slides}) {
  return slides ??
      List.generate(
        3,
        (index) => Slide(
          key: 'slide-$index',
          sections: [
            SectionBlock([ContentBlock('Test slide $index content')]),
          ],
        ),
      );
}

class SlideTestHarness {
  static SlideConfiguration createConfiguration(
    Slide slide, {
    SlideStyle? style,
    Map<String, WidgetFactory> widgets = const {},
    bool debug = false,
    int slideIndex = 0,
    SlideParts? parts,
    bool isStaticRendering = false,
  }) {
    return SlideConfiguration(
      slideIndex: slideIndex,
      style: style ?? SlideStyle(),
      slide: slide,
      thumbnailKey: 'test-thumbnail.png',
      debug: debug,
      widgets: widgets,
      parts: parts ?? const SlideParts(),
      isStaticRendering: isStaticRendering,
    );
  }
}
