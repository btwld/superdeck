import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_genui/src/ai/schemas/deck_schemas.dart';
import 'package:superdeck_genui/src/ai/services/slide_key_utils.dart';
import 'package:superdeck_genui/src/tools/deck_document_store.dart';
import 'package:superdeck_genui/src/tools/deck_tools_schemas.dart';
import 'package:superdeck_genui/src/tools/deck_tools_service.dart';
import 'package:superdeck_genui/src/tools/errors.dart';
import 'package:superdeck_genui/src/utils/deck_style_service.dart';

void main() {
  late Directory tempDir;
  late DeckWorkspace configuration;
  late DeckDocumentStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('deck_tools_service_test_');
    configuration = DeckWorkspace(projectDir: tempDir.path);
    store = DeckDocumentStore(configuration: configuration);
    DeckStyleService.clearCache();
  });

  tearDown(() async {
    DeckStyleService.clearCache();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DeckToolsService', () {
    test('getDeck returns deck snapshot', () async {
      await _writeDeck(
        configuration,
        slides: [
          _slideSchema(key: 'slide-1', title: 'Intro'),
          _slideSchema(key: 'slide-2', title: 'Agenda'),
        ],
        style: _styleMap(),
      );

      final service = DeckToolsService(documentStore: store);
      final result = await service.getDeck();

      expect(result.totalSlides, 2);
      expect(result.slides[0].key, 'slide-1');
      expect(result.style, isNotNull);
    });

    test('createSlide generates key when key is missing', () async {
      await _writeDeck(
        configuration,
        slides: [_slideSchema(key: 'slide-1', title: 'Intro')],
        style: _styleMap(),
      );

      final service = DeckToolsService(documentStore: store);
      final result = await service.createSlide(
        CreateSlideRequestType.parse({
          'schema': _slideSchema(title: 'Generated Key Slide'),
        }),
      );

      expect(result.deck.totalSlides, 2);
      expect(result.slide.key, isNotEmpty);

      final persisted = await store.readRequired();
      expect(persisted.slides, hasLength(2));
      expect(persisted.slides.last.key, result.slide.key);
    });

    test(
      'createSlide retries generated key when first candidate collides',
      () async {
        final incomingSchema = _slideSchema(title: 'Collision Candidate');
        final collidingKey = generateSlideKey(
          Map<String, dynamic>.from(incomingSchema),
          1,
        );
        await _writeDeck(
          configuration,
          slides: [_slideSchema(key: collidingKey, title: 'Existing')],
          style: _styleMap(),
        );

        final service = DeckToolsService(documentStore: store);
        final result = await service.createSlide(
          CreateSlideRequestType.parse({
            'schema': incomingSchema,
            'atIndex': 1,
          }),
        );

        expect(result.slide.key, isNot(collidingKey));

        final persisted = await store.readRequired();
        expect(
          persisted.slides.map((slide) => slide.key).toSet(),
          hasLength(2),
        );
      },
    );

    test('createSlide throws slide_key_conflict for duplicate key', () async {
      await _writeDeck(
        configuration,
        slides: [_slideSchema(key: 'slide-1', title: 'Intro')],
      );

      final service = DeckToolsService(documentStore: store);

      await expectLater(
        service.createSlide(
          CreateSlideRequestType.parse({
            'schema': _slideSchema(key: 'slide-1', title: 'Dupe'),
          }),
        ),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.slideKeyConflict,
          ),
        ),
      );
    });

    test('updateSlide preserves existing key', () async {
      await _writeDeck(
        configuration,
        slides: [_slideSchema(key: 'slide-1', title: 'Original')],
      );

      final service = DeckToolsService(documentStore: store);
      final result = await service.updateSlide(
        UpdateSlideRequestType.parse({
          'index': 0,
          'schema': _slideSchema(key: 'new-key', title: 'Updated'),
        }),
      );

      expect(result.slide.key, 'slide-1');

      final persisted = await store.readRequired();
      expect(persisted.slides.single.key, 'slide-1');
      expect(persisted.slides.single.options?.title, 'Updated');
    });

    test(
      'updateSlide accepts schema without key and preserves existing key',
      () async {
        await _writeDeck(
          configuration,
          slides: [_slideSchema(key: 'slide-1', title: 'Original')],
        );

        final service = DeckToolsService(documentStore: store);
        final result = await service.updateSlide(
          UpdateSlideRequestType.parse({
            'index': 0,
            'schema': _slideSchema(title: 'Updated without key'),
          }),
        );

        expect(result.slide.key, 'slide-1');

        final persisted = await store.readRequired();
        expect(persisted.slides.single.key, 'slide-1');
        expect(persisted.slides.single.options?.title, 'Updated without key');
      },
    );

    test('deleteSlide removes a slide by index', () async {
      await _writeDeck(
        configuration,
        slides: [
          _slideSchema(key: 'slide-1', title: 'One'),
          _slideSchema(key: 'slide-2', title: 'Two'),
        ],
      );

      final service = DeckToolsService(documentStore: store);
      final snapshot = await service.deleteSlide(
        DeleteSlideRequestType.parse({'index': 0}),
      );

      expect(snapshot.totalSlides, 1);
      expect(snapshot.slides.single.key, 'slide-2');
    });

    test('moveSlide reorders slides', () async {
      await _writeDeck(
        configuration,
        slides: [
          _slideSchema(key: 'slide-1', title: 'One'),
          _slideSchema(key: 'slide-2', title: 'Two'),
          _slideSchema(key: 'slide-3', title: 'Three'),
        ],
      );

      final service = DeckToolsService(documentStore: store);
      final result = await service.moveSlide(
        MoveSlideRequestType.parse({'fromIndex': 0, 'toIndex': 2}),
      );

      expect(result.slide.key, 'slide-1');
      expect(result.deck.slides.map((slide) => slide.key), [
        'slide-2',
        'slide-3',
        'slide-1',
      ]);
    });

    test('updateStyle validates payload and updates cache', () async {
      await _writeDeck(
        configuration,
        slides: [_slideSchema(key: 'slide-1', title: 'One')],
      );

      final service = DeckToolsService(documentStore: store);
      final style = _styleMap(name: 'Updated Style', heading: '#123456');

      final result = await service.updateStyle(
        UpdateStyleRequestType.parse({
          'style': Map<String, Object?>.from(style),
        }),
      );

      expect(result.style['name'], 'Updated Style');
      expect(DeckStyleService.readStyleFromCache()?.name, 'Updated Style');

      final persisted = await store.readRequired();
      expect(persisted.style?.name, 'Updated Style');
    });

    test(
      'updateStyle rejects invalid payload and preserves existing style',
      () async {
        await _writeDeck(
          configuration,
          slides: [_slideSchema(key: 'slide-1')],
          style: _styleMap(name: 'Existing Style'),
        );
        DeckStyleService.setStyle(
          DeckStyleType.parse(_styleMap(name: 'Existing Style')),
        );

        final service = DeckToolsService(documentStore: store);

        await expectLater(
          service.updateStyle(
            UpdateStyleRequestType({
              'style': {'name': 'Invalid only'},
            }),
          ),
          throwsA(
            isA<DeckToolException>().having(
              (error) => error.code,
              'code',
              DeckToolErrorCode.styleInvalid,
            ),
          ),
        );

        expect(DeckStyleService.readStyleFromCache()?.name, 'Existing Style');
      },
    );

    test('getDeck fails fast when deck file is missing', () async {
      final service = DeckToolsService(documentStore: store);

      await expectLater(
        service.getDeck(),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.deckFileNotFound,
          ),
        ),
      );
    });

    test('readSlide returns schema and base64 thumbnail', () async {
      await _writeDeck(
        configuration,
        slides: [_slideSchema(key: 'slide-1', title: 'Intro')],
        style: _styleMap(),
      );

      final context = _StubBuildContext();

      final service = DeckToolsService(
        documentStore: store,
        contextProvider: () => context,
        buildReadSlideData: _fakeReadSlideDataBuilder,
        captureSlide: (slide, context) async => Uint8List.fromList([1, 2, 3]),
      );

      final result = await service.readSlide(
        ReadSlideRequestType.parse({'index': 0}),
      );

      expect(result.slide['key'], 'slide-1');
      expect((result.slide['schema'] as Map)['key'], 'slide-1');
      expect(result.slide['thumbnail'], base64Encode([1, 2, 3]));
      expect(result.deck.totalSlides, 1);
    });

    test('readSlide captures using the requested slide index', () async {
      await _writeDeck(
        configuration,
        slides: [
          _slideSchema(key: 'slide-1', title: 'Intro'),
          _slideSchema(key: 'slide-2', title: 'Agenda'),
        ],
        style: _styleMap(),
      );

      final context = _StubBuildContext();
      SlideData? capturedConfiguration;

      final service = DeckToolsService(
        documentStore: store,
        contextProvider: () => context,
        buildReadSlideData:
            ({
              required slide,
              required configuration,
              required style,
              required index,
            }) {
              // Simulate a misbehaving builder that always returns index 0.
              return SlideData(
                slideIndex: 0,
                style: SlideStyle(),
                slide: slide,
                thumbnailFile: 'slide-$index.png',
              );
            },
        captureSlide: (slide, context) async {
          capturedConfiguration = slide;
          return Uint8List.fromList([1]);
        },
      );

      final result = await service.readSlide(
        ReadSlideRequestType.parse({'index': 1}),
      );

      expect(result.slide['index'], 1);
      expect(capturedConfiguration, isNotNull);
      expect(capturedConfiguration!.slideIndex, 1);
    });

    test(
      'readSlide throws context_unavailable when no context exists',
      () async {
        await _writeDeck(configuration, slides: [_slideSchema(key: 'slide-1')]);

        final service = DeckToolsService(documentStore: store);

        await expectLater(
          service.readSlide(ReadSlideRequestType.parse({'index': 0})),
          throwsA(
            isA<DeckToolException>().having(
              (error) => error.code,
              'code',
              DeckToolErrorCode.contextUnavailable,
            ),
          ),
        );
      },
    );

    test('serializes concurrent mutations', () async {
      await _writeDeck(
        configuration,
        slides: [_slideSchema(key: 'slide-1', title: 'Seed')],
      );

      final gate = Completer<void>();
      final gatedStore = _GatedDeckDocumentStore(
        configuration: configuration,
        firstReadGate: gate,
      );
      final service = DeckToolsService(documentStore: gatedStore);

      final firstMutation = service.createSlide(
        CreateSlideRequestType.parse({
          'schema': _slideSchema(title: 'First concurrent'),
        }),
      );
      await Future<void>.delayed(Duration.zero);

      final secondMutation = service.createSlide(
        CreateSlideRequestType.parse({
          'schema': _slideSchema(title: 'Second concurrent'),
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      try {
        expect(
          gatedStore.readCalls,
          1,
          reason: 'Second mutation should not start before the first finishes',
        );
      } finally {
        if (!gate.isCompleted) {
          gate.complete();
        }
      }

      await Future.wait([firstMutation, secondMutation]);

      final persisted = await store.readRequired();
      expect(persisted.slides, hasLength(3));
      expect(
        persisted.slides.map((slide) => slide.options?.title),
        containsAll(['Seed', 'First concurrent', 'Second concurrent']),
      );
    });
  });
}

SlideData _fakeReadSlideDataBuilder({
  required Slide slide,
  required DeckWorkspace configuration,
  required DeckStyleType? style,
  required int index,
}) {
  final thumbnailNameSuffix = style?.name ?? configuration.projectDir;
  return SlideData(
    slideIndex: index,
    style: SlideStyle(),
    slide: slide,
    thumbnailFile: 'slide-$index-$thumbnailNameSuffix.png',
  );
}

class _StubBuildContext implements BuildContext {
  @override
  bool get mounted => true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _GatedDeckDocumentStore extends DeckDocumentStore {
  _GatedDeckDocumentStore({
    required super.configuration,
    required this.firstReadGate,
  });

  final Completer<void> firstReadGate;
  int readCalls = 0;

  @override
  Future<DeckDocument> readRequired() async {
    readCalls++;
    if (readCalls == 1) {
      await firstReadGate.future;
    }
    return super.readRequired();
  }
}

Future<void> _writeDeck(
  DeckWorkspace configuration, {
  required List<Map<String, dynamic>> slides,
  Map<String, Object?>? style,
}) async {
  final payload = <String, Object?>{'slides': slides};
  if (style != null) {
    payload['style'] = style;
  }

  await configuration.deckJson.parent.create(recursive: true);
  await configuration.deckJson.writeAsString(jsonEncode(payload));
}

Map<String, dynamic> _slideSchema({
  String? key,
  String title = 'Slide',
  String content = 'Body',
}) {
  return {
    if (key != null) 'key': key,
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

Map<String, Object?> _styleMap({
  String name = 'Default',
  String heading = '#112233',
}) {
  return {
    'name': name,
    'colors': {'background': '#FFFFFF', 'heading': heading, 'body': '#445566'},
    'fonts': {'headline': 'montserrat', 'body': 'openSans'},
  };
}
