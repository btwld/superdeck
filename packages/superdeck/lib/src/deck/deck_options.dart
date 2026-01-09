import '../rendering/slides/slide_parts.dart';
import '../styling/styling.dart';
import 'widget_definition.dart';

class DeckOptions {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, WidgetDefinition> widgets;
  final SlideParts parts;
  final bool debug;

  /// Whether to watch for file changes and auto-rebuild the deck.
  ///
  /// When `true` (default), starts a CLI watcher process that monitors
  /// the slides file and rebuilds automatically on changes.
  /// Set to `false` to disable file watching.
  final bool watchForChanges;

  const DeckOptions({
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
    this.widgets = const <String, WidgetDefinition>{},
    this.parts = const SlideParts(),
    this.debug = false,
    this.watchForChanges = false,
  });

  DeckOptions copyWith({
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
    Map<String, WidgetDefinition>? widgets,
    SlideParts? parts,
    bool? debug,
    bool? watchForChanges,
  }) {
    return DeckOptions(
      baseStyle: baseStyle ?? this.baseStyle,
      styles: styles ?? this.styles,
      widgets: widgets ?? this.widgets,
      parts: parts ?? this.parts,
      debug: debug ?? this.debug,
      watchForChanges: watchForChanges ?? this.watchForChanges,
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
          watchForChanges == other.watchForChanges;

  @override
  int get hashCode =>
      Object.hash(baseStyle, styles, widgets, parts, debug, watchForChanges);
}
