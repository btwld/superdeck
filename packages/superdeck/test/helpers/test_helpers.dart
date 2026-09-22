import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck_core/superdeck_core.dart';

export '../fixtures/slide_fixtures.dart';

class NoopAssetCacheStore implements AssetCacheStore {
  @override
  Future<void> delete(String assetKey) async {}

  @override
  Future<Uri?> resolve(String assetKey) async => null;

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async => null;
}

/// Creates a list of test slides for testing navigation and presentation.
List<SlideConfiguration> createTestSlides(int count) {
  return List.generate(
    count,
    (index) => SlideConfiguration(
      slideIndex: index,
      style: SlideStyler(),
      slide: Slide(
        key: 'slide-$index',
        sections: [
          SectionBlock([ContentBlock('Test slide $index content')]),
        ],
      ),
      thumbnailKey: buildThumbnailKey('slide-$index'),
    ),
  );
}

/// Creates a test slide payload with the given slides.
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

int _testSlideId = 0;

String _nextKey(String prefix) => '$prefix-${_testSlideId++}';

/// Creates a simple single-section slide with given blocks.
Slide createSlideFromBlocks(
  List<Block> blocks, {
  String? key,
  int sectionFlex = 1,
}) {
  return Slide(
    key: key ?? _nextKey('test-slide'),
    sections: [SectionBlock(blocks, flex: sectionFlex)],
  );
}

extension WidgetTesterX on WidgetTester {
  Future<void> pumpWithScaffold(Widget widget) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }
}
