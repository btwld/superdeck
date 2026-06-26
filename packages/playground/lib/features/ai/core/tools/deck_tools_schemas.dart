import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import '../ai/schemas/deck_schemas.dart';

part 'deck_tools_schemas.g.dart';

@AckType(name: 'DeckToolSlideOptions')
final _deckToolSlideOptionsSchema = Ack.object({
  'title': Ack.string().optional(),
  'style': Ack.string().optional(),
  'template': Ack.string().optional(),
}, additionalProperties: true).describe('Core SuperDeck slide options');
final deckToolSlideOptionsSchema = _deckToolSlideOptionsSchema;

const _alignmentValues = [
  'topLeft',
  'topCenter',
  'topRight',
  'centerLeft',
  'center',
  'centerRight',
  'bottomLeft',
  'bottomCenter',
  'bottomRight',
];

@AckType(name: 'DeckToolContentBlock')
final _deckToolContentBlockSchema = Ack.object({
  'type': Ack.literal('block').describe('Markdown content block'),
  'content': Ack.string().optional(),
  'align': Ack.enumString(_alignmentValues).optional(),
  'flex': Ack.integer().optional(),
  'scrollable': Ack.boolean().optional(),
}, additionalProperties: true).describe('Core SuperDeck content block');

@AckType(name: 'DeckToolWidgetBlock')
final _deckToolWidgetBlockSchema = Ack.object({
  'type': Ack.literal('widget').describe('Named widget block'),
  'name': Ack.string(),
  'align': Ack.enumString(_alignmentValues).optional(),
  'flex': Ack.integer().optional(),
  'scrollable': Ack.boolean().optional(),
}, additionalProperties: true).describe('Core SuperDeck widget block');

@AckType(name: 'DeckToolBlock')
final _deckToolBlockSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'block': _deckToolContentBlockSchema,
    'widget': _deckToolWidgetBlockSchema,
  },
).describe('Core SuperDeck block payload');

@AckType(name: 'DeckToolSlideSection')
final _deckToolSlideSectionSchema = Ack.object({
  'type': Ack.literal('section').optional(),
  'align': Ack.enumString(_alignmentValues).optional(),
  'flex': Ack.integer().optional(),
  'blocks': Ack.list(_deckToolBlockSchema).optional(),
}, additionalProperties: false).describe('Core SuperDeck section payload');
final deckToolSlideSectionSchema = _deckToolSlideSectionSchema;

@AckType(name: 'DeckToolSlide')
final _deckToolSlideSchema = Ack.object(
  {
    'options': _deckToolSlideOptionsSchema.optional(),
    'comments': Ack.list(Ack.string()).optional(),
    'sections': Ack.list(_deckToolSlideSectionSchema),
  },
  additionalProperties: false,
).describe('Keyless SuperDeck slide payload used by deck-edit tools');
final deckToolSlideSchema = _deckToolSlideSchema;

@AckType(name: 'ReadSlideRequest')
final _readSlideRequestSchema = Ack.object({
  'index': Ack.integer().describe('Zero-based slide index'),
}).describe('Request payload for readSlide');
final readSlideRequestSchema = _readSlideRequestSchema;

@AckType(name: 'CreateSlideRequest')
final _createSlideRequestSchema = Ack.object({
  'slide': _deckToolSlideSchema.describe('Keyless slide payload'),
  'atIndex': Ack.integer().optional().describe(
    'Optional insertion index. Defaults to appending at the end',
  ),
}).describe('Request payload for createSlide');
final createSlideRequestSchema = _createSlideRequestSchema;

@AckType(name: 'UpdateSlideRequest')
final _updateSlideRequestSchema = Ack.object({
  'index': Ack.integer().describe('Zero-based slide index'),
  'slide': _deckToolSlideSchema.describe('Replacement keyless slide payload'),
}).describe('Request payload for updateSlide');
final updateSlideRequestSchema = _updateSlideRequestSchema;

@AckType(name: 'DeleteSlideRequest')
final _deleteSlideRequestSchema = Ack.object({
  'index': Ack.integer().describe('Zero-based slide index'),
}).describe('Request payload for deleteSlide');
final deleteSlideRequestSchema = _deleteSlideRequestSchema;

@AckType(name: 'MoveSlideRequest')
final _moveSlideRequestSchema = Ack.object({
  'fromIndex': Ack.integer().describe('Current slide index'),
  'toIndex': Ack.integer().describe('Target slide index'),
}).describe('Request payload for moveSlide');
final moveSlideRequestSchema = _moveSlideRequestSchema;

@AckType(name: 'UpdateStyleRequest')
final _updateStyleRequestSchema = Ack.object({
  'style': styleSchema.describe('Complete deck style payload'),
}).describe('Request payload for updateStyle');
final updateStyleRequestSchema = _updateStyleRequestSchema;

@AckType(name: 'SlideSummary')
final _slideSummarySchema = Ack.object({
  'index': Ack.integer().describe('Zero-based slide index'),
  'title': Ack.string().optional().describe('Optional slide title'),
}).describe('Deck slide summary');
final slideSummarySchema = _slideSummarySchema;

@AckType(name: 'DeckSnapshot')
final _deckSnapshotSchema = Ack.object({
  'totalSlides': Ack.integer().describe('Total number of slides'),
  'slides': Ack.list(
    _slideSummarySchema,
  ).describe('Ordered slide summaries for the deck'),
}).describe('Current deck snapshot');
final deckSnapshotSchema = _deckSnapshotSchema;

@AckType(name: 'ReadSlideResult')
final _readSlideResultSchema = Ack.object({
  'index': Ack.integer().describe('Zero-based slide index'),
  'title': Ack.string().optional().describe('Optional slide title'),
  'slide': _deckToolSlideSchema.describe('Keyless slide payload'),
  'thumbnailBase64': Ack.string().describe('Base64-encoded PNG thumbnail'),
  'deck': _deckSnapshotSchema,
}).describe('Result payload for readSlide');
final readSlideResultSchema = _readSlideResultSchema;

@AckType(name: 'SlideMutationResult')
final _slideMutationResultSchema = Ack.object({
  'index': Ack.integer().describe('Result slide index'),
  'slide': _deckToolSlideSchema.describe('Keyless slide payload'),
  'deck': _deckSnapshotSchema,
}).describe('Result payload for createSlide/updateSlide');
final slideMutationResultSchema = _slideMutationResultSchema;

@AckType(name: 'SlideMoveResult')
final _slideMoveResultSchema = Ack.object({
  'fromIndex': Ack.integer().describe('Original slide index'),
  'toIndex': Ack.integer().describe('Target slide index'),
  'deck': _deckSnapshotSchema,
}).describe('Result payload for moveSlide');
final slideMoveResultSchema = _slideMoveResultSchema;

@AckType(name: 'StyleUpdateResult')
final _styleUpdateResultSchema = Ack.object({
  'style': styleSchema.describe('Applied deck style'),
  'deck': _deckSnapshotSchema,
}).describe('Result payload for updateStyle');
final styleUpdateResultSchema = _styleUpdateResultSchema;
