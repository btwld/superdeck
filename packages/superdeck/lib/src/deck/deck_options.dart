import '../rendering/slides/slide_parts.dart';
import '../styling/styling.dart';
import 'widget_definition.dart';

class DeckOptions {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, WidgetDefinition> widgets;
  final SlideParts parts;
  final bool debug;

  const DeckOptions({
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
    this.widgets = const <String, WidgetDefinition>{},
    this.parts = const SlideParts(),
    this.debug = false,
  });

  DeckOptions copyWith({
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
    Map<String, WidgetDefinition>? widgets,
    SlideParts? parts,
    bool? debug,
  }) {
    return DeckOptions(
      baseStyle: baseStyle ?? this.baseStyle,
      styles: styles ?? this.styles,
      widgets: widgets ?? this.widgets,
      parts: parts ?? this.parts,
      debug: debug ?? this.debug,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckOptions &&
          runtimeType == other.runtimeType &&
          baseStyle == other.baseStyle &&
          styles == other.styles &&
          widgets == other.widgets &&
          parts == other.parts &&
          debug == other.debug;

  @override
  int get hashCode => Object.hash(baseStyle, styles, widgets, parts, debug);
}
