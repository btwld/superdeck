import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../components/parts/slide_parts.dart';
import '../common/helpers/provider.dart';
import 'deck_options.dart';

part 'slide_configuration.mapper.dart';

@MappableClass()
class SlideConfiguration with SlideConfigurationMappable {
  final int slideIndex;
  final Style style;
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
  })  : _slide = slide,
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
}
