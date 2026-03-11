import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'block_model.dart';

part 'slide_model.g.dart';
part 'slide_model.mapper.dart';

/// Represents a single slide in a presentation.
///
/// A slide contains sections of content blocks, optional configuration options,
/// and any speaker notes or comments. Each slide is uniquely identified by a key.
@AckModel(additionalProperties: true)
@MappableClass(ignoreNull: true)
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

  static final fromMap = SlideMapper.fromMap;

  /// Validation schema for slide data.
  static final schema = slideSchema.extend({
    'options': SlideOptions.schema.optional(),
    'sections': Ack.list(sectionBlockSchema).optional(),
    'comments': Ack.list(Ack.string()).optional(),
  });

  /// Validates [map] against the schema and constructs a [Slide].
  static Slide parse(Map<String, Object?> map) => fromMap(schema.parse(map)!);
}

/// Configuration options for a slide.
///
/// Provides metadata and styling information for individual slides.
@AckModel(additionalProperties: true, additionalPropertiesField: 'args')
@MappableClass(hook: UnmappedPropertiesHook('args'), ignoreNull: true)
class SlideOptions with SlideOptionsMappable {
  static const _knownFields = {'title', 'style', 'template'};

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
  }) : args = Map.unmodifiable(
         Map.fromEntries(
           args.entries.where((e) => !_knownFields.contains(e.key)),
         ),
       );

  static final fromMap = SlideOptionsMapper.fromMap;

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
