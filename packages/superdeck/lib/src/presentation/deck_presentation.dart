import 'package:meta/meta.dart';

import '../deck/deck_options.dart';
import '../deck/slide_template.dart';
import '../deck/widget_definition.dart';
import '../rendering/slides/slide_parts.dart';
import '../styling/styling.dart';
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

  @internal
  DeckOptions toDeckOptions() {
    return DeckOptions(
      baseStyle: baseStyle,
      styles: styles,
      widgets: widgets,
      parts: parts,
      debug: debug,
      templates: templates,
      defaultTemplate: defaultTemplate,
      extensions: extensions,
    );
  }
}
