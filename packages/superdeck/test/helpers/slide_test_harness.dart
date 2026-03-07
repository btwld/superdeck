import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/rendering/slides/slide_view.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/utils/constants.dart'; // kResolution
import 'package:superdeck/src/utils/syntax_highlighter.dart';
import 'package:superdeck/superdeck.dart';

/// Lightweight harness for pumping slides with production defaults.
class SlideTestHarness {
  /// Pumps a [Slide] inside MaterialApp/Scaffold with defaults that mirror runtime.
  static Future<void> pumpSlide(
    WidgetTester tester,
    Slide slide, {
    SlideStyle? style,
    Map<String, BlockDefinition> widgets = const {},
    bool debug = false,
    Size? resolution,
    bool isExporting = false,
    SlideFrame? frame,
  }) async {
    await SyntaxHighlight.initialize();
    final configuration = createConfiguration(
      slide,
      style: style,
      widgets: widgets,
      debug: debug,
      isExporting: isExporting,
      frame: frame,
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

  /// Creates a [SlideData] with sensible defaults.
  static SlideData createConfiguration(
    Slide slide, {
    SlideStyle? style,
    Map<String, BlockDefinition> widgets = const {},
    bool debug = false,
    int slideIndex = 0,
    SlideFrame? frame,
    bool isExporting = false,
  }) {
    return SlideData(
      slideIndex: slideIndex,
      style: style ?? defaultSlideStyle,
      slide: slide,
      thumbnailFile: 'test-thumbnail.png',
      debug: debug,
      widgets: {...builtInWidgets, ...widgets},
      frame: frame ?? const SlideFrame(),
      isExporting: isExporting,
    );
  }

  /// Pumps a pre-built [SlideData].
  static Future<void> pumpConfiguration(
    WidgetTester tester,
    SlideData configuration, {
    Size? resolution,
  }) async {
    await SyntaxHighlight.initialize();
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
