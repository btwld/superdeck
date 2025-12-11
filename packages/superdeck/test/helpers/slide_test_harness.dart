import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck/src/utils/constants.dart'; // kResolution
import 'package:superdeck/src/rendering/slides/slide_view.dart';

/// Lightweight harness for pumping slides with production defaults.
class SlideTestHarness {
  /// Pumps a [Slide] inside MaterialApp/Scaffold with defaults that mirror runtime.
  static Future<void> pumpSlide(
    WidgetTester tester,
    Slide slide, {
    SlideStyle? style,
    Map<String, WidgetDefinition> widgets = const {},
    bool debug = false,
    Size? resolution,
    bool isExporting = false,
    SlideParts? parts,
  }) async {
    final configuration = createConfiguration(
      slide,
      style: style,
      widgets: widgets,
      debug: debug,
      isExporting: isExporting,
      parts: parts,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InheritedData(
            data: configuration,
            child: SizedBox(
              width: resolution?.width ?? kResolution.width,
              height: resolution?.height ?? kResolution.height,
              child: SlideView(configuration),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  /// Creates a [SlideConfiguration] with sensible defaults.
  static SlideConfiguration createConfiguration(
    Slide slide, {
    SlideStyle? style,
    Map<String, WidgetDefinition> widgets = const {},
    bool debug = false,
    int slideIndex = 0,
    SlideParts? parts,
    bool isExporting = false,
  }) {
    return SlideConfiguration(
      slideIndex: slideIndex,
      style: style ?? defaultSlideStyle,
      slide: slide,
      thumbnailFile: 'test-thumbnail.png',
      debug: debug,
      widgets: {...builtInWidgets, ...widgets},
      parts: parts ?? const SlideParts(),
      isExporting: isExporting,
    );
  }

  /// Pumps a pre-built [SlideConfiguration].
  static Future<void> pumpConfiguration(
    WidgetTester tester,
    SlideConfiguration configuration, {
    Size? resolution,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InheritedData(
            data: configuration,
            child: SizedBox(
              width: resolution?.width ?? kResolution.width,
              height: resolution?.height ?? kResolution.height,
              child: SlideView(configuration),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }
}
