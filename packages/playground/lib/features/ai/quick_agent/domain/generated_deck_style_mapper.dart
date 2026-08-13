import 'package:flutter/widgets.dart';

import '../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../core/domain/stores/deck_customization_store.dart';

extension GeneratedDeckStyleMapping on ResolvedPresentationTheme {
  GeneratedDeckStyle toGeneratedDeckStyle() => .new(
    background: _colorFromHex(palette.background),
    surface: _colorFromHex(palette.surface),
    surfaceAlt: _colorFromHex(palette.surfaceAlt),
    heading: _colorFromHex(palette.heading),
    body: _colorFromHex(palette.body),
    accent: _colorFromHex(palette.accent),
    accentContrast: _colorFromHex(palette.accentContrast),
    headlineFamily: headlineFamily,
    bodyFamily: bodyFamily,
    direction: direction,
    density: density,
    typeScale: typeScale,
    runtime: descriptor.recipe.runtime,
  );
}

Color _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '');

  return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
}
