// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_model.dart';

/// Generated schema for Deck
final deckSchema = Ack.object({
  'slides': Ack.list(slideSchema),
  'style': Ack.object({}, additionalProperties: true).optional().nullable(),
  'configuration': deckConfigurationSchema,
}, additionalProperties: true);
