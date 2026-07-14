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
/// Structured-output schema adapters (e.g. Google Generative AI) cannot
/// consume the JSON Schema `anyOf` union produced by
/// [Block.discriminatedSchema], so the discriminated block union is flattened
/// into one object with a `type` enum. Every field vocabulary (alignment,
/// flex, spacing, normalized insets, slide options) is shared with the
/// canonical schemas, so a contract change here reaches AI generation
/// automatically. Data generated against this projection must still decode
/// through [Slide.parse] / [parseSlidesContract].
final aiSlideSchema = Ack.object({
  'key': Ack.string().describe('Unique slide identifier using kebab-case'),
  'options': SlideOptions.schema.optional().describe('Slide options'),
  'comments': Ack.list(
    Ack.string().describe('A speaker note or talking point for this slide'),
  ).optional().describe('Speaker notes'),
  'sections': Ack.list(
    _aiSectionSchema,
  ).describe('Horizontal sections in the slide'),
}).describe('A single slide');

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
  'blocks': Ack.list(_aiBlockSchema).describe('Content blocks in this section'),
}).describe('A section containing blocks');

final _aiBlockSchema = Ack.object({
  'type': Ack.enumString(const [ContentBlock.key, WidgetBlock.key]).describe(
    'Block type: "block" for markdown content, "widget" for a named widget '
    'reference',
  ),
  'content': Ack.string().optional().describe(
    'Markdown content (required for type "block")',
  ),
  'name': Ack.string().optional().describe(
    'Widget name (required for type "widget")',
  ),
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
  'scrollable': Ack.boolean().optional().describe(
    'Whether overflowing block content scrolls',
  ),
}).describe('A content or widget block');
