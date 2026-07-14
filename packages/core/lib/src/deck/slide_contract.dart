import 'package:ack/ack.dart';

import 'block_insets.dart';
import 'block_model.dart';
import 'slide_model.dart';

/// Canonical top-level JSON contract for compiled slide payloads.
final slidesContractSchema = Ack.list(Slide.schema);

/// Parses a compiled slide payload from a raw JSON array.
List<Slide> parseSlidesContract(Object? value) {
  final validated = slidesContractSchema.parse(value)! as List<Object?>;
  return validated
      .cast<Map<String, Object?>>()
      .map((slide) => Slide.fromMap(Map<String, dynamic>.from(slide)))
      .toList(growable: false);
}

/// Flattened slide projection for structured-output AI generation.
///
/// This text-only projection shares canonical field vocabularies (alignment,
/// flex, spacing, normalized insets, and safe slide options) while excluding
/// runtime-only features. Widget blocks, scrolling, and registry references
/// such as `style` and `template` require host application configuration, so
/// generated visual styling belongs to the deck-level style contract instead.
/// Data generated against this projection must still decode through
/// [Slide.parse] / [parseSlidesContract].
final aiSlideSchema = Ack.object({
  'key': Ack.string().describe('Unique slide identifier using kebab-case'),
  'options': _aiSlideOptionsSchema.optional().describe('Slide options'),
  'comments': Ack.list(
    Ack.string().describe('A speaker note or talking point for this slide'),
  ).optional().describe('Speaker notes'),
  'sections': Ack.list(
    _aiSectionSchema,
  ).minLength(1).describe('Horizontal sections in the slide'),
}).describe('A single slide');

final _aiSlideOptionsSchema = Ack.object({
  'title': Ack.string().optional(),
  'layout': SlideLayout.schema.optional(),
});

final _aiSectionSchema = Ack.object({
  'type': Ack.literal(SectionBlock.key).describe('Section type discriminator'),
  'align': ContentAlignment.schema.optional().describe(
    'Content alignment within the section',
  ),
  'flex': positiveFlexSchema.optional().describe(
    'Flex weight for proportional sizing. Higher values take more space.',
  ),
  'spacing': nonNegativeSpacingSchema.optional().describe(
    'Gap in logical pixels between sibling blocks',
  ),
  'blocks': Ack.list(
    _aiBlockSchema,
  ).minLength(1).describe('Content blocks in this section'),
}).describe('A section containing blocks');

final _aiBlockSchema = Ack.object({
  'type': Ack.literal(ContentBlock.key).describe('Content block discriminator'),
  'content': Ack.string().notEmpty().describe('Non-empty Markdown content'),
  'align': ContentAlignment.schema.optional().describe('Content alignment'),
  'flex': positiveFlexSchema.optional().describe(
    'Flex weight for proportional sizing. Higher values take more space.',
  ),
  'margin': BlockInsets.schema.optional().describe(
    'Space inside the block frame but outside its decoration, as normalized '
    'physical edges',
  ),
  'padding': BlockInsets.schema.optional().describe(
    'Space between the block decoration and its content, as normalized '
    'physical edges',
  ),
}).describe('A Markdown content block');
