import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'block_model.dart';

part 'slide_model.mapper.dart';

final slideOptionsSchema = Ack.object({
  'title': Ack.string().optional(),
  'style': Ack.string().optional(),
  'layout': SlideLayout.schema.optional(),
  'template': Ack.string().optional(),
}, additionalProperties: true);

final slideSchema = Ack.object({
  'key': Ack.string(),
  'options': slideOptionsSchema.optional(),
  'sections': Ack.list(sectionBlockSchema).optional(),
  'comments': Ack.list(Ack.string()).optional(),
}, additionalProperties: true);

/// Represents a single slide in a presentation.
///
/// A slide contains sections of content blocks, optional configuration options,
/// and any speaker notes or comments. Each slide is uniquely identified by a key.
@MappableClass(ignoreNull: true)
class Slide with SlideMappable {
  /// Unique identifier for this slide, typically generated from content hash.
  final String key;

  final SlideOptions? options;

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

  static final schema = slideSchema;

  /// Validates [map] against the schema and constructs a [Slide].
  static Slide parse(Map<String, Object?> map) => fromMap(schema.parse(map)!);
}

@MappableEnum()
enum SlideLayout {
  normal,
  fullscreen;

  static final schema = Ack.enumValues(values);

  String toJson() => name;
}

/// Configuration options for a slide.
///
/// Provides metadata and styling information for individual slides.
@MappableClass(hook: UnmappedPropertiesHook('args'), ignoreNull: true)
class SlideOptions with SlideOptionsMappable {
  static const _knownFields = {'title', 'style', 'layout', 'template'};

  final String? title;

  /// The style variant to apply to this slide.
  final String? style;

  /// The layout mode to apply to this slide.
  ///
  /// Missing layout and [SlideLayout.normal] both use the default slide chrome
  /// and spacing. [SlideLayout.fullscreen] removes header/footer chrome (keeps
  /// background) and zeroes default block padding and margin before named style
  /// merge.
  final SlideLayout? layout;

  /// The slide template to use for chrome and style isolation.
  ///
  /// `template: 'none'` is a reserved opt-out value used to disable template
  /// application for the slide when a deck-level default template is configured.
  final String? template;

  final Map<String, Object?> args;

  SlideOptions({
    this.title,
    this.style,
    this.layout,
    this.template,
    Map<String, Object?> args = const {},
  }) : args = Map.unmodifiable(
         Map.fromEntries(
           args.entries.where((e) => !_knownFields.contains(e.key)),
         ),
       );

  static final fromMap = SlideOptionsMapper.fromMap;

  static final schema = slideOptionsSchema;

  /// Validates [map] against the schema and constructs [SlideOptions].
  static SlideOptions parse(Map<String, Object?> map) =>
      fromMap(schema.parse(map)!);
}
