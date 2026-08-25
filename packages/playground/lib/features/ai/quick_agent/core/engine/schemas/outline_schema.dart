import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import 'deck_schemas.dart';

part 'outline_schema.ack.dart';
part 'outline_schema.ack.g.dart';

/// Schema definitions for presentation planning (Phase 1).
///
/// The deck plan captures the narrative, shared theme, and enough composition
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
  'webview',
  'dartpad',
  'custom',
];

const deckPlanElementTypes = ['image', 'webview', 'dartpad', 'custom'];

const deckPlanTreatments = [
  'hero',
  'section',
  'content',
  'data',
  'quote',
  'visual',
  'closing',
];

@AckInfer(name: 'DeckPlanSection')
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
@AckInfer(name: 'DeckPlanElement')
final deckPlanElementSchema = Ack.object({
  'type': Ack.enumString(
    deckPlanElementTypes,
  ).describe('Generation-capable element needed by the slide'),
  'purpose': Ack.string().describe('Why this element belongs on the slide'),
  'source': Ack.string().optional().describe(
    'User-supplied asset path, URL, text, or gist identifier when available',
  ),
  'generationPrompt': Ack.string().optional().describe(
    'Concrete visual subject to generate when an image style is configured',
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
@AckInfer(name: 'DeckPlanSlide')
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
@AckInfer(name: 'DeckPlan')
final deckPlanSchema =
    Ack.object({
      'topic': Ack.string().describe('Main topic of the presentation'),
      'story': Ack.string().describe(
        'One-sentence narrative through-line for the complete presentation',
      ),
      'theme': deckThemeReferenceSchema.describe(
        'Application-resolved theme reference for the complete deck',
      ),
      'sections': Ack.list(deckPlanSectionSchema).describe(
        'Ordered narrative sections whose slide keys partition the deck',
      ),
      'slides': Ack.list(
        deckPlanSlideSchema,
      ).describe('Ordered list of slides in the presentation'),
    }).describe(
      'Presentation deck plan with narrative, theme, and composition intent',
    );

/// Builds the model-facing deck-plan schema for one deterministic shortlist.
///
/// The model can select only one eligible ID. Catalog version, density, full
/// recipe, and user brand overrides are attached by Dart after parsing.
ObjectSchema buildDeckPlanDraftSchema(
  List<String> eligibleThemeIds, {
  List<String> allowedCompositionIntents = deckPlanCompositionIntents,
  List<String> allowedElementTypes = deckPlanElementTypes,
  bool allowElementSources = true,
  bool requireImageGenerationPrompt = false,
}) {
  if (eligibleThemeIds.isEmpty) {
    throw ArgumentError('At least one eligible theme ID is required.');
  }
  if (allowedCompositionIntents.isEmpty) {
    throw ArgumentError('At least one composition intent is required.');
  }

  return Ack.object({
    'topic': Ack.string().describe('Main topic of the presentation'),
    'story': Ack.string().describe(
      'One-sentence narrative through-line for the complete presentation',
    ),
    'theme': Ack.object({
      'id': Ack.enumString(
        eligibleThemeIds,
      ).describe('Exact ID selected from the eligible theme candidates'),
    }).describe('Model-selected theme ID only'),
    'sections': Ack.list(deckPlanSectionSchema).describe(
      'Ordered narrative sections whose slide keys partition the deck',
    ),
    'slides': Ack.list(
      buildDeckPlanDraftSlideSchema(
        allowedCompositionIntents: allowedCompositionIntents,
        allowedElementTypes: allowedElementTypes,
        allowElementSources: allowElementSources,
        requireImageGenerationPrompt: requireImageGenerationPrompt,
      ),
    ).describe('Ordered list of slides in the presentation'),
  }).describe('Model-facing deck-plan draft with bounded theme selection');
}

/// Builds the model-facing slide plan from capabilities present in the request.
ObjectSchema buildDeckPlanDraftSlideSchema({
  List<String> allowedCompositionIntents = deckPlanCompositionIntents,
  List<String> allowedElementTypes = deckPlanElementTypes,
  bool allowElementSources = true,
  bool requireImageGenerationPrompt = false,
}) {
  final elementSchema = allowedElementTypes.isEmpty
      ? null
      : Ack.object({
          'type': Ack.enumString(
            allowedElementTypes,
          ).describe('Generation-capable element needed by the slide'),
          'purpose': Ack.string().describe(
            'Why this element belongs on the slide',
          ),
          if (allowElementSources)
            'source': Ack.string().optional().describe(
              'Exact user-supplied source when available',
            ),
          'generationPrompt': requireImageGenerationPrompt
              ? Ack.string().describe('Concrete visual subject to generate')
              : Ack.string().optional().describe(
                  'Concrete visual subject to generate for an image',
                ),
          if (allowedElementTypes.contains('custom'))
            'widgetName': Ack.string().optional().describe(
              'Registered widget name when type is custom',
            ),
        });

  return Ack.object({
    'key': Ack.string().describe('Unique descriptive kebab-case slide ID'),
    'title': Ack.string().describe('Short working slide title'),
    'sectionKey': Ack.string().describe('Owning narrative section key'),
    'assertion': Ack.string().describe('Single audience-facing claim'),
    'contentUnits': Ack.list(
      Ack.string(),
    ).describe('Concrete evidence, examples, or implications'),
    'narrativeRole': Ack.enumString(
      deckPlanNarrativeRoles,
    ).describe('Narrative job performed by the slide'),
    'composition': Ack.enumString(
      allowedCompositionIntents,
    ).describe('Semantic composition chosen for the information shape'),
    if (elementSchema != null)
      'elements': Ack.list(elementSchema).optional().describe(
        'Optional grounded or generated elements required by the slide',
      ),
  }).describe('Lean slide plan enriched by the application after generation');
}

/// Lean model-owned fields; Dart derives the remaining canonical plan fields.
final deckPlanDraftSlideSchema = Ack.object({
  'key': Ack.string().describe('Unique descriptive kebab-case slide ID'),
  'title': Ack.string().describe('Short working slide title'),
  'sectionKey': Ack.string().describe('Owning narrative section key'),
  'assertion': Ack.string().describe('Single audience-facing claim'),
  'contentUnits': Ack.list(
    Ack.string(),
  ).describe('Concrete evidence, examples, or implications'),
  'narrativeRole': Ack.enumString(
    deckPlanNarrativeRoles,
  ).describe('Narrative job performed by the slide'),
  'composition': Ack.enumString(
    deckPlanCompositionIntents,
  ).describe('Semantic composition chosen for the information shape'),
  'elements': Ack.list(deckPlanElementSchema).optional().describe(
    'Optional grounded or generated elements required by the slide',
  ),
}).describe('Lean slide plan enriched by the application after generation');
