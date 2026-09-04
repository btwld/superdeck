import 'package:collection/collection.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/components/slide.dart';
import 'slide_template.dart';
import 'widget_factory.dart';

const _undefined = Object();

class DeckOptions {
  static const _stylesEquality = MapEquality<String, SlideStyler>();
  static const _widgetsEquality = MapEquality<String, WidgetFactory>();
  static const _templatesEquality = MapEquality<String, SlideTemplate>();

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

  DeckOptions copyWith({
    Object? baseStyle = _undefined,
    Map<String, SlideStyler>? styles,
    Map<String, WidgetFactory>? widgets,
    SlideParts? parts,
    bool? debug,
    Map<String, SlideTemplate>? templates,
    Object? defaultTemplate = _undefined,
  }) {
    return DeckOptions(
      baseStyle: identical(baseStyle, _undefined)
          ? this.baseStyle
          : baseStyle as SlideStyler?,
      styles: styles ?? this.styles,
      widgets: widgets ?? this.widgets,
      parts: parts ?? this.parts,
      debug: debug ?? this.debug,
      templates: templates ?? this.templates,
      defaultTemplate: identical(defaultTemplate, _undefined)
          ? this.defaultTemplate
          : defaultTemplate as SlideTemplate?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeckOptions &&
            runtimeType == other.runtimeType &&
            baseStyle == other.baseStyle &&
            _stylesEquality.equals(styles, other.styles) &&
            _widgetsEquality.equals(widgets, other.widgets) &&
            parts == other.parts &&
            debug == other.debug &&
            _templatesEquality.equals(templates, other.templates) &&
            defaultTemplate == other.defaultTemplate;
  }

  @override
  int get hashCode => Object.hash(
    baseStyle,
    _stylesEquality.hash(styles),
    _widgetsEquality.hash(widgets),
    parts,
    debug,
    _templatesEquality.hash(templates),
    defaultTemplate,
  );

  @override
  String toString() {
    return 'DeckOptions(baseStyle: $baseStyle, styles: $styles, '
        'widgets: $widgets, parts: $parts, debug: $debug, '
        'templates: $templates, defaultTemplate: $defaultTemplate)';
  }
}
