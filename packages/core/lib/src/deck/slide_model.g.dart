// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'slide_model.dart';

/// Generated schema for Slide
/// Represents a single slide in a presentation. A slide contains sections of content blocks, optional configuration options, and any speaker notes or comments. Each slide is uniquely identified by a key.
final slideSchema = Ack.object({
  'key': Ack.string().describe(
    'Unique identifier for this slide, typically generated from content hash.',
  ),
  'options': slideOptionsSchema.optional().nullable(),
  'sections': Ack.list(sectionBlockSchema),
  'comments': Ack.list(
    Ack.string(),
  ).describe('Speaker notes or comments associated with this slide.'),
}, additionalProperties: true);

/// Generated schema for SlideOptions
/// Configuration options for a slide. Provides metadata and styling information for individual slides.
final slideOptionsSchema = Ack.object({
  'title': Ack.string().optional().nullable(),
  'style': Ack.string().optional().nullable().describe(
    'The style variant to apply to this slide.',
  ),
  'template': Ack.string().optional().nullable().describe(
    'The slide template to use for chrome and style isolation. `template: \'none\'` is a reserved opt-out value used to disable template application for the slide when a deck-level default template is configured.',
  ),
}, additionalProperties: true);
