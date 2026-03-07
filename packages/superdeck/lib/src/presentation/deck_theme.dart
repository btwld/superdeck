import 'package:flutter/foundation.dart' show mapEquals;

import '../styling/styling.dart';
import '../utils/collection_hashes.dart';
import 'slide_frame.dart';
import 'slide_template.dart';
import 'block_definition.dart';

class DeckTheme {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, BlockDefinition> widgets;
  final SlideFrame frame;
  final bool debug;
  final Map<String, SlideTemplate> templates;
  final SlideTemplate? defaultTemplate;

  const DeckTheme({
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
    this.widgets = const <String, BlockDefinition>{},
    this.frame = const SlideFrame(),
    this.debug = false,
    this.templates = const <String, SlideTemplate>{},
    this.defaultTemplate,
  });

  DeckTheme copyWith({
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
    Map<String, BlockDefinition>? widgets,
    SlideFrame? frame,
    bool? debug,
    Map<String, SlideTemplate>? templates,
    SlideTemplate? defaultTemplate,
  }) {
    return DeckTheme(
      baseStyle: baseStyle ?? this.baseStyle,
      styles: styles ?? this.styles,
      widgets: widgets ?? this.widgets,
      frame: frame ?? this.frame,
      debug: debug ?? this.debug,
      templates: templates ?? this.templates,
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckTheme &&
          runtimeType == other.runtimeType &&
          baseStyle == other.baseStyle &&
          mapEquals(styles, other.styles) &&
          mapEquals(widgets, other.widgets) &&
          frame == other.frame &&
          debug == other.debug &&
          mapEquals(templates, other.templates) &&
          defaultTemplate == other.defaultTemplate;

  @override
  int get hashCode => Object.hash(
    baseStyle,
    unorderedMapHash(styles),
    unorderedMapHash(widgets),
    frame,
    debug,
    unorderedMapHash(templates),
    defaultTemplate,
  );
}
