import 'package:ack/ack.dart';

/// Schema definitions for presentation outline generation (Phase 1).
///
/// The outline is a lightweight structure that captures:
/// - Slide topics and purposes
/// - Layout hints for variety
///
/// This is generated first so the AI can plan the deck structure before
/// writing the full slide content.

// ============================================================================
// SLIDE OUTLINE SCHEMA
// ============================================================================

/// Layout hint values for slide structure guidance.
const _layoutHintValues = [
  'title',
  'content',
  'two-column',
  'three-column',
  'quote',
  'title-left',
];

/// Schema for a single slide in the outline.
///
/// Contains the essential planning information:
/// - key: Unique identifier for referencing in later phases
/// - title: Working title (may be refined in final deck)
/// - purpose: What the slide will communicate
/// - layoutHint: Suggested layout type for variety
final outlineSlideSchema = Ack.object({
  'key': Ack.string().describe(
    'Unique identifier for this slide (e.g., "intro", "slide-1", "conclusion")',
  ),
  'title': Ack.string().describe(
    'Working title for this slide (may be refined in final generation)',
  ),
  'purpose': Ack.string().describe(
    'Brief description of what this slide will communicate (1-2 sentences)',
  ),
  'layoutHint': Ack.enumString(
    _layoutHintValues,
  ).describe('Suggested layout type for this slide'),
  'imageRequirement':
      Ack.object({
        'subject': Ack.string().describe(
          'Concrete visual subject that reinforces this slide without text',
        ),
      }).optional().describe(
        'Omit when imagery would be decorative, distracting, or redundant',
      ),
}).describe('A single slide in the presentation outline');

// ============================================================================
// ROOT OUTLINE SCHEMA
// ============================================================================

/// Schema for the complete presentation outline.
///
/// Root schema for Phase 1 generation, containing the topic
/// and ordered list of slide outlines.
final outlineSchema = Ack.object({
  'topic': Ack.string().describe('Main topic of the presentation'),
  'slides': Ack.list(
    outlineSlideSchema,
  ).describe('Ordered list of slides in the presentation'),
}).describe('Presentation outline with structure');
