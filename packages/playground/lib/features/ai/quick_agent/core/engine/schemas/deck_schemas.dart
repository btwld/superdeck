import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:superdeck_core/superdeck_core.dart' show aiSlideSchema;

import '../prompts/font_styles.dart';

part 'deck_schemas.g.dart';

/// Schema definitions for SuperDeck presentation generation.
///
/// The slide portion comes from `superdeck_core`'s [aiSlideSchema], the
/// AI-compatible projection of the canonical slide contract — Playground owns
/// only the style schema and prompt guidance. Schemas are compatible with
/// Google Generative AI via `.toJsonSchemaBuilder()`.

// ============================================================================
// STYLE SCHEMAS
// ============================================================================

/// Schema for color palette configuration.
///
/// Defines the background, heading, and body colors for the presentation theme.
/// Colors must be provided as hex strings. The semantic roles are:
/// - background: Slide background color
/// - heading: Heading/title text color
/// - body: Body text color
@AckType(name: 'DeckColors')
final _deckColorsSchema = Ack.object({
  'background': Ack.string().describe('Background hex color for slides'),
  'heading': Ack.string().describe('Hex color for heading text'),
  'body': Ack.string().describe('Hex color for body text'),
}).describe('Color palette for the presentation');
final colorsSchema = _deckColorsSchema;

/// Schema for typography configuration.
///
/// Defines the font families used for headlines and body text.
/// Uses predefined font enums to ensure only valid Google Fonts are used.
@AckType(name: 'DeckFonts')
final _deckFontsSchema = Ack.object({
  'headline': Ack.enumValues<HeadlineFont>(
    HeadlineFont.values,
  ).describe(HeadlineFont.schemaDescription),
  'body': Ack.enumValues<BodyFont>(
    BodyFont.values,
  ).describe(BodyFont.schemaDescription),
}).describe('Typography configuration');
final fontsSchema = _deckFontsSchema;

/// Schema for global style configuration.
///
/// Combines color palette and typography settings with a style name.
@AckType(name: 'DeckStyle')
final styleSchema = Ack.object({
  'name': Ack.string().describe('Style name identifier'),
  'colors': _deckColorsSchema,
  'fonts': _deckFontsSchema,
}).describe('Global style configuration for the deck');

// ============================================================================
// ROOT SCHEMA
// ============================================================================

/// Schema for the complete slide generation output.
///
/// Root schema for SuperDeck presentation generation: the slides array uses
/// the canonical AI projection exported by `superdeck_core`, so any layout
/// contract change in core reaches AI generation automatically.
final slideGenerationSchema = Ack.object({
  'slides': Ack.list(
    aiSlideSchema,
  ).describe('Array of slides in the presentation'),
  'style': styleSchema,
}).describe('A SuperDeck presentation with slides and style');

// ============================================================================
// PROMPT GUIDANCE
// ============================================================================

/// Prompt guidance for slide generation.
///
/// Provides field-specific examples and behavioral context for the AI model.
/// This should be included in the prompt, not duplicated in schema descriptions.
///
/// References field names from the schema to maintain a single source of truth.
String getSlideGenerationGuidance() {
  return '''
## Field Guidance

### Slide Keys
Use descriptive kebab-case identifiers that reflect slide purpose:
- Opening slides: "slide-intro", "slide-welcome", "slide-title"
- Content slides: "slide-overview", "slide-features", "slide-benefits"
- Closing slides: "slide-summary", "slide-conclusion", "slide-next-steps"

### Flex Values
Control proportional sizing with flex weights:
- Use 1:3 ratio for title + body (prevents content cropping)
- Use equal flex (1:1) for side-by-side comparisons
- Use weighted flex (2:3) when one column needs emphasis

### Content Alignment
Position content based on its role:
- Titles and hero text: "center"
- Body content and bullets: "topLeft"
- Captions and attributions: "bottomRight" or "bottomCenter"
''';
}
