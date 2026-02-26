import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_ai/core/tools/deck_tools_schemas.dart';

void main() {
  group('Deck tool request schemas', () {
    test('parse valid request payloads', () {
      final readRequest = ReadSlideRequestType.parse({'index': 0});
      final createRequest = CreateSlideRequestType.parse({
        'schema': _slideSchema(),
      });
      final createWithoutKey = CreateSlideRequestType.parse({
        'schema': _slideSchema(includeKey: false),
      });
      final updateWithoutKey = UpdateSlideRequestType.parse({
        'index': 0,
        'schema': _slideSchema(includeKey: false),
      });
      final moveRequest = MoveSlideRequestType.parse({
        'fromIndex': 0,
        'toIndex': 1,
      });

      expect(readRequest.index, 0);
      expect(createRequest.schema['key'], 'slide-1');
      expect(createWithoutKey.schema['key'], isNull);
      expect(updateWithoutKey.schema['key'], isNull);
      expect(moveRequest.toIndex, 1);
    });

    test('reject invalid request payloads', () {
      expect(ReadSlideRequestType.safeParse({'index': -1}).getOrNull(), isNull);
      expect(
        MoveSlideRequestType.safeParse({'fromIndex': 0}).getOrNull(),
        isNull,
      );
      expect(
        CreateSlideRequestType.safeParse({
          'schema': 'not-an-object',
        }).getOrNull(),
        isNull,
      );
      expect(
        UpdateStyleRequestType.safeParse({'style': 'invalid'}).getOrNull(),
        isNull,
      );
    });
  });

  group('Deck tool response schemas', () {
    test('parse response payloads with typed getters', () {
      final snapshot = DeckSnapshotType.parse({
        'totalSlides': 1,
        'slides': [
          {'index': 0, 'key': 'slide-1', 'title': 'Intro'},
        ],
        'style': _styleMap(),
      });

      final readResult = ReadSlideResultType.parse({
        'slide': {
          'index': 0,
          'key': 'slide-1',
          'schema': _slideSchema(),
          'thumbnail': 'AAECAw==',
        },
        'deck': snapshot.toJson(),
      });

      final styleResult = StyleUpdateResultType.parse({
        'style': _styleMap(),
        'deck': snapshot.toJson(),
      });

      expect(snapshot.totalSlides, 1);
      expect(snapshot.slides.single.title, 'Intro');
      expect(snapshot.style?['name'], 'Default');
      expect(readResult.slide['key'], 'slide-1');
      expect((readResult.slide['schema'] as Map)['key'], 'slide-1');
      expect(styleResult.style['name'], 'Default');
    });
  });
}

Map<String, Object?> _slideSchema({bool includeKey = true}) {
  return {
    if (includeKey) 'key': 'slide-1',
    'options': {'title': 'Intro'},
    'sections': [
      {
        'type': 'section',
        'blocks': [
          {'type': 'block', 'content': 'Body'},
        ],
      },
    ],
  };
}

Map<String, Object?> _styleMap() {
  return {
    'name': 'Default',
    'colors': {
      'background': '#FFFFFF',
      'heading': '#112233',
      'body': '#445566',
    },
    'fonts': {'headline': 'montserrat', 'body': 'openSans'},
  };
}
