import 'package:flutter/widgets.dart';
import 'package:dart_mappable/dart_mappable.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/components/slide.dart';
import 'slide_template.dart';
import 'widget_factory.dart';

part 'deck_options.mapper.dart';

@MappableClass()
class DeckOptions with DeckOptionsMappable {
  final SlideStyler? baseStyle;
  final Map<String, SlideStyler> styles;
  final Map<String, WidgetFactory> widgets;
  final SlideParts parts;
  final bool debug;

  /// Named slide templates that bundle chrome + style systems.
  final Map<String, SlideTemplate> templates;

  /// Default template applied when a slide has no explicit template.
  ///
  /// Individual slides can opt out by setting `template: 'none'`, which
  /// disables applying any template for that slide.
  final SlideTemplate? defaultTemplate;

  DeckOptions({
    this.baseStyle,
    Map<String, SlideStyler> styles = const <String, SlideStyler>{},
    Map<String, WidgetFactory> widgets = const <String, WidgetFactory>{},
    this.parts = const SlideParts(),
    this.debug = false,
    Map<String, SlideTemplate> templates = const <String, SlideTemplate>{},
    this.defaultTemplate,
  }) : styles = Map.unmodifiable(styles),
       widgets = Map.unmodifiable(widgets),
       templates = Map.unmodifiable(templates);
}
