import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:superdeck_core/superdeck_core.dart' show HexColorValidation;

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
  'background': Ack.string().hexColor().describe(
    'Background hex color for slides',
  ),
  'surface': Ack.string().hexColor().describe(
    'Primary elevated surface hex color',
  ),
  'surfaceAlt': Ack.string().hexColor().describe(
    'Secondary elevated surface hex color',
  ),
  'heading': Ack.string().hexColor().describe('Hex color for heading text'),
  'body': Ack.string().hexColor().describe('Hex color for body text'),
  'accent': Ack.string().hexColor().describe(
    'Accent hex color for emphasis and decoration',
  ),
  'accentContrast': Ack.string().hexColor().describe(
    'Readable text/icon hex color placed on the accent color',
  ),
}).describe('Color palette for the presentation');
final colorsSchema = _deckColorsSchema;

/// Schema for typography configuration.
///
/// Defines the font families used for headlines and body text.
/// Families are validated against the injected presentation typography catalog
/// after parsing, which also permits application-registered bundled fonts.
@AckType(name: 'DeckFonts')
final _deckFontsSchema = Ack.object({
  'headline': Ack.string().describe(
    'Exact registered font family for display and heading text',
  ),
  'body': Ack.string().describe(
    'Exact registered font family for paragraphs, lists, and tables',
  ),
}).describe('Typography configuration');
final fontsSchema = _deckFontsSchema;

const deckDesignDirections = [
  'editorial',
  'minimal',
  'bold',
  'technical',
  'playful',
];

const deckDensityProfiles = ['spacious', 'balanced', 'compact'];

const deckTypeScales = ['dramatic', 'balanced', 'dense'];

/// Schema for global style configuration.
///
/// Combines color palette and typography settings with a style name.
@AckType(name: 'DeckStyle')
final styleSchema = Ack.object({
  'name': Ack.string().describe('Style name identifier'),
  'direction': Ack.enumString(
    deckDesignDirections,
  ).describe('Semantic visual direction mapped to safe Dart styling'),
  'density': Ack.enumString(
    deckDensityProfiles,
  ).describe('Default content-density profile for the deck'),
  'typeScale': Ack.enumString(
    deckTypeScales,
  ).describe('Semantic presentation-scale typography profile'),
  'colors': _deckColorsSchema,
  'fonts': _deckFontsSchema,
}).describe('Global style configuration for the deck');

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
