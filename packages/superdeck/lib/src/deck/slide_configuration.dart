import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/components/slide.dart';
import '../ui/widgets/provider.dart';
import 'widget_factory.dart';

String buildThumbnailKey(String slideKey) {
  return 'thumbnail_$slideKey.png';
}

class SlideConfiguration {
  final int slideIndex;
  final SlideStyle style;
  final Slide _slide;
  final bool debug;
  final SlideParts? parts;
  final Map<String, WidgetFactory> _widgets;
  // Runtime thumbnail cache key (for example: thumbnail_intro.png).
  final String thumbnailKey;

  final bool isExporting;

  SlideConfiguration({
    required this.slideIndex,
    required this.style,
    required Slide slide,
    this.debug = false,
    this.parts,
    required this.thumbnailKey,
    Map<String, WidgetFactory> widgets = const {},
    this.isExporting = false,
  }) : _slide = slide,
       _widgets = widgets;

  SlideOptions get options => _slide.options ?? SlideOptions();

  String get key => _slide.key;

  Slide get data => _slide;

  List<SectionBlock> get sections => _slide.sections;

  List<String> get comments => _slide.comments;

  WidgetFactory? getWidgetFactory(String name) => _widgets[name];

  static SlideConfiguration of(BuildContext context) {
    return InheritedData.of(context);
  }

  SlideConfiguration copyWith({
    int? slideIndex,
    SlideStyle? style,
    Slide? slide,
    bool? debug,
    SlideParts? parts,
    String? thumbnailKey,
    Map<String, WidgetFactory>? widgets,
    bool? isExporting,
  }) {
    return SlideConfiguration(
      slideIndex: slideIndex ?? this.slideIndex,
      style: style ?? this.style,
      slide: slide ?? _slide,
      debug: debug ?? this.debug,
      parts: parts ?? this.parts,
      thumbnailKey: thumbnailKey ?? this.thumbnailKey,
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
          thumbnailKey == other.thumbnailKey &&
          _widgets == other._widgets &&
          isExporting == other.isExporting;

  @override
  int get hashCode => Object.hash(
    slideIndex,
    style,
    _slide,
    debug,
    parts,
    thumbnailKey,
    _widgets,
    isExporting,
  );
}
