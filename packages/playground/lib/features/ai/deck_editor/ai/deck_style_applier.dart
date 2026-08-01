import 'package:ack/ack.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../../core/utils/color_utils.dart';
import '../../quick_agent/core/engine/schemas/deck_schemas.dart';
import '../../quick_agent/core/engine/services/style_json_serializer.dart';
import '../domain/deck_store.dart';
import '../domain/deck_tool_error.dart';
import 'deck_tool_schemas.dart';

/// Applies the existing AI style contract to live customization state.
final class DeckStyleApplier {
  const DeckStyleApplier({
    required DeckCustomizationStore customizationStore,
    required DeckStore deckStore,
  }) : _customizationStore = customizationStore,
       _deckStore = deckStore;

  final DeckCustomizationStore _customizationStore;
  final DeckStore _deckStore;

  Map<String, Object?> update(Object? value) {
    final DeckStyleType style;
    try {
      style = DeckStyleType.parse(value);
    } on AckException catch (error) {
      throw DeckToolError(
        DeckToolErrorCode.validationFailed,
        'The deck style is invalid.',
        cause: error,
      );
    }

    final background = _validColor(style.colors.background, 'background');
    final heading = _validColor(style.colors.heading, 'heading');
    final body = _validColor(style.colors.body, 'body');
    final before = _customizationStore.captureSnapshot();
    final levels = {
      for (final level in TextLevel.values)
        level: before
            .level(level)
            .copyWith(
              color: level == TextLevel.p ? body : heading,
              family: level == TextLevel.p
                  ? style.fonts.body.fontFamily
                  : style.fonts.headline.fontFamily,
            ),
    };

    _customizationStore.restoreSnapshot(
      before.copyWith(background: background, levels: levels),
    );

    return {
      'style': serializeDeckStyleForJson(style),
      'deck': deckSnapshot(_deckStore.read()),
    };
  }

  Color _validColor(String value, String field) {
    final parsed = parseHexColor(value);
    if (!parsed.isValid) {
      throw DeckToolError(
        DeckToolErrorCode.validationFailed,
        'The $field color must be a valid RGB or ARGB hex color.',
      );
    }
    return parsed.color;
  }
}
