import 'package:genui/genui.dart';

import 'ask_user_checkbox.dart';
import 'ask_user_image_style.dart';
import 'ask_user_radio.dart';
import 'ask_user_slider.dart';
import 'ask_user_style.dart';
import 'ask_user_text.dart';
import 'summary_card.dart';

export 'ask_user_checkbox.dart';
export 'ask_user_image_style.dart';
export 'ask_user_radio.dart';
export 'ask_user_slider.dart';
export 'ask_user_style.dart';
export 'ask_user_text.dart';
export 'summary_card.dart';

/// SuperDeck AI chat catalog with GenUI components.
///
/// Components:
/// - [askUserRadio] - Radio button single selection
/// - [askUserCheckbox] - Checkbox multiple selection
/// - [askUserSlider] - Slider numeric input
/// - [askUserText] - Free-form text input
/// - [askUserStyle] - Visual style selection with colors and fonts
/// - [askUserImageStyle] - Curated artwork selection with generated previews
/// - [summaryCard] - Wizard summary with aggregated selections
final chatCatalog = Catalog([
  askUserRadio,
  askUserCheckbox,
  askUserSlider,
  askUserText,
  askUserStyle,
  askUserImageStyle,
  summaryCard,
], catalogId: 'com.superdeck.ai.chat');
