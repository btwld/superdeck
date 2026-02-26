import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_ai/core/ai/schemas/deck_schemas.dart';
import 'package:superdeck_ai/core/tools/deck_document_store.dart';
import 'package:superdeck_ai/core/tools/errors.dart';

void main() {
  late Directory tempDir;
  late DeckConfiguration configuration;
  late DeckDocumentStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'deck_document_store_test_',
    );
    configuration = DeckConfiguration(projectDir: tempDir.path);
    store = DeckDocumentStore(configuration: configuration);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('readRequired', () {
    test('throws deck_file_not_found when file does not exist', () async {
      await expectLater(
        store.readRequired(),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.deckFileNotFound,
          ),
        ),
      );
    });

    test('throws deck_json_invalid when JSON is malformed', () async {
      final file = configuration.deckJson;
      await file.parent.create(recursive: true);
      await file.writeAsString('{ not valid json');

      await expectLater(
        store.readRequired(),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.deckJsonInvalid,
          ),
        ),
      );
    });

    test('throws deck_schema_invalid when root shape is invalid', () async {
      final file = configuration.deckJson;
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'style': _styleMap()}));

      await expectLater(
        store.readRequired(),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.deckSchemaInvalid,
          ),
        ),
      );
    });

    test('throws deck_schema_invalid when style payload is invalid', () async {
      final file = configuration.deckJson;
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'slides': [_slideMap()],
          'style': {'name': 'Missing fields'},
        }),
      );

      await expectLater(
        store.readRequired(),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.deckSchemaInvalid,
          ),
        ),
      );
    });

    test('reads parsed slides and style when document is valid', () async {
      final file = configuration.deckJson;
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'slides': [_slideMap(key: 'slide-1')],
          'style': _styleMap(),
        }),
      );

      final document = await store.readRequired();

      expect(document.slides, hasLength(1));
      expect(document.slides.single.key, 'slide-1');
      expect(document.style, isNotNull);
      expect(document.style!.colors.heading, '#112233');
    });
  });

  group('writeCanonical', () {
    test('writes only canonical root keys slides + style', () async {
      final slide = Slide.parse(_slideMap(key: 'slide-1', title: 'Intro'));
      final style = DeckStyleType.parse(_styleMap());

      await store.writeCanonical(slides: [slide], style: style);

      final file = configuration.deckJson;
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      expect(map.keys.toSet(), {'slides', 'style'});
      expect((map['slides'] as List).length, 1);
      expect((map['slides'] as List).first['key'], 'slide-1');
      expect((map['style'] as Map)['name'], 'Default');
    });

    test('omits style key when style is null', () async {
      final slide = Slide.parse(_slideMap(key: 'slide-1'));

      await store.writeCanonical(slides: [slide], style: null);

      final map =
          jsonDecode(await configuration.deckJson.readAsString())
              as Map<String, dynamic>;

      expect(map.keys.toSet(), {'slides'});
    });

    test('writes to project-relative superdeck.json', () async {
      final slide = Slide.parse(_slideMap(key: 'slide-1'));
      await store.writeCanonical(slides: [slide], style: null);

      final expectedPath = p.join(tempDir.path, '.superdeck', 'superdeck.json');
      expect(configuration.deckJson.path, expectedPath);
      expect(await File(expectedPath).exists(), isTrue);
    });

    test('throws deck_write_failed when filesystem write fails', () async {
      final superdeckPath = p.join(tempDir.path, '.superdeck');
      await File(superdeckPath).writeAsString('block directory creation');

      final slide = Slide.parse(_slideMap(key: 'slide-1'));

      await expectLater(
        store.writeCanonical(slides: [slide], style: null),
        throwsA(
          isA<DeckToolException>()
              .having(
                (error) => error.code,
                'code',
                DeckToolErrorCode.deckWriteFailed,
              )
              .having(
                (error) => error.message,
                'message',
                contains('Failed to write deck file'),
              ),
        ),
      );
    });
  });
}

Map<String, dynamic> _slideMap({
  String key = 'slide-1',
  String title = 'Slide Title',
  String content = 'Hello world',
}) {
  return {
    'key': key,
    'options': {'title': title},
    'sections': [
      {
        'type': 'section',
        'blocks': [
          {'type': 'block', 'content': content},
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
