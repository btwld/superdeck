import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'block_model.dart';

part 'slide_model.g.dart';
part 'slide_model.mapper.dart';

const _knownSlideOptionFields = <String>{'title', 'style', 'template'};

/// Represents a single slide in a presentation.
///
/// A slide contains sections of content blocks, optional configuration options,
/// and any speaker notes or comments. Each slide is uniquely identified by a key.
@AckModel(additionalProperties: true)
@MappableClass()
class Slide with SlideMappable {
  /// Unique identifier for this slide, typically generated from content hash.
  final String key;

  /// Optional configuration options for this slide such as title and style.
  final SlideOptions? options;

  /// List of content sections that make up this slide.
  final List<SectionBlock> sections;

  /// Speaker notes or comments associated with this slide.
  final List<String> comments;

  Slide({
    required this.key,
    this.options,
    List<SectionBlock> sections = const [],
    List<String> comments = const [],
  }) : sections = List.unmodifiable(sections),
       comments = List.unmodifiable(comments);

  Map<String, Object?> toMap() {
    return {
      'key': key,
      if (options != null) 'options': options!.toMap(),
      'sections': sections.map((s) => s.toMap()).toList(),
      'comments': comments,
    };
  }

  static Slide fromMap(Map<String, Object?> map) {
    final optionsPayload = map['options'] as Map<String, Object?>?;

    return Slide(
      key: map['key'] as String,
      options: optionsPayload == null
          ? null
          : SlideOptions.fromMap(optionsPayload),
      sections: (map['sections'] as List<dynamic>? ?? const [])
          .map(
            (section) =>
                SectionBlock.fromMap(Map<String, Object?>.from(section as Map)),
          )
          .toList(),
      comments: (map['comments'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }

  /// Validation schema for slide data.
  static final schema = slideSchema.extend({
    'options': SlideOptions.schema.optional(),
    'sections': Ack.list(sectionBlockSchema).optional(),
    'comments': Ack.list(Ack.string()).optional(),
  });

  /// Validates [map] against the schema and constructs a [Slide].
  static Slide parse(Map<String, Object?> map) => fromMap(schema.parse(map)!);

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
          ContentBlock('''
> [!CAUTION]
> $title
> $message


```dart
${error.toString()}
```
'''),
          ContentBlock(''),
        ]),
      ],
    );
  }
}

/// Configuration options for a slide.
///
/// Provides metadata and styling information for individual slides.
@AckModel(additionalProperties: true, additionalPropertiesField: 'args')
@MappableClass(hook: UnmappedPropertiesHook('args'))
class SlideOptions with SlideOptionsMappable {
  /// The title of the slide, if any.
  final String? title;

  /// The style variant to apply to this slide.
  final String? style;

  /// The slide template to use for chrome and style isolation.
  ///
  /// `template: 'none'` is a reserved opt-out value used to disable template
  /// application for the slide when a deck-level default template is configured.
  final String? template;

  /// Additional arguments passed to the slide.
  final Map<String, Object?> args;

  SlideOptions({
    this.title,
    this.style,
    this.template,
    Map<String, Object?> args = const {},
  }) : args = Map.unmodifiable(args) {
    final collision =
        this.args.keys.where(_knownSlideOptionFields.contains).toList();
    if (collision.isNotEmpty) {
      throw ArgumentError(
        'SlideOptions args must not contain reserved keys: $collision',
      );
    }
  }

  Map<String, Object?> toMap() {
    return {
      ...args,
      if (title != null) 'title': title,
      if (style != null) 'style': style,
      if (template != null) 'template': template,
    };
  }

  static SlideOptions fromMap(Map<String, Object?> map) {
    final args = Map<String, Object?>.fromEntries(
      map.entries.where(
        (entry) => !_knownSlideOptionFields.contains(entry.key),
      ),
    );

    return SlideOptions(
      title: map['title'] as String?,
      style: map['style'] as String?,
      template: map['template'] as String?,
      args: args,
    );
  }

  /// Validation schema for slide options.
  static final schema = slideOptionsSchema.extend({
    'title': Ack.string().optional(),
    'style': Ack.string().optional(),
    'template': Ack.string().optional(),
  });

  /// Validates [map] against the schema and constructs [SlideOptions].
  static SlideOptions parse(Map<String, Object?> map) =>
      fromMap(schema.parse(map)!);
}
