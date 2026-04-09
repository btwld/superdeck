import 'package:flutter/widgets.dart';
import 'package:dart_mappable/dart_mappable.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/components/slide.dart';
import 'slide_template.dart';
import 'superdeck_plugin.dart';
import 'widget_factory.dart';

part 'deck_options.mapper.dart';

@MappableClass()
class DeckOptions with DeckOptionsMappable {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
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

  /// Optional plugin descriptors that extend deck behavior.
  final List<SuperDeckPlugin> plugins;

  DeckOptions({
    this.baseStyle,
    Map<String, SlideStyle> styles = const <String, SlideStyle>{},
    Map<String, WidgetFactory> widgets = const <String, WidgetFactory>{},
    this.parts = const SlideParts(),
    this.debug = false,
    Map<String, SlideTemplate> templates = const <String, SlideTemplate>{},
    this.defaultTemplate,
    List<SuperDeckPlugin> plugins = const <SuperDeckPlugin>[],
  }) : styles = Map.unmodifiable(styles),
       widgets = Map.unmodifiable(widgets),
       templates = Map.unmodifiable(templates),
       plugins = List.unmodifiable(plugins);
}
