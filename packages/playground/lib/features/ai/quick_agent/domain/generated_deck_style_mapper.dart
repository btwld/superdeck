import 'package:flutter/widgets.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../core/engine/schemas/deck_schemas.dart';

extension GeneratedDeckStyleMapping on DeckStyleType {
  GeneratedDeckStyle toGeneratedDeckStyle() => .new(
    background: _colorFromHex(colors.background),
    surface: _colorFromHex(colors.surface),
    surfaceAlt: _colorFromHex(colors.surfaceAlt),
    heading: _colorFromHex(colors.heading),
    body: _colorFromHex(colors.body),
    accent: _colorFromHex(colors.accent),
    accentContrast: _colorFromHex(colors.accentContrast),
    headlineFamily: fonts.headline,
    bodyFamily: fonts.body,
    direction: direction,
    density: density,
    typeScale: typeScale,
  );
}

Color _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '');

  return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
}
