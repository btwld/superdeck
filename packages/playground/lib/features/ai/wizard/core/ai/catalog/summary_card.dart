import 'dart:async';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as prov;
import 'package:remix/remix.dart';
import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../wizard_context.dart';
import '../prompts/image_style_prompts.dart';
import '../schemas/genui_action_schema.dart';
import '../schemas/wizard_context_keys.dart';
import '../services/prompt_builder.dart';
import '../../debug_logger.dart';
import '../../ui/ui.dart';
import '../../utils/color_utils.dart';
import '../../../../quick_agent/domain/commands/generate_deck_command.dart';
import 'component_schema.dart';
import 'presentation_theme_component_schema.dart';
import 'typed_catalog_item.dart';
import 'user_action_dispatch.dart';

part 'summary_card.g.dart';
part 'summary_card_view.dart';

enum SummaryItemKind { text, theme, imageStyle }

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
  'themeId': Ack.string().optional().describe(
    'Exact registered presentation theme ID',
  ),
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
  /// Returns true if this item references a registered presentation theme.
  bool get hasThemeData => themeId != null;

  /// Returns true if this item has image style data.
  bool get hasImageStyleData => imageStyleId != null;

  bool get hasTitleOrText {
    final titleValue = this['title'];
    final textValue = this['text'];
    return (titleValue is String && titleValue.isNotEmpty) ||
        (textValue is String && textValue.isNotEmpty);
  }

  /// Validates supported field combinations for summary rendering.
  String? get shapeValidationError {
    final explicitKind = kind;
    if (explicitKind != null) {
      switch (explicitKind) {
        case .theme:
          if (!hasThemeData) {
            return 'theme kind requires themeId';
          }
          if (imageStyleId != null) {
            return 'theme kind should not include imageStyleId';
          }
          return null;
        case SummaryItemKind.imageStyle:
          if (imageStyleId == null) {
            return 'imageStyle kind requires imageStyleId';
          }
          if (themeId != null) {
            return 'imageStyle kind should not include themeId';
          }
          return null;
        case SummaryItemKind.text:
          if (!hasTitleOrText) {
            return 'text kind requires title or text';
          }
          if (themeId != null || imageStyleId != null) {
            return 'text kind should not include theme or imageStyle fields';
          }
          return null;
      }
    }

    if (hasImageStyleData && hasThemeData) {
      return 'imageStyleId should not be combined with themeId';
    }

    if (!hasThemeData && !hasImageStyleData && !hasTitleOrText) {
      return 'item must include themeId, imageStyleId, title, or text';
    }

    return null;
  }
}

/// A summary card that displays a recap of all user selections before finalizing.
///
/// Shows multiple items with labels and values. Theme items resolve their
/// preview from the injected catalog; other items show text details.
CatalogItem summaryCardFor(PresentationThemeCatalog themeCatalog) {
  final exampleThemeId = themeCatalog.currentThemes.first.id;

  return typedCatalogItem<SummaryCardType>(
    name: 'SummaryCard',
    dataSchema: componentSchema(
      schemaWithPresentationThemeIds(
        _summaryCardSchema.toJsonSchemaBuilder(),
        themeCatalog,
        paths: const [
          ['properties', 'items', 'items', 'properties', 'themeId'],
        ],
      ),
    ),
    exampleData: [
      () =>
          '''
      [
        {
          "id": "root",
          "component": "SummaryCard",
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
              "kind": "theme",
              "label": "Style",
              "themeId": "$exampleThemeId"
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
      ]
    ''',
    ],
    parse: (data) => parseSummaryCard(data, themeCatalog: themeCatalog),
    widgetBuilder: (catalogContext, data) {
      final action = data.generateSlidesAction;

      return Builder(
        builder: (buildContext) {
          return SummaryCard(
            title: data.title,
            items: data.items.toList(),
            themeCatalog: themeCatalog,
            generateSlides: () {
              unawaited(() async {
                debugLog.section('Generate Slides Triggered');
                final command = prov.Provider.of<GenerateDeckCommand>(
                  buildContext,
                  listen: false,
                );

                // Extract context from displayed summary items
                final extractedContext = extractWizardContextFromSummaryItems(
                  data.items.toList(),
                );
                debugLog.userAction(
                  'GENERATE_SLIDES',
                  extractedContext.toMap(),
                );

                // Merge with any path-resolved context from the action
                final resolvedContext = WizardContext.fromMap(
                  await resolveCatalogActionContext(
                    itemContext: catalogContext,
                    action: action,
                  ),
                );
                final finalContext = extractedContext.merge(resolvedContext);
                debugLog.log('GEN', 'Final context: ${finalContext.toMap()}');

                // Preserve exact wizard selections in the typed generation
                // request handed to the shared editor command.
                final request = buildPromptFromWizardContext(finalContext);
                debugLog.log(
                  'GEN',
                  'Routing generation through GenerateDeckCommand. '
                      'slides: ${request.slideCount}',
                );

                // Fire-and-forget — the command manages running/phase/result and
                // loads the generated markdown into the editor on success.
                unawaited(command(request));
              }());
            },
          );
        },
      );
    },
  );
}

final summaryCard = summaryCardFor(PresentationThemeCatalog.withDefaults());

SummaryCardType parseSummaryCard(
  Object? data, {
  required PresentationThemeCatalog themeCatalog,
}) {
  final parsed = SummaryCardType.parse(data);
  final unknownIds = parsed.items
      .map((item) => item.themeId)
      .whereType<String>()
      .where((themeId) => themeCatalog.current(themeId) == null)
      .toSet();
  if (unknownIds.isNotEmpty) {
    throw FormatException(
      'Unknown presentation theme IDs: ${unknownIds.join(", ")}.',
    );
  }

  return parsed;
}
