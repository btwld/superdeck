import 'package:superdeck_ai/core/ai/schemas/deck_schemas.dart';

/// Serializes a parsed deck style to a JSON-encodable map.
///
/// ACK enum fields are converted to their wire-format string IDs.
Map<String, Object?> serializeDeckStyleForJson(DeckStyleType style) {
  final colors = style.colors;
  final fonts = style.fonts;

  return {
    'name': style.name,
    'colors': {
      'background': colors.background,
      'heading': colors.heading,
      'body': colors.body,
    },
    'fonts': {'headline': fonts.headline.name, 'body': fonts.body.name},
  };
}
