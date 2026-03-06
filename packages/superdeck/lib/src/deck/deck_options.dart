import '../rendering/slides/slide_parts.dart';
import '../presentation/deck_extension.dart';
import '../styling/styling.dart';
import 'slide_template.dart';
import 'widget_definition.dart';

class DeckOptions {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, WidgetDefinition> widgets;
  final SlideParts parts;
  final bool debug;

  /// Named slide templates that bundle chrome + style systems.
  final Map<String, SlideTemplate> templates;

  /// Default template applied when a slide has no explicit template.
  ///
  /// Individual slides can opt out by setting `template: 'none'`, which
  /// disables applying any template for that slide.
  final SlideTemplate? defaultTemplate;

  /// Optional extension descriptors that extend deck behavior.
  final List<DeckExtension> extensions;

  const DeckOptions({
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
    this.widgets = const <String, WidgetDefinition>{},
    this.parts = const SlideParts(),
    this.debug = false,
    this.templates = const <String, SlideTemplate>{},
    this.defaultTemplate,
    this.extensions = const <DeckExtension>[],
  });

  DeckOptions copyWith({
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
    Map<String, WidgetDefinition>? widgets,
    SlideParts? parts,
    bool? debug,
    Map<String, SlideTemplate>? templates,
    SlideTemplate? defaultTemplate,
    List<DeckExtension>? extensions,
  }) {
    return DeckOptions(
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
      other is DeckOptions &&
          runtimeType == other.runtimeType &&
          baseStyle == other.baseStyle &&
          styles == other.styles &&
          widgets == other.widgets &&
          parts == other.parts &&
          debug == other.debug &&
          templates == other.templates &&
          defaultTemplate == other.defaultTemplate &&
          extensions == other.extensions;

  @override
  int get hashCode => Object.hash(
    baseStyle,
    styles,
    widgets,
    parts,
    debug,
    templates,
    defaultTemplate,
    extensions,
  );
}
