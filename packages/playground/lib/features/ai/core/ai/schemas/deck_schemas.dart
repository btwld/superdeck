import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import '../prompts/font_styles.dart';

part 'deck_schemas.g.dart';

/// Schema definitions for SuperDeck presentation generation.
///
/// These schemas use the ACK fluent API for consistency with catalog schemas.
/// They are compatible with Google Generative AI via `.toJsonSchemaBuilder()`.

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
// SLIDE CONTENT SCHEMAS
// ============================================================================

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

/// Schema for a content or widget block.
///
/// Blocks can be either:
/// - Content blocks (type: "block"): Contain markdown content
/// - Widget blocks (type: "widget"): Reference named widgets
@AckType(name: 'SlideBlock')
final _slideBlockSchema = Ack.object({
  'type': Ack.enumString(['block', 'widget']).describe(
    'Block type: "block" for markdown content, "widget" for named widget reference',
  ),
  'content': Ack.string().optional().describe(
    'Markdown content (required for type "block")',
  ),
  'name': Ack.string().optional().describe(
    'Widget name (required for type "widget")',
  ),
  'flex': Ack.integer().optional().describe(
    'Flex weight for proportional sizing. Higher values take more space.',
  ),
  'align': Ack.enumString(
    _alignmentValues,
  ).optional().describe('Content alignment'),
  'scrollable': Ack.boolean().optional().describe(
    'Whether this block is scrollable',
  ),
}).describe('A content or widget block');
final blockSchema = _slideBlockSchema;

/// Schema for a section containing blocks.
///
/// Sections represent horizontal rows in a slide, containing one or more
/// blocks laid out as columns.
@AckType(name: 'SlideSection')
final _slideSectionSchema = Ack.object({
  'type': Ack.literal('section').describe('Section type discriminator'),
  'flex': Ack.integer().optional().describe(
    'Flex weight for proportional sizing. Higher values take more space.',
  ),
  'align': Ack.enumString(
    _alignmentValues,
  ).optional().describe('Content alignment within section'),
  'scrollable': Ack.boolean().optional().describe(
    'Whether this section is scrollable',
  ),
  'blocks': Ack.list(
    _slideBlockSchema,
  ).describe('Content blocks in this section'),
}).describe('A section containing blocks');
final sectionSchema = _slideSectionSchema;

// ============================================================================
// SLIDE SCHEMAS
// ============================================================================

/// Schema for slide options.
///
/// Contains metadata about the slide such as title and style reference.
@AckType(name: 'SlideOptions')
final _slideOptionsSchema = Ack.object({
  'title': Ack.string().optional().describe(
    'Slide title displayed in navigation',
  ),
  'style': Ack.string().optional().describe(
    'Style name reference matching a defined style',
  ),
}).describe('Slide options');
final slideOptionsSchema = _slideOptionsSchema;

/// Schema for a single slide.
///
/// Each slide contains a unique key, optional metadata, and a vertical stack
/// of sections. Images are handled separately via the outline phase.
@AckType(name: 'Slide')
final slideSchema = Ack.object({
  'key': Ack.string().describe('Unique slide identifier using kebab-case'),
  'options': _slideOptionsSchema.optional(),
  'comments': Ack.list(
    Ack.string().describe('A speaker note or talking point for this slide'),
  ).optional().describe('Speaker notes'),
  'sections': Ack.list(
    _slideSectionSchema,
  ).describe('Horizontal sections in the slide'),
}).describe('A single slide');

/// Schema for slide creation payloads.
///
/// Matches [slideSchema], but allows omitting `key` so callers can request
/// automatic key generation.
@AckType(name: 'CreateSlide')
final createSlideSchema = Ack.object({
  'key': Ack.string().optional().describe(
    'Optional slide identifier. When missing, a key can be generated.',
  ),
  'options': _slideOptionsSchema.optional(),
  'comments': Ack.list(
    Ack.string().describe('A speaker note or talking point for this slide'),
  ).optional().describe('Speaker notes'),
  'sections': Ack.list(
    _slideSectionSchema,
  ).describe('Horizontal sections in the slide'),
}).describe('A slide payload accepted by createSlide');

// ============================================================================
// ROOT SCHEMA
// ============================================================================

/// Schema for the complete slide generation output.
///
/// Root schema for SuperDeck presentation generation, containing the slides
/// array and global style configuration.
@AckType(name: 'SlideGeneration')
final _slideGenerationSchema = Ack.object({
  'slides': Ack.list(
    slideSchema,
  ).describe('Array of slides in the presentation'),
  'style': styleSchema,
}).describe('A SuperDeck presentation with slides and style');
final slideGenerationSchema = _slideGenerationSchema;

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

// ============================================================================
// AVAILABLE IMAGES CONTEXT
// ============================================================================

/// Builds the available images context for Phase 3 prompt injection.
///
/// This creates a human-readable list of available images that the AI
/// can reference when generating the final deck structure. The AI will
/// use this to decide where to place images in slide content.
///
/// Example output:
/// ```
/// Available images for your slides:
/// - intro: .superdeck/assets/slide-intro-illustration.png
/// - slide-1: .superdeck/assets/slide-slide-1-illustration.png
///
/// Include these paths in slide content as markdown images where appropriate.
/// ```
String buildAvailableImagesContext(Map<String, String> availableImages) {
  if (availableImages.isEmpty) {
    return 'No images were generated for this presentation.';
  }

  final buffer = StringBuffer('Available images for your slides:\n');
  for (final entry in availableImages.entries) {
    buffer.writeln('- ${entry.key}: ${entry.value}');
  }
  buffer.writeln(
    '\nInclude these paths in slide content as markdown images '
    '(e.g., `![description](path)`) where they enhance the slide.',
  );
  return buffer.toString();
}
