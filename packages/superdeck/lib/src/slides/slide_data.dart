import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../presentation/slide_frame.dart';
import '../presentation/widget_definition.dart';
import '../styling/components/slide.dart';
import '../ui/widgets/provider.dart';
import '../utils/collection_hashes.dart';

class SlideData {
  final int slideIndex;
  final SlideStyle style;
  final Slide _slide;
  final bool debug;
  final SlideFrame? frame;
  final Map<String, WidgetDefinition> _widgets;
  // Bare thumbnail asset key (for example: thumbnail_intro.png).
  final String thumbnailFile;

  final bool isExporting;

  SlideData({
    required this.slideIndex,
    required this.style,
    required Slide slide,
    this.debug = false,
    this.frame,
    required this.thumbnailFile,
    Map<String, WidgetDefinition> widgets = const {},
    this.isExporting = false,
  }) : _slide = slide,
       _widgets = widgets;

  SlideOptions get options => _slide.options ?? const SlideOptions();

  String get key => _slide.key;

  Slide get slide => _slide;

  List<SectionBlock> get sections => _slide.sections;

  List<String> get notes => _slide.notes;

  WidgetDefinition? getWidgetDefinition(String name) => _widgets[name];

  static SlideData of(BuildContext context) {
    return InheritedData.of(context);
  }

  SlideData copyWith({
    int? slideIndex,
    SlideStyle? style,
    Slide? slide,
    bool? debug,
    SlideFrame? frame,
    String? thumbnailFile,
    Map<String, WidgetDefinition>? widgets,
    bool? isExporting,
  }) {
    return SlideData(
      slideIndex: slideIndex ?? this.slideIndex,
      style: style ?? this.style,
      slide: slide ?? _slide,
      debug: debug ?? this.debug,
      frame: frame ?? this.frame,
      thumbnailFile: thumbnailFile ?? this.thumbnailFile,
      widgets: widgets ?? _widgets,
      isExporting: isExporting ?? this.isExporting,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideData &&
          runtimeType == other.runtimeType &&
          slideIndex == other.slideIndex &&
          style == other.style &&
          _slide == other._slide &&
          debug == other.debug &&
          frame == other.frame &&
          thumbnailFile == other.thumbnailFile &&
          mapEquals(_widgets, other._widgets) &&
          isExporting == other.isExporting;

  @override
  int get hashCode => Object.hash(
    slideIndex,
    style,
    _slide,
    debug,
    frame,
    thumbnailFile,
    unorderedMapHash(_widgets),
    isExporting,
  );
}
