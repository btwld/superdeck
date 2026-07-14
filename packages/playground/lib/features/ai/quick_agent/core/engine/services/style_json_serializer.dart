import '../schemas/deck_schemas.dart';

/// Serializes a parsed deck style to a JSON-encodable map.
///
Map<String, Object?> serializeDeckStyleForJson(DeckStyleType style) {
  final colors = style.colors;
  final fonts = style.fonts;

  return {
    'name': style.name,
    'direction': style.direction,
    'density': style.density,
    'typeScale': style.typeScale,
    'colors': {
      'background': colors.background,
      'surface': colors.surface,
      'surfaceAlt': colors.surfaceAlt,
      'heading': colors.heading,
      'body': colors.body,
      'accent': colors.accent,
      'accentContrast': colors.accentContrast,
    },
    'fonts': {'headline': fonts.headline, 'body': fonts.body},
  };
}
