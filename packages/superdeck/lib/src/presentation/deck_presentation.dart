import 'package:flutter/foundation.dart' show listEquals, mapEquals;

import '../deck/slide_template.dart';
import '../deck/widget_definition.dart';
import '../rendering/slides/slide_parts.dart';
import '../styling/styling.dart';
import '../utils/collection_hashes.dart';
import 'deck_extension.dart';

class DeckPresentation {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, WidgetDefinition> widgets;
  final SlideParts parts;
  final bool debug;
  final Map<String, SlideTemplate> templates;
  final SlideTemplate? defaultTemplate;
  final List<DeckExtension> extensions;

  const DeckPresentation({
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
    this.widgets = const <String, WidgetDefinition>{},
    this.parts = const SlideParts(),
    this.debug = false,
    this.templates = const <String, SlideTemplate>{},
    this.defaultTemplate,
    this.extensions = const <DeckExtension>[],
  });

  DeckPresentation copyWith({
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
    Map<String, WidgetDefinition>? widgets,
    SlideParts? parts,
    bool? debug,
    Map<String, SlideTemplate>? templates,
    SlideTemplate? defaultTemplate,
    List<DeckExtension>? extensions,
  }) {
    return DeckPresentation(
      baseStyle: baseStyle ?? this.baseStyle,
      styles: styles ?? this.styles,
      widgets: widgets ?? this.widgets,
      parts: parts ?? this.parts,
      debug: debug ?? this.debug,
      templates: templates ?? this.templates,
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
      extensions: extensions ?? this.extensions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckPresentation &&
          runtimeType == other.runtimeType &&
          baseStyle == other.baseStyle &&
          mapEquals(styles, other.styles) &&
          mapEquals(widgets, other.widgets) &&
          parts == other.parts &&
          debug == other.debug &&
          mapEquals(templates, other.templates) &&
          defaultTemplate == other.defaultTemplate &&
          listEquals(extensions, other.extensions);

  @override
  int get hashCode => Object.hash(
    baseStyle,
    unorderedMapHash(styles),
    unorderedMapHash(widgets),
    parts,
    debug,
    unorderedMapHash(templates),
    defaultTemplate,
    Object.hashAll(extensions),
  );
}
