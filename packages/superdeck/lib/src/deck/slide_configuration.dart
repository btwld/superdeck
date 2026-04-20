import 'package:flutter/widgets.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/components/slide.dart';
import '../ui/widgets/provider.dart';
import 'widget_factory.dart';

part 'slide_configuration.mapper.dart';

String buildThumbnailKey(String slideKey) {
  return 'thumbnail_$slideKey.png';
}

@MappableClass()
class SlideConfiguration with SlideConfigurationMappable {
  final int slideIndex;
  final SlideStyle style;
  final Slide slide;
  final bool debug;
  final SlideParts? parts;
  final Map<String, WidgetFactory> widgets;
  // Runtime thumbnail cache key (for example: thumbnail_intro.png).
  final String thumbnailKey;

  final bool isStaticRendering;

  SlideConfiguration({
    required this.slideIndex,
    required this.style,
    required this.slide,
    this.debug = false,
    this.parts,
    required this.thumbnailKey,
    this.widgets = const {},
    this.isStaticRendering = false,
  });

  SlideOptions get options => slide.options ?? SlideOptions();

  String get key => slide.key;

  List<SectionBlock> get sections => slide.sections;

  List<String> get comments => slide.comments;

  WidgetFactory? getWidgetFactory(String name) => widgets[name];

  static SlideConfiguration of(BuildContext context) {
    return InheritedData.of(context);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideConfiguration &&
          runtimeType == other.runtimeType &&
          slideIndex == other.slideIndex &&
          style == other.style &&
          slide == other.slide &&
          debug == other.debug &&
          parts == other.parts &&
          thumbnailKey == other.thumbnailKey &&
          widgets == other.widgets &&
          isStaticRendering == other.isStaticRendering;

  @override
  int get hashCode => Object.hash(
    slideIndex,
    style,
    slide,
    debug,
    parts,
    thumbnailKey,
    widgets,
    isStaticRendering,
  );
}
