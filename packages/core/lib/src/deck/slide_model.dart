import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import 'block_model.dart';

part 'slide_model.ack.dart';
part 'slide_model.ack.g.dart';

/// Represents a single slide in a presentation.
///
/// A slide contains sections of content blocks, optional configuration options,
/// and any speaker notes or comments. Each slide is uniquely identified by a key.
@AckModel()
final class Slide with _$SlideAck {
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

  static final fromJson = SlideSchema.fromJson;

  /// Validates [map] against the schema and constructs a [Slide].
  static Slide parse(Map<String, Object?> map) => SlideSchema.parse(map);
}

enum SlideLayout {
  normal,
  fullscreen;

  static final schema = Ack.enumValues(values);

  String toJson() => name;
}

/// Configuration options for a slide.
///
/// Provides metadata and styling information for individual slides.
@AckModel(
  unknownProperties: AckUnknownPropertyPolicy.capture,
  captureField: 'args',
)
final class SlideOptions with _$SlideOptionsAck {
  static const _knownFields = {'title', 'style', 'layout', 'template'};

  final String? title;

  /// The style variant to apply to this slide.
  final String? style;

  /// The layout mode to apply to this slide.
  ///
  /// Missing layout and [SlideLayout.normal] both use the resolved slide parts
  /// unchanged. [SlideLayout.fullscreen] removes header/footer chrome (keeps
  /// background) without changing the resolved slide style.
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
  }) : args = deepUnmodifiableJsonMap(
         Map.fromEntries(
           args.entries.where((e) => !_knownFields.contains(e.key)),
         ),
       );

  static final fromJson = SlideOptionsSchema.fromJson;

  /// Validates [map] against the schema and constructs [SlideOptions].
  static SlideOptions parse(Map<String, Object?> map) =>
      SlideOptionsSchema.parse(map);
}
