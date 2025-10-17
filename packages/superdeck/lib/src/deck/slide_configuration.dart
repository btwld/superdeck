import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/slide_style.dart';
import '../ui/widgets/provider.dart';
import 'deck_options.dart';

class SlideConfiguration {
  final int slideIndex;
  final SlideStyle style;
  final Slide _slide;
  final bool debug;
  final SlideParts? parts;
  final Map<String, WidgetBlockBuilder> _widgets;
  final String thumbnailFile;

  final bool isExporting;

  SlideConfiguration({
    required this.slideIndex,
    required this.style,
    required Slide slide,
    this.debug = false,
    this.parts,
    required this.thumbnailFile,
    Map<String, WidgetBlockBuilder> widgets = const {},
    this.isExporting = false,
  }) : _slide = slide,
       _widgets = widgets;

  SlideOptions get options => _slide.options ?? const SlideOptions();

  String get key => _slide.key;

  Slide get data => _slide;

  List<SectionBlock> get sections => _slide.sections;

  List<String> get comments => _slide.comments;

  WidgetBlockBuilder? getWidget(String name) => _widgets[name];

  static SlideConfiguration of(BuildContext context) {
    return InheritedData.of(context);
  }

  SlideConfiguration copyWith({
    int? slideIndex,
    SlideStyle? style,
    Slide? slide,
    bool? debug,
    SlideParts? parts,
    String? thumbnailFile,
    Map<String, WidgetBlockBuilder>? widgets,
    bool? isExporting,
  }) {
    return SlideConfiguration(
      slideIndex: slideIndex ?? this.slideIndex,
      style: style ?? this.style,
      slide: slide ?? _slide,
      debug: debug ?? this.debug,
      parts: parts ?? this.parts,
      thumbnailFile: thumbnailFile ?? this.thumbnailFile,
      widgets: widgets ?? _widgets,
      isExporting: isExporting ?? this.isExporting,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideConfiguration &&
          runtimeType == other.runtimeType &&
          slideIndex == other.slideIndex &&
          style == other.style &&
          _slide == other._slide &&
          debug == other.debug &&
          parts == other.parts &&
          thumbnailFile == other.thumbnailFile &&
          _widgets == other._widgets &&
          isExporting == other.isExporting;

  @override
  int get hashCode => Object.hash(
    slideIndex,
    style,
    _slide,
    debug,
    parts,
    thumbnailFile,
    _widgets,
    isExporting,
  );
}
