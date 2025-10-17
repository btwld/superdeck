import 'package:ack/ack.dart';
import 'package:collection/collection.dart';
import 'package:superdeck_core/src/models/block_model.dart';

/// Represents a single slide in a presentation.
///
/// A slide contains sections of content blocks, optional configuration options,
/// and any speaker notes or comments. Each slide is uniquely identified by a key.
class Slide {
  /// Unique identifier for this slide, typically generated from content hash.
  final String key;

  /// Optional configuration options for this slide such as title and style.
  final SlideOptions? options;

  /// List of content sections that make up this slide.
  final List<SectionBlock> sections;

  /// Speaker notes or comments associated with this slide.
  final List<String> comments;

  const Slide({
    required this.key,
    this.options,
    this.sections = const [],
    this.comments = const [],
  });

  Slide copyWith({
    String? key,
    SlideOptions? options,
    List<SectionBlock>? sections,
    List<String>? comments,
  }) {
    return Slide(
      key: key ?? this.key,
      options: options ?? this.options,
      sections: sections ?? this.sections,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      if (options != null) 'options': options!.toMap(),
      'sections': sections.map((s) => s.toMap()).toList(),
      'comments': comments,
    };
  }

  static Slide fromMap(Map<String, dynamic> map) {
    return Slide(
      key: map['key'] as String,
      options: map['options'] != null
          ? SlideOptions.fromMap(map['options'] as Map<String, dynamic>)
          : null,
      sections:
          (map['sections'] as List<dynamic>?)
              ?.map((e) => SectionBlock.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      comments:
          (map['comments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Validation schema for slide data.
  static final schema = Ack.object({
    "key": Ack.string(),
    'options': SlideOptions.schema.nullable().optional(),
    'sections': Ack.list(
      Ack.object({
        'type': Ack.string(),
        'blocks': Ack.list(Ack.object({})).nullable().optional(),
      }),
    ).optional(),
    'comments': Ack.list(Ack.string()).optional(),
  }, additionalProperties: true);

  /// Parses a slide from a JSON map.
  ///
  /// Validates the map against the schema before parsing.
  /// Throws an exception if the validation fails.
  static Slide parse(Map<String, dynamic> map) {
    schema.parse(map);
    return fromMap(map);
  }

  /// Creates an error slide to display errors in the presentation.
  ///
  /// This slide is automatically generated when there are parsing errors
  /// or other issues loading the presentation.
  static Slide error({
    required String title,
    required String message,
    required Exception error,
  }) {
    return Slide(
      key: 'error',
      sections: [
        SectionBlock([
          ColumnBlock('''
> [!CAUTION]
> $title
> $message


```dart
${error.toString()}
```
'''),
          ColumnBlock(''),
        ]),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Slide &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          options == other.options &&
          const DeepCollectionEquality().equals(sections, other.sections) &&
          const ListEquality().equals(comments, other.comments);

  @override
  int get hashCode => Object.hash(
    key,
    options,
    const DeepCollectionEquality().hash(sections),
    const ListEquality().hash(comments),
  );
}

/// Configuration options for a slide.
///
/// Provides metadata and styling information for individual slides.
class SlideOptions {
  /// The title of the slide, if any.
  final String? title;

  /// The style template to apply to this slide.
  final String? style;

  /// Additional arguments passed to the slide template.
  final Map<String, Object?> args;

  const SlideOptions({this.title, this.style, this.args = const {}});

  SlideOptions copyWith({
    String? title,
    String? style,
    Map<String, Object?>? args,
  }) {
    return SlideOptions(
      title: title ?? this.title,
      style: style ?? this.style,
      args: args ?? this.args,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (title != null) 'title': title,
      if (style != null) 'style': style,
      ...args,
    };
  }

  static SlideOptions fromMap(Map<String, dynamic> map) {
    final title = map['title'] as String?;
    final style = map['style'] as String?;

    final args = Map<String, Object?>.from(map);
    args.remove('title');
    args.remove('style');

    return SlideOptions(title: title, style: style, args: args);
  }

  /// Validation schema for slide options.
  static final schema = Ack.object({
    'title': Ack.string().nullable().optional(),
    'style': Ack.string().nullable().optional(),
  }, additionalProperties: true);

  /// Parses slide options from a JSON map.
  static SlideOptions parse(Map<String, dynamic> map) {
    schema.parse(map);
    return fromMap(map);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideOptions &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          style == other.style &&
          const MapEquality().equals(args, other.args);

  @override
  int get hashCode => Object.hash(title, style, const MapEquality().hash(args));
}
