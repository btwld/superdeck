import 'package:genui/genui.dart';

import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../../../core/domain/design/presentation_image_style_catalog.dart';

import 'ask_user_checkbox.dart';
import 'ask_user_image_style.dart';
import 'ask_user_radio.dart';
import 'ask_user_slider.dart';
import 'ask_user_style.dart';

export 'ask_user_checkbox.dart';
export 'ask_user_image_style.dart';
export 'ask_user_radio.dart';
export 'ask_user_slider.dart';
export 'ask_user_style.dart';

/// SuperDeck AI chat catalog with GenUI components.
///
/// Components:
/// - [askUserRadio] - Radio button single selection
/// - [askUserCheckbox] - Checkbox multiple selection
/// - [askUserSlider] - Slider numeric input
/// - [askUserStyleFor] - Catalog-backed presentation theme selection
/// - [askUserImageStyleFor] - Application-owned generated artwork directions
Catalog chatCatalogFor(
  PresentationThemeCatalog themeCatalog, {
  required PresentationImageStyleCatalog imageStyleCatalog,
}) {
  return Catalog([
    askUserRadio,
    askUserCheckbox,
    askUserSlider,
    askUserStyleFor(themeCatalog),
    askUserImageStyleFor(imageStyleCatalog),
  ], catalogId: 'com.superdeck.ai.chat');
}
