import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/ai/services/slide_key_utils.dart';
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/deck_tools_schemas.dart';
import 'package:playground/features/ai/core/tools/deck_tools_service.dart';
import 'package:playground/features/ai/core/tools/errors.dart';
import 'package:playground/features/ai/core/tools/in_memory_deck_store.dart';
import 'package:playground/features/ai/core/utils/deck_style_service.dart';
import 'package:playground/utils/memory_deck_loader.dart';

void main() {
  setUp(() {
    DeckStyleService.clearCache();
  });

  tearDown(() {
    DeckStyleService.clearCache();
  });

  /// Builds an [InMemoryDeckStore] pre-seeded with [slides] and [style].
  (InMemoryDeckStore, MemoryDeckLoader) makeStore({
    required List<Map<String, dynamic>> slides,
    Map<String, Object?>? style,
  }) {
    final loader = MemoryDeckLoader();
    final parsedSlides = slides.map((s) => Slide.parse(Map<String, Object?>.from(s))).toList();
    final parsedStyle = style != null ? DeckStyleType.parse(style) : null;
    final store = InMemoryDeckStore(
      slidesProvider: () => parsedSlides,
      deckLoader: loader,
      initialStyle: parsedStyle,
    );
    return (store, loader);
  }

  group('DeckToolsService', () {
    test('getDeck returns deck snapshot', () async {
      final (store, _) = makeStore(
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
      final slides = [_slideSchema(key: 'slide-1', title: 'Intro')];
      final loader = MemoryDeckLoader();
      // Use a mutable list so writeCanonical updates are visible in readRequired.
      final mutableSlides = slides
          .map((s) => Slide.parse(Map<String, Object?>.from(s)))
          .toList();
      final store = _MutableInMemoryStore(
        mutableSlides: mutableSlides,
        deckLoader: loader,
        style: DeckStyleType.parse(_styleMap()),
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
        final mutableSlides = [
          Slide.parse(Map<String, Object?>.from(_slideSchema(key: collidingKey, title: 'Existing'))),
        ];
        final loader = MemoryDeckLoader();
        final store = _MutableInMemoryStore(
          mutableSlides: mutableSlides,
          deckLoader: loader,
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
      final (store, _) = makeStore(
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

    test('createSlide rejects unsafe explicit key', () async {
      final (store, _) = makeStore(
        slides: [_slideSchema(key: 'slide-1', title: 'Intro')],
      );

      final service = DeckToolsService(documentStore: store);

      await expectLater(
        service.createSlide(
          CreateSlideRequestType.parse({
            'schema': _slideSchema(key: '../unsafe', title: 'Unsafe'),
          }),
        ),
        throwsA(
          isA<DeckToolException>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.slideKeyInvalid,
          ),
        ),
      );
    });

    test('updateSlide preserves existing key', () async {
      final mutableSlides = [
        Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-1', title: 'Original'))),
      ];
      final loader = MemoryDeckLoader();
      final store = _MutableInMemoryStore(
        mutableSlides: mutableSlides,
        deckLoader: loader,
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
        final mutableSlides = [
          Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-1', title: 'Original'))),
        ];
        final loader = MemoryDeckLoader();
        final store = _MutableInMemoryStore(
          mutableSlides: mutableSlides,
          deckLoader: loader,
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
      final mutableSlides = [
        Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-1', title: 'One'))),
        Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-2', title: 'Two'))),
      ];
      final loader = MemoryDeckLoader();
      final store = _MutableInMemoryStore(
        mutableSlides: mutableSlides,
        deckLoader: loader,
      );

      final service = DeckToolsService(documentStore: store);
      final snapshot = await service.deleteSlide(
        DeleteSlideRequestType.parse({'index': 0}),
      );

      expect(snapshot.totalSlides, 1);
      expect(snapshot.slides.single.key, 'slide-2');
    });

    test('moveSlide reorders slides', () async {
      final mutableSlides = [
        Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-1', title: 'One'))),
        Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-2', title: 'Two'))),
        Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-3', title: 'Three'))),
      ];
      final loader = MemoryDeckLoader();
      final store = _MutableInMemoryStore(
        mutableSlides: mutableSlides,
        deckLoader: loader,
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
      final mutableSlides = [
        Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-1', title: 'One'))),
      ];
      final loader = MemoryDeckLoader();
      final store = _MutableInMemoryStore(
        mutableSlides: mutableSlides,
        deckLoader: loader,
      );

      final service = DeckToolsService(documentStore: store);
      final style = _styleMap(name: 'Updated Style', heading: '#123456');

      final result = await service.updateStyle(
        UpdateStyleRequestType.parse({
          'style': Map<String, Object?>.from(style),
        }),
      );

      expect(result.style['name'], 'Updated Style');
      expect(DeckStyleService.style.value?.name, 'Updated Style');

      final persisted = await store.readRequired();
      expect(persisted.style?.name, 'Updated Style');
    });

    test(
      'updateStyle rejects invalid payload and preserves existing style',
      () async {
        final (store, _) = makeStore(
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

        expect(DeckStyleService.style.value?.name, 'Existing Style');
      },
    );

    test('getDeck fails fast when no store is provided', () async {
      final service = DeckToolsService();

      await expectLater(
        service.getDeck(),
        throwsA(isA<StateError>()),
      );
    });

    test('readSlide returns schema and base64 thumbnail', () async {
      final (store, _) = makeStore(
        slides: [_slideSchema(key: 'slide-1', title: 'Intro')],
        style: _styleMap(),
      );

      final context = _StubBuildContext();

      final service = DeckToolsService(
        documentStore: store,
        contextProvider: () => context,
        buildReadSlideConfiguration: _fakeReadSlideConfigurationBuilder,
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
      final (store, _) = makeStore(
        slides: [
          _slideSchema(key: 'slide-1', title: 'Intro'),
          _slideSchema(key: 'slide-2', title: 'Agenda'),
        ],
        style: _styleMap(),
      );

      final context = _StubBuildContext();
      SlideConfiguration? capturedConfiguration;

      final service = DeckToolsService(
        documentStore: store,
        contextProvider: () => context,
        buildReadSlideConfiguration:
            ({required slide, required style, required index}) {
              return SlideConfiguration(
                slideIndex: 0,
                style: SlideStyle(),
                slide: slide,
                thumbnailKey: 'slide-$index.png',
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
      'readSlide stops before capture if context unmounts while configuring',
      () async {
        final (store, _) = makeStore(
          slides: [_slideSchema(key: 'slide-1', title: 'Intro')],
          style: _styleMap(),
        );

        final context = _MutableBuildContext();
        var captureCalled = false;

        final service = DeckToolsService(
          documentStore: store,
          contextProvider: () => context,
          buildReadSlideConfiguration:
              ({required slide, required style, required index}) async {
                await Future<void>.delayed(Duration.zero);
                context.mounted = false;
                return SlideConfiguration(
                  slideIndex: index,
                  style: SlideStyle(),
                  slide: slide,
                  thumbnailKey: 'slide-$index.png',
                );
              },
          captureSlide: (slide, context) async {
            captureCalled = true;
            return Uint8List.fromList([1]);
          },
        );

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
        expect(captureCalled, isFalse);
      },
    );

    test(
      'readSlide throws context_unavailable when no context exists',
      () async {
        final (store, _) = makeStore(
          slides: [_slideSchema(key: 'slide-1')],
        );

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
      final mutableSlides = [
        Slide.parse(Map<String, Object?>.from(_slideSchema(key: 'slide-1', title: 'Seed'))),
      ];
      final loader = MemoryDeckLoader();
      final gate = Completer<void>();
      final gatedStore = _GatedMutableStore(
        mutableSlides: mutableSlides,
        deckLoader: loader,
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

      final persisted = await gatedStore.readRequired();
      expect(persisted.slides, hasLength(3));
      expect(
        persisted.slides.map((slide) => slide.options?.title),
        containsAll(['Seed', 'First concurrent', 'Second concurrent']),
      );
    });
  });
}

SlideConfiguration _fakeReadSlideConfigurationBuilder({
  required Slide slide,
  required DeckStyleType? style,
  required int index,
}) {
  final thumbnailNameSuffix = style?.name ?? 'no-style';
  return SlideConfiguration(
    slideIndex: index,
    style: SlideStyle(),
    slide: slide,
    thumbnailKey: 'slide-$index-$thumbnailNameSuffix.png',
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

class _MutableBuildContext implements BuildContext {
  @override
  bool mounted = true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

/// A [DeckStore] backed by a mutable list, allowing [writeCanonical] to
/// update the visible state returned by [readRequired].
class _MutableInMemoryStore implements DeckStore {
  _MutableInMemoryStore({
    required List<Slide> mutableSlides,
    required MemoryDeckLoader deckLoader,
    DeckStyleType? style,
  }) : _slides = mutableSlides,
       _deckLoader = deckLoader,
       _style = style;

  final List<Slide> _slides;
  final MemoryDeckLoader _deckLoader;
  DeckStyleType? _style;

  @override
  Future<DeckDocument> readRequired() async =>
      DeckDocument(slides: List.unmodifiable(_slides), style: _style);

  @override
  Future<void> writeCanonical({
    required List<Slide> slides,
    DeckStyleType? style,
  }) async {
    _slides
      ..clear()
      ..addAll(slides);
    _style = style;
    // Update the loader (required by InMemoryDeckStore contract, used here
    // for fidelity but not observed by test assertions).
    final markdown = const SlideSerializer().serialize(slides);
    _deckLoader.updateMarkdown(markdown);
  }
}

class _GatedMutableStore extends _MutableInMemoryStore {
  _GatedMutableStore({
    required super.mutableSlides,
    required super.deckLoader,
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
