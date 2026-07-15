import 'package:genui/genui.dart';

import '../../../../../../core/domain/design/presentation_theme_catalog.dart';

import 'ask_user_checkbox.dart';
import 'ask_user_radio.dart';
import 'ask_user_slider.dart';
import 'ask_user_style.dart';

export 'ask_user_checkbox.dart';
export 'ask_user_radio.dart';
export 'ask_user_slider.dart';
export 'ask_user_style.dart';

/// SuperDeck AI chat catalog with GenUI components.
///
/// Components:
/// - [askUserRadio] - Radio button single selection
/// - [askUserCheckbox] - Checkbox multiple selection
/// - [askUserSlider] - Slider numeric input
/// - [askUserStyle] - Catalog-backed presentation theme selection
///
/// Image-style selection is intentionally omitted for v1 (no image generation).
Catalog chatCatalogFor(PresentationThemeCatalog themeCatalog) {
  return Catalog([
    askUserRadio,
    askUserCheckbox,
    askUserSlider,
    askUserStyleFor(themeCatalog),
  ], catalogId: 'com.superdeck.ai.chat');
}

final chatCatalog = chatCatalogFor(PresentationThemeCatalog.withDefaults());
