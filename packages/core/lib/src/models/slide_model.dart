import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'block_model.dart';

part 'slide_model.g.dart';
part 'slide_model.mapper.dart';

/// Represents a single slide in a presentation.
///
/// A slide contains sections of content blocks, optional configuration options,
/// and any speaker notes. Each slide is uniquely identified by a key.
@AckModel(additionalProperties: true)
@MappableClass(ignoreNull: true)
class Slide with SlideMappable {
  /// Unique identifier for this slide, typically generated from content hash.
  final String key;

  /// Optional configuration options for this slide such as title and style.
  final SlideOptions? options;

  /// List of content sections that make up this slide.
  final List<SectionBlock> sections;

  /// Speaker notes associated with this slide.
  final List<String> notes;

  const Slide({
    required this.key,
    this.options,
    this.sections = const [],
    this.notes = const [],
  });

  factory Slide.fromMap(Map<String, Object?> map) =>
      SlideMapper.fromMap(Map<String, dynamic>.from(map));

  /// Validation schema for slide data.
  static final schema = slideSchema.extend({
    'options': SlideOptions.schema.optional(),
    'sections': Ack.list(sectionBlockSchema).optional(),
    'notes': Ack.list(Ack.string()).optional(),
  });

  static Slide parse(Map<String, Object?> map) {
    final payload = schema.parse(map) as Map<String, Object?>;
    return Slide.fromMap(payload);
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
@MappableClass(ignoreNull: true, hook: UnmappedPropertiesHook('args'))
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

  const SlideOptions({
    this.title,
    this.style,
    this.template,
    this.args = const {},
  });

  factory SlideOptions.fromMap(Map<String, Object?> map) {
    return SlideOptionsMapper.fromMap(Map<String, dynamic>.from(map));
  }

  /// Validation schema for slide options.
  static final schema = slideOptionsSchema.extend({
    'title': Ack.string().optional(),
    'style': Ack.string().optional(),
    'template': Ack.string().optional(),
  });

  static SlideOptions parse(Map<String, Object?> map) {
    final payload = schema.parse(map) as Map<String, Object?>;
    return SlideOptions.fromMap(payload);
  }
}
