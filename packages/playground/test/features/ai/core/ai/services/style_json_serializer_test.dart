import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/services/style_json_serializer.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';

void main() {
  group('serializeDeckStyleForJson', () {
    test('converts enum fields to string IDs', () {
      final style = DeckStyleType.parse({
        'name': 'Test Style',
        'colors': {
          'background': '#FFFFFF',
          'heading': '#112233',
          'body': '#445566',
        },
        'fonts': {'headline': 'montserrat', 'body': 'openSans'},
      });

      final jsonStyle = serializeDeckStyleForJson(style);

      expect((jsonStyle['fonts'] as Map)['headline'], 'montserrat');
      expect((jsonStyle['fonts'] as Map)['body'], 'openSans');
    });

    test('produces JSON-encodable output', () {
      final style = DeckStyleType.parse({
        'name': 'Test Style',
        'colors': {
          'background': '#FFFFFF',
          'heading': '#112233',
          'body': '#445566',
        },
        'fonts': {'headline': 'montserrat', 'body': 'openSans'},
      });

      final jsonStyle = serializeDeckStyleForJson(style);
      final encoded = jsonEncode({'style': jsonStyle});
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['style'], isA<Map<String, dynamic>>());
      expect((decoded['style'] as Map<String, dynamic>)['fonts'], {
        'headline': 'montserrat',
        'body': 'openSans',
      });
    });
  });
}
