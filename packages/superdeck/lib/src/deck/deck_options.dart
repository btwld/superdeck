import '../rendering/slides/slide_parts.dart';
import '../styling/styling.dart';
import 'widget_definition.dart';

class DeckOptions {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, WidgetDefinition> widgets;
  final SlideParts parts;
  final bool debug;
  final bool showThumbnails;

  /// Whether to watch for file changes and auto-rebuild the deck.
  ///
  /// When `true`, starts a runtime watcher that monitors the slides file
  /// and rebuilds automatically on changes.
  /// Defaults to `false`.
  final bool watchForChanges;

  const DeckOptions({
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
    this.widgets = const <String, WidgetDefinition>{},
    this.parts = const SlideParts(),
    this.debug = false,
    bool? showThumbnails,
    @Deprecated('Use showThumbnails instead') bool? generateThumbnails,
    this.watchForChanges = false,
  }) : showThumbnails = generateThumbnails ?? showThumbnails ?? true;

  @Deprecated('Use showThumbnails instead')
  bool get generateThumbnails => showThumbnails;

  DeckOptions copyWith({
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
    Map<String, WidgetDefinition>? widgets,
    SlideParts? parts,
    bool? debug,
    bool? showThumbnails,
    @Deprecated('Use showThumbnails instead') bool? generateThumbnails,
    bool? watchForChanges,
  }) {
    return DeckOptions(
      baseStyle: baseStyle ?? this.baseStyle,
      styles: styles ?? this.styles,
      widgets: widgets ?? this.widgets,
      parts: parts ?? this.parts,
      debug: debug ?? this.debug,
      showThumbnails:
          generateThumbnails ?? showThumbnails ?? this.showThumbnails,
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
          showThumbnails == other.showThumbnails &&
          watchForChanges == other.watchForChanges;

  @override
  int get hashCode => Object.hash(
    baseStyle,
    styles,
    widgets,
    parts,
    debug,
    showThumbnails,
    watchForChanges,
  );
}
