import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import '../../debug_logger.dart';

import 'ask_user_checkbox.dart';
import 'ask_user_image_style.dart';
import 'ask_user_radio.dart';
import 'ask_user_slider.dart';
import 'ask_user_style.dart';
import 'ask_user_text.dart';
import 'remix_component_preview.dart';
import 'summary_card.dart';

export 'ask_user_checkbox.dart';
export 'ask_user_image_style.dart';
export 'ask_user_radio.dart';
export 'ask_user_slider.dart';
export 'ask_user_style.dart';
export 'ask_user_text.dart';
export 'remix_component_preview.dart';
export 'summary_card.dart';

/// Wraps a CatalogItem's widgetBuilder with error handling.
/// Catches parse/build errors and returns fallback UI.
CatalogItem withCatalogErrorHandling(CatalogItem item) {
  return CatalogItem(
    name: item.name,
    dataSchema: item.dataSchema,
    exampleData: item.exampleData,
    widgetBuilder: (context) {
      try {
        return item.widgetBuilder(context);
      } catch (e, stack) {
        debugLog.error(
          item.name,
          'Failed to build: $e\nData: ${context.data}',
          stack,
        );
        return Center(child: Text('Failed to load ${item.name}'));
      }
    },
  );
}

/// SuperDeck AI chat catalog with GenUI components.
///
/// Components:
/// - [askUserRadio] - Radio button single selection
/// - [askUserCheckbox] - Checkbox multiple selection
/// - [askUserSlider] - Slider numeric input
/// - [askUserText] - Free-form text input
/// - [askUserStyle] - Visual style selection with colors and fonts
/// - [askUserImageStyle] - Image style selection with generated previews
/// - [summaryCard] - Wizard summary with aggregated selections
final chatCatalog = Catalog([
  withCatalogErrorHandling(askUserRadio),
  withCatalogErrorHandling(askUserCheckbox),
  withCatalogErrorHandling(askUserSlider),
  withCatalogErrorHandling(askUserText),
  withCatalogErrorHandling(askUserStyle),
  withCatalogErrorHandling(askUserImageStyle),
  withCatalogErrorHandling(summaryCard),
  withCatalogErrorHandling(remixComponentPreview),
], catalogId: 'com.superdeck.ai.chat');
