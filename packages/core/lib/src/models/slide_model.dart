import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'block_model.dart';

part 'slide_model.g.dart';

const _knownSlideOptionFields = <String>{'title', 'style', 'template'};

/// Represents a single slide in a presentation.
///
/// A slide contains sections of content blocks, optional configuration options,
/// and any speaker notes or comments. Each slide is uniquely identified by a key.
@AckModel(additionalProperties: true)
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

  Map<String, Object?> toMap() {
    return {
      'key': key,
      if (options != null) 'options': options!.toMap(),
      'sections': sections.map((s) => s.toMap()).toList(),
      'comments': comments,
    };
  }

  static Slide fromMap(Map<String, Object?> map) {
    final payload = schema.parse(map) as Map<String, Object?>;
    return _fromPayload(payload);
  }

  @internal
  static Slide fromValidatedMap(Map<String, Object?> payload) {
    return _fromPayload(payload);
  }

  static Slide _fromPayload(Map<String, Object?> payload) {
    final optionsPayload = payload['options'] as Map<String, Object?>?;

    return Slide(
      key: payload['key'] as String,
      options: optionsPayload == null
          ? null
          : SlideOptions.fromMap(optionsPayload),
      sections: (payload['sections'] as List<dynamic>? ?? const [])
          .map(
            (section) =>
                SectionBlock.fromMap(Map<String, Object?>.from(section as Map)),
          )
          .toList(),
      comments: (payload['comments'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }

  /// Validation schema for slide data.
  static final schema = slideSchema.extend({
    'options': SlideOptions.schema.optional(),
    'sections': Ack.list(sectionBlockSchema).optional(),
    'comments': Ack.list(Ack.string()).optional(),
  });

  /// Alias for [fromMap].
  static Slide parse(Map<String, Object?> map) => fromMap(map);

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
@AckModel(additionalProperties: true, additionalPropertiesField: 'args')
class SlideOptions {
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

  const SlideOptions({
    this.title,
    this.style,
    this.template,
    this.args = const {},
  });

  SlideOptions copyWith({
    String? title,
    String? style,
    String? template,
    Map<String, Object?>? args,
  }) {
    return SlideOptions(
      title: title ?? this.title,
      style: style ?? this.style,
      template: template ?? this.template,
      args: args ?? this.args,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (title != null) 'title': title,
      if (style != null) 'style': style,
      if (template != null) 'template': template,
      ...args,
    };
  }

  static SlideOptions fromMap(Map<String, Object?> map) {
    final payload = schema.parse(map) as Map<String, Object?>;
    return _fromPayload(payload);
  }

  static SlideOptions _fromPayload(Map<String, Object?> payload) {
    final args = Map<String, Object?>.fromEntries(
      payload.entries.where(
        (entry) => !_knownSlideOptionFields.contains(entry.key),
      ),
    );

    return SlideOptions(
      title: payload['title'] as String?,
      style: payload['style'] as String?,
      template: payload['template'] as String?,
      args: args,
    );
  }

  /// Validation schema for slide options.
  static final schema = slideOptionsSchema.extend({
    'title': Ack.string().optional(),
    'style': Ack.string().optional(),
    'template': Ack.string().optional(),
  });

  /// Alias for [fromMap].
  static SlideOptions parse(Map<String, Object?> map) => fromMap(map);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideOptions &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          style == other.style &&
          template == other.template &&
          const MapEquality().equals(args, other.args);

  @override
  int get hashCode =>
      Object.hash(title, style, template, const MapEquality().hash(args));
}
