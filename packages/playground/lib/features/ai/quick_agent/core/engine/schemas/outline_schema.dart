import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import 'deck_schemas.dart';

part 'outline_schema.g.dart';

/// Schema definitions for presentation planning (Phase 1).
///
/// The deck plan captures the narrative, shared style, and enough composition
/// intent to generate each slide independently in a later phase.
///
/// This is generated first so the AI can plan the deck structure before
/// writing the full slide content.

// ============================================================================
// SLIDE OUTLINE SCHEMA
// ============================================================================

const deckPlanNarrativeRoles = [
  'opening',
  'context',
  'problem',
  'insight',
  'evidence',
  'comparison',
  'solution',
  'process',
  'takeaway',
  'transition',
  'closing',
];

const deckPlanCompositionIntents = [
  'title',
  'content',
  'twoColumn',
  'threeColumn',
  'table',
  'quote',
  'titleLeft',
  'imageLeft',
  'imageRight',
  'imageFullBleed',
  'metric',
  'qrcode',
  'webview',
  'dartpad',
  'custom',
];

const deckPlanElementTypes = [
  'image',
  'qrcode',
  'webview',
  'dartpad',
  'custom',
];

const deckPlanTreatments = [
  'hero',
  'section',
  'content',
  'data',
  'quote',
  'visual',
  'closing',
];

@AckType(name: 'DeckPlanSection')
final deckPlanSectionSchema = Ack.object({
  'key': Ack.string().describe('Unique section or act identifier'),
  'title': Ack.string().describe('Short internal title for this story section'),
  'purpose': Ack.string().describe('Narrative job performed by this section'),
  'transition': Ack.string().describe(
    'How this section hands the story to the next section',
  ),
  'slideKeys': Ack.list(
    Ack.string(),
  ).describe('Ordered slide keys belonging to this section'),
}).describe('A narrative section or act in the deck blueprint');

/// Optional generated-element requirement attached to a slide plan.
@AckType(name: 'DeckPlanElement')
final deckPlanElementSchema = Ack.object({
  'type': Ack.enumString(
    deckPlanElementTypes,
  ).describe('Generation-capable element needed by the slide'),
  'purpose': Ack.string().describe('Why this element belongs on the slide'),
  'source': Ack.string().optional().describe(
    'User-supplied asset path, URL, text, or gist identifier when available',
  ),
  'widgetName': Ack.string().optional().describe(
    'Registered widget name when type is custom',
  ),
}).describe('An element requirement for later slide composition');

/// Schema for a single slide in the deck plan.
///
/// Contains the essential planning information:
/// - key: Unique identifier for referencing in later phases
/// - title: Working title (may be refined during slide composition)
/// - purpose: What the slide will communicate
/// - composition: Semantic layout intent for the slide composer
@AckType(name: 'DeckPlanSlide')
final deckPlanSlideSchema = Ack.object({
  'key': Ack.string().describe(
    'Unique identifier for this slide (e.g., "intro", "slide-1", "conclusion")',
  ),
  'title': Ack.string().describe(
    'Working title for this slide (may be refined in final generation)',
  ),
  'purpose': Ack.string().describe(
    'Brief description of what this slide will communicate (1-2 sentences)',
  ),
  'sectionKey': Ack.string().describe(
    'Key of the narrative section containing this slide',
  ),
  'assertion': Ack.string().describe(
    'The single audience-facing claim this slide must make',
  ),
  'contentUnits': Ack.list(
    Ack.string(),
  ).describe('Concrete evidence, examples, or implications to compose'),
  'narrativeRole': Ack.enumString(
    deckPlanNarrativeRoles,
  ).describe('The job this slide performs in the presentation story'),
  'contentBrief': Ack.string().describe(
    'Specific facts, examples, and emphasis the composed slide must include',
  ),
  'continuity': Ack.string().describe(
    'How this slide connects the previous and next ideas',
  ),
  'composition': Ack.enumString(deckPlanCompositionIntents).describe(
    'Semantic composition intent; the slide composer owns exact geometry',
  ),
  'treatment': Ack.enumString(
    deckPlanTreatments,
  ).describe('Semantic theme treatment selected for this slide'),
  'density': Ack.enumString(
    deckDensityProfiles,
  ).describe('Slide-specific density override within the shared system'),
  'elements': Ack.list(deckPlanElementSchema).optional().describe(
    'Optional non-Markdown elements required by this slide',
  ),
}).describe('A single slide in the presentation deck plan');

// ============================================================================
// ROOT OUTLINE SCHEMA
// ============================================================================

/// Schema for the complete presentation outline.
///
/// Root schema for Phase 1 generation, containing the topic
/// and ordered list of slide outlines.
@AckType(name: 'DeckPlan')
final deckPlanSchema =
    Ack.object({
      'topic': Ack.string().describe('Main topic of the presentation'),
      'story': Ack.string().describe(
        'One-sentence narrative through-line for the complete presentation',
      ),
      'style': styleSchema.describe(
        'Shared palette and typography selected once for the complete deck',
      ),
      'sections': Ack.list(deckPlanSectionSchema).describe(
        'Ordered narrative sections whose slide keys partition the deck',
      ),
      'slides': Ack.list(
        deckPlanSlideSchema,
      ).describe('Ordered list of slides in the presentation'),
    }).describe(
      'Presentation deck plan with narrative, style, and composition intent',
    );
