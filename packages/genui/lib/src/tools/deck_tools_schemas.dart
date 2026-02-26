import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import '../ai/schemas/deck_schemas.dart';

part 'deck_tools_schemas.g.dart';

@AckType(name: 'ReadSlideRequest')
final _readSlideRequestSchema = Ack.object({
  'index': Ack.integer().min(0).describe('Zero-based slide index'),
}).describe('Request payload for readSlide');
final readSlideRequestSchema = _readSlideRequestSchema;

@AckType(name: 'CreateSlideRequest')
final _createSlideRequestSchema = Ack.object({
  'schema': createSlideSchema.describe('Slide schema payload'),
  'atIndex': Ack.integer()
      .min(0)
      .optional()
      .describe('Optional insertion index. Defaults to appending at the end'),
}).describe('Request payload for createSlide');
final createSlideRequestSchema = _createSlideRequestSchema;

@AckType(name: 'UpdateSlideRequest')
final _updateSlideRequestSchema = Ack.object({
  'index': Ack.integer().min(0).describe('Zero-based slide index'),
  'schema': createSlideSchema.describe('Replacement slide schema payload'),
}).describe('Request payload for updateSlide');
final updateSlideRequestSchema = _updateSlideRequestSchema;

@AckType(name: 'DeleteSlideRequest')
final _deleteSlideRequestSchema = Ack.object({
  'index': Ack.integer().min(0).describe('Zero-based slide index'),
}).describe('Request payload for deleteSlide');
final deleteSlideRequestSchema = _deleteSlideRequestSchema;

@AckType(name: 'MoveSlideRequest')
final _moveSlideRequestSchema = Ack.object({
  'fromIndex': Ack.integer().min(0).describe('Current slide index'),
  'toIndex': Ack.integer().min(0).describe('Target slide index'),
}).describe('Request payload for moveSlide');
final moveSlideRequestSchema = _moveSlideRequestSchema;

@AckType(name: 'UpdateStyleRequest')
final _updateStyleRequestSchema = Ack.object({
  'style': styleSchema.describe('Complete deck style payload'),
}).describe('Request payload for updateStyle');
final updateStyleRequestSchema = _updateStyleRequestSchema;

@AckType(name: 'SlideSummary')
final _slideSummarySchema = Ack.object({
  'index': Ack.integer().min(0).describe('Zero-based slide index'),
  'key': Ack.string().describe('Stable slide key'),
  'title': Ack.string().optional().describe('Optional slide title'),
}).describe('Deck slide summary');
final slideSummarySchema = _slideSummarySchema;

@AckType(name: 'DeckSnapshot')
final _deckSnapshotSchema = Ack.object({
  'totalSlides': Ack.integer().min(0).describe('Total number of slides'),
  'slides': Ack.list(
    _slideSummarySchema,
  ).describe('Ordered slide summaries for the deck'),
  'style': styleSchema.optional().describe('Current deck style when available'),
}).describe('Current deck snapshot');
final deckSnapshotSchema = _deckSnapshotSchema;

@AckType(name: 'ReadSlidePayload')
final _readSlidePayloadSchema = Ack.object({
  'index': Ack.integer().describe('Zero-based slide index'),
  'key': Ack.string().describe('Slide key'),
  'schema': slideSchema.describe('Serialized slide schema'),
  'thumbnail': Ack.string().describe('Base64-encoded PNG thumbnail'),
}).describe('Detailed slide read payload');

@AckType(name: 'ReadSlideResult')
final _readSlideResultSchema = Ack.object({
  'slide': _readSlidePayloadSchema,
  'deck': _deckSnapshotSchema,
}).describe('Result payload for readSlide');
final readSlideResultSchema = _readSlideResultSchema;

@AckType(name: 'SlideMutationResult')
final _slideMutationResultSchema = Ack.object({
  'slide': _slideSummarySchema,
  'deck': _deckSnapshotSchema,
}).describe('Result payload for createSlide/updateSlide');
final slideMutationResultSchema = _slideMutationResultSchema;

@AckType(name: 'SlideMoveResult')
final _slideMoveResultSchema = Ack.object({
  'slide': _slideSummarySchema,
  'deck': _deckSnapshotSchema,
}).describe('Result payload for moveSlide');
final slideMoveResultSchema = _slideMoveResultSchema;

@AckType(name: 'StyleUpdateResult')
final _styleUpdateResultSchema = Ack.object({
  'style': styleSchema.describe('Applied deck style'),
  'deck': _deckSnapshotSchema,
}).describe('Result payload for updateStyle');
final styleUpdateResultSchema = _styleUpdateResultSchema;
