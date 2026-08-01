import 'package:genui/genui.dart';

import '../../wizard/core/ai/catalog/ask_user_checkbox.dart';
import '../../wizard/core/ai/catalog/ask_user_radio.dart';
import '../../wizard/core/ai/catalog/ask_user_slider.dart';
import '../../wizard/core/ai/catalog/ask_user_style.dart';
import '../../wizard/core/ai/catalog/ask_user_text.dart';

/// Input-only GenUI catalog for an active deck-editing session.
final deckEditCatalog = Catalog([
  askUserRadio,
  askUserCheckbox,
  askUserSlider,
  askUserText,
  askUserStyle,
], catalogId: 'com.superdeck.ai.deck_edit');
