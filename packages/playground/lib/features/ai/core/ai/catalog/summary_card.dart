import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:provider/provider.dart' as prov;
import 'package:remix/remix.dart';
import 'package:playground/features/ai/core/ai/wizard_context.dart';
import 'package:playground/features/ai/core/ai/prompts/font_styles.dart';
import 'package:playground/features/ai/core/ai/prompts/image_style_prompts.dart';
import 'package:playground/features/ai/core/ai/schemas/genui_action_schema.dart';
import 'package:playground/features/ai/core/ai/schemas/wizard_context_keys.dart';
import 'package:playground/features/ai/core/ai/services/prompt_builder.dart';
import 'package:playground/features/ai/core/debug_logger.dart';
import 'package:playground/features/ai/core/ui/ui.dart';
import 'package:playground/features/ai/core/utils/color_utils.dart';
import 'package:playground/features/ai/core/utils/font_utils.dart';
import 'package:playground/features/ai/ai_progress_screen.dart';
import 'package:playground/stores/ai_store.dart';

part 'summary_card.g.dart';
part 'summary_card_view.dart';

enum SummaryItemKind { text, style, imageStyle }

/// Schema for summary item with optional fields for different item types.
@AckType(name: 'SummaryItem')
final _summaryItemSchema = Ack.object({
  'kind': Ack.enumValues<SummaryItemKind>(
    SummaryItemKind.values,
  ).optional().describe('Discriminator for summary payload shape'),
  'label': Ack.string().describe('The category label for this selection'),
  'title': Ack.string().optional().describe(
    'The primary text representing the user\'s choice',
  ),
  'description': Ack.string().optional().describe(
    'Additional details about the selection',
  ),
  'text': Ack.string().optional().describe(
    'Plain text content for simple display items',
  ),
  'colors': Ack.list(
    Ack.string().describe('Hex color value'),
  ).optional().describe('List of hex color strings for the style palette'),
  'headlineFont': Ack.enumValues<HeadlineFont>(
    HeadlineFont.values,
  ).optional().describe(HeadlineFont.schemaDescription),
  'bodyFont': Ack.enumValues<BodyFont>(
    BodyFont.values,
  ).optional().describe(BodyFont.schemaDescription),
  'imageStyleId': Ack.enumValues<ImageStyle>(
    ImageStyle.values,
  ).optional().describe(ImageStyle.schemaDescription()),
}).describe('Summary item representing a user selection');

/// Schema for SummaryCard component using ACK fluent API.
@AckType(name: 'SummaryCard')
final _summaryCardSchema =
    Ack.object({
      'title': Ack.string().describe('The main heading of the summary card'),
      'items': Ack.list(
        _summaryItemSchema,
      ).describe('List of summary items representing user selections'),
      'generateSlidesAction': actionSchema,
    }).describe(
      'Summary card showing recap of all user selections before finalizing',
    );

/// Extension for SummaryItemType to add computed properties.
extension SummaryItemExt on SummaryItemType {
  /// Returns true if this item has style data (colors and fonts).
  bool get hasStyleData =>
      colors != null && headlineFont != null && bodyFont != null;

  /// Returns true if this item has image style data.
  bool get hasImageStyleData => imageStyleId != null;

  /// Validates supported field combinations for summary rendering.
  ///
  /// This keeps backward compatibility with the current schema while surfacing
  /// malformed payloads early.
  String? get shapeValidationError {
    final hasTitleOrText = title != null || text != null;
    final hasAnyStyleFields =
        colors != null || headlineFont != null || bodyFont != null;

    final explicitKind = kind;
    if (explicitKind != null) {
      switch (explicitKind) {
        case SummaryItemKind.style:
          if (!hasStyleData) {
            return 'style kind requires colors/headlineFont/bodyFont';
          }
          if (imageStyleId != null) {
            return 'style kind should not include imageStyleId';
          }
          if (!hasTitleOrText) {
            return 'style kind requires title or text';
          }
          return null;
        case SummaryItemKind.imageStyle:
          if (imageStyleId == null) {
            return 'imageStyle kind requires imageStyleId';
          }
          if (hasAnyStyleFields) {
            return 'imageStyle kind should not include style palette fields';
          }
          return null;
        case SummaryItemKind.text:
          if (!hasTitleOrText) {
            return 'text kind requires title or text';
          }
          if (hasAnyStyleFields || imageStyleId != null) {
            return 'text kind should not include style or imageStyle fields';
          }
          return null;
      }
    }

    if (hasAnyStyleFields && !hasStyleData) {
      return 'style item is missing colors/headlineFont/bodyFont';
    }

    if (hasImageStyleData && hasAnyStyleFields) {
      return 'imageStyleId should not be combined with style palette fields';
    }

    if (!hasStyleData && !hasImageStyleData && !hasTitleOrText) {
      return 'item must include either title or text';
    }

    return null;
  }
}

/// A summary card that displays a recap of all user selections before finalizing.
///
/// Shows multiple items with labels and values. Items with color and font data
/// are rendered as style previews, otherwise they display as title/description pairs.
final summaryCard = CatalogItem(
  name: 'SummaryCard',
  dataSchema: _summaryCardSchema.toJsonSchemaBuilder(),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "SummaryCard": {
              "title": "Summary",
              "items": [
                {
                  "kind": "text",
                  "label": "Topic",
                  "title": "Introduction to Astronomy",
                  "description": "A beginner-friendly overview of space and celestial objects"
                },
                {
                  "kind": "text",
                  "label": "Audience",
                  "title": "Middle School Students",
                  "description": "Ages 11-14"
                },
                {
                  "kind": "text",
                  "label": "Approach",
                  "title": "Interactive & Visual",
                  "description": "Engaging visuals with hands-on examples"
                },
                {
                  "kind": "text",
                  "label": "Emphasis",
                  "text": "Planets, Stars, Space Exploration"
                },
                {
                  "kind": "text",
                  "label": "Slide Count",
                  "text": "12 slides"
                },
                {
                  "kind": "style",
                  "label": "Style",
                  "title": "Cosmic Blue",
                  "description": "Deep space theme with vibrant accents",
                  "colors": ["#0F172A", "#60A5FA", "#94A3B8"],
                  "headlineFont": "oswald",
                  "bodyFont": "inter"
                },
                {
                  "kind": "imageStyle",
                  "label": "Image Style",
                  "imageStyleId": "minimalist"
                }
              ],
              "generateSlidesAction": {
                "name": "generate_slides",
                "context": []
              }
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (catalogContext) {
    final data = SummaryCardType.parse(catalogContext.data);

    // Use ActionType for type-safe action parsing with validation
    final action = ActionType.parse(data.generateSlidesAction);
    final contextDefinition = action.context ?? [];

    return Builder(
      builder: (buildContext) {
        return SummaryCard(
          title: data.title,
          items: data.items.toList(),
          generateSlides: () {
            debugLog.section('Generate Slides Triggered');

            // Extract context from displayed summary items
            final extractedContext = _extractContextFromItems(
              data.items.toList(),
            );
            debugLog.userAction('GENERATE_SLIDES', extractedContext.toMap());

            // Merge with any path-resolved context from the action
            final resolvedContext = WizardContext.fromMap(
              resolveContext(catalogContext.dataContext, contextDefinition),
            );
            final finalContext = extractedContext.merge(resolvedContext);
            debugLog.log('GEN', 'Final context: ${finalContext.toMap()}');

            // Build the prompt string from wizard context.
            final prompt = buildPromptFromWizardContext(finalContext);
            final imageStyleId = finalContext.imageStyleId;
            final backgroundColor = finalContext.colors?.firstOrNull;

            debugLog.log(
              'GEN',
              'Routing generation through AiStore. prompt length: ${prompt.length}',
            );

            // Read AiStore from the app-level Provider tree.
            final aiStore = prov.Provider.of<AiStore>(
              buildContext,
              listen: false,
            );

            // Fire-and-forget — AiStore manages all reactive state.
            aiStore.generate(
              prompt,
              imageStyleId: imageStyleId,
              backgroundColor: backgroundColor,
            );

            // Navigate to the progress screen immediately.
            if (buildContext.mounted) {
              Navigator.of(buildContext).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const AiProgressScreen(),
                ),
              );
            }
          },
        );
      },
    );
  },
);
