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
/// The discriminated content/widget union is retained for providers that
/// support same-type `anyOf` branches. Every field vocabulary (alignment,
/// flex, spacing, normalized insets, slide options) is shared with the
/// canonical schemas, so a contract change here reaches AI generation
/// automatically. Data generated against this projection must still decode
/// through [Slide.parse] / [parseSlidesContract].
final aiSlideSchema = buildAiSlideSchema();

/// Builds the canonical AI slide projection with optional widget argument
/// fields supplied by an application generation catalog.
///
/// Set [nestWidgetArguments] for model-facing draft payloads so widget-only
/// fields cannot collide with content-block fields such as `content`. Those
/// draft `args` objects must be flattened before canonical [Slide.parse].
ObjectSchema buildAiSlideSchema({
  Map<String, AckSchema<Object, Object>> widgetArgumentProperties = const {},
  bool nestWidgetArguments = false,
  bool requirePresentationOptions = false,
}) {
  final widgetProperties = switch ((
    nestWidgetArguments,
    widgetArgumentProperties.isEmpty,
  )) {
    (_, true) => <String, AckSchema<Object, Object>>{},
    (true, false) => <String, AckSchema<Object, Object>>{
      'args': Ack.object(widgetArgumentProperties).optional().describe(
        'Arguments for the selected widget name. Use only fields allowed by '
        'that widget catalog entry.',
      ),
    },
    (false, false) => widgetArgumentProperties,
  };
  final commonBlockProperties = <String, AckSchema<Object, Object>>{
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
  };
  final contentBlockSchema = Ack.object({
    'type': Ack.literal(
      ContentBlock.key,
    ).describe('Markdown content block discriminator'),
    'content': Ack.string()
        .minLength(1)
        .describe('Non-empty Markdown content for this block'),
    ...commonBlockProperties,
  }).describe('A Markdown content block');
  final widgetBlockSchema = Ack.object({
    'type': Ack.literal(
      WidgetBlock.key,
    ).describe('Named widget block discriminator'),
    'name': Ack.string().minLength(1).describe('Registered widget name'),
    ...commonBlockProperties,
    ...widgetProperties,
  }).describe('A named widget block');
  final blockSchema = Ack.anyOf([
    contentBlockSchema,
    widgetBlockSchema,
  ]).describe('A discriminated content or widget block');

  final sectionSchema = Ack.object({
    'type': Ack.literal(
      SectionBlock.key,
    ).describe('Section type discriminator'),
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
      blockSchema,
    ).minItems(1).maxItems(3).describe('Content blocks in this section'),
  }).describe('A section containing blocks');
  final generationOptionsSchema = Ack.object({
    'title': Ack.string().minLength(1).describe('Visible slide title'),
    'style': Ack.string()
        .minLength(1)
        .describe('Exact renderer-owned treatment selected in the deck plan'),
    'layout': SlideLayout.schema.optional(),
    'template': Ack.string().optional(),
  });

  return Ack.object({
    'key': Ack.string().describe('Unique slide identifier using kebab-case'),
    'options': requirePresentationOptions
        ? generationOptionsSchema.describe(
            'Required presentation metadata for generated slides',
          )
        : SlideOptions.schema.optional().describe('Slide options'),
    'comments': Ack.list(
      Ack.string().describe('A speaker note or talking point for this slide'),
    ).optional().describe('Speaker notes'),
    'sections': Ack.list(
      sectionSchema,
    ).minItems(1).maxItems(4).describe('Horizontal sections in the slide'),
  }).describe('A single slide');
}
