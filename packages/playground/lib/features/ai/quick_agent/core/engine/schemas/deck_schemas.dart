import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:superdeck_core/superdeck_core.dart' show HexColorValidation;

import '../../../../../../../core/domain/design/presentation_theme_catalog.dart';

part 'deck_schemas.g.dart';

/// Schema definitions for SuperDeck presentation generation.
///
/// The slide portion comes from `superdeck_core`'s [aiSlideSchema], the
/// AI-compatible projection of the canonical slide contract — Playground owns
/// only the generation theme contract and prompt guidance. Schemas are compatible with
/// Google Generative AI via `.toJsonSchemaBuilder()`.

// ============================================================================
// THEME REFERENCE SCHEMAS
// ============================================================================

const deckDesignDirections = presentationThemeDirections;
const deckDensityProfiles = presentationThemeDensityProfiles;
const deckTypeScales = presentationThemeTypeScales;

@AckType(name: 'DeckBrandColors')
final deckBrandColorsSchema = Ack.object({
  'background': Ack.string().hexColor().optional(),
  'surface': Ack.string().hexColor().optional(),
  'surfaceAlt': Ack.string().hexColor().optional(),
  'heading': Ack.string().hexColor().optional(),
  'body': Ack.string().hexColor().optional(),
  'accent': Ack.string().hexColor().optional(),
  'accentContrast': Ack.string().hexColor().optional(),
}).describe('Only exact palette roles supplied by the user');

@AckType(name: 'DeckBrandFonts')
final deckBrandFontsSchema = Ack.object({
  'headline': Ack.string().optional(),
  'body': Ack.string().optional(),
}).describe('Only exact registered font families supplied by the user');

@AckType(name: 'DeckBrandOverride')
final deckBrandOverrideSchema = Ack.object({
  'colors': deckBrandColorsSchema.optional(),
  'fonts': deckBrandFontsSchema.optional(),
}).describe('Validated user-only overrides layered on the selected theme');

@AckType(name: 'DeckThemeReference')
final deckThemeReferenceSchema = Ack.object({
  'id': Ack.string().notEmpty().describe('Stable catalog theme ID'),
  'version': Ack.integer().positive().describe(
    'Exact catalog version attached by the application',
  ),
  'density': Ack.enumString(
    deckDensityProfiles,
  ).describe('Resolved deck density supported by the selected theme'),
  'brandOverride': deckBrandOverrideSchema.optional().describe(
    'Exact user-supplied palette or typography constraints, if any',
  ),
}).describe('Canonical versioned presentation-theme reference');

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
