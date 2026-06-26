import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/deck_tools_adapter.dart';
import 'package:playground/features/ai/core/tools/deck_tools_runtime.dart';
import 'package:playground/features/ai/core/tools/deck_tools_schemas.dart';
import 'package:playground/features/ai/core/tools/deck_tools_service.dart';
import 'package:playground/features/ai/core/tools/errors.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('DeckToolsService', () {
    test(
      'createSlide appends by default and returns keyless post-write slide',
      () async {
        final store = _MutableDeckStore([_slide('seed', title: 'Seed')]);
        final service = _service(store);

        final result = await service.createSlide(
          CreateSlideRequestType.parse({'slide': _deckToolSlide(title: 'New')}),
        );

        expect(result.index, 1);
        expect(result.deck.totalSlides, 2);
        expect(result.slide.options?.title, 'New');
        expect(result.slide.containsKey('key'), isFalse);
        expect(store.slides.map((slide) => slide.options?.title), [
          'Seed',
          'New',
        ]);

        service.dispose();
      },
    );

    test(
      'createSlide maps invalid integer insert indices to range error',
      () async {
        final store = _MutableDeckStore([_slide('seed')]);
        final service = _service(store);

        await expectLater(
          service.createSlide(
            CreateSlideRequestType.parse({
              'slide': _deckToolSlide(),
              'atIndex': -1,
            }),
          ),
          throwsA(_rangeErrorMatcher),
        );
        expect(store.slides, hasLength(1));

        service.dispose();
      },
    );

    test('update, delete, and move operate by live index', () async {
      final store = _MutableDeckStore([
        _slide('a', title: 'A'),
        _slide('b', title: 'B'),
        _slide('c', title: 'C'),
      ]);
      final service = _service(store);

      final updated = await service.updateSlide(
        UpdateSlideRequestType.parse({
          'index': 1,
          'slide': _deckToolSlide(title: 'B2'),
        }),
      );
      expect(updated.index, 1);
      expect(store.slides[1].options?.title, 'B2');

      final moved = await service.moveSlide(
        MoveSlideRequestType.parse({'fromIndex': 0, 'toIndex': 2}),
      );
      expect(moved.fromIndex, 0);
      expect(moved.toIndex, 2);
      expect(store.slides.map((slide) => slide.options?.title), [
        'B2',
        'C',
        'A',
      ]);

      final deleted = await service.deleteSlide(
        DeleteSlideRequestType.parse({'index': 1}),
      );
      expect(deleted.totalSlides, 2);
      expect(store.slides.map((slide) => slide.options?.title), ['B2', 'A']);

      service.dispose();
    });

    test(
      'readSlide returns keyless slide and base64 thumbnail from one snapshot',
      () async {
        final store = _MutableDeckStore([_slide('a', title: 'Intro')]);
        final service = _service(
          store,
          captureSlide: (configuration) async {
            expect(configuration.slide.options?.title, 'Intro');
            return Uint8List.fromList([1, 2, 3]);
          },
        );

        final result = await service.readSlide(
          ReadSlideRequestType.parse({'index': 0}),
        );

        expect(result.index, 0);
        expect(result.title, 'Intro');
        expect(result.slide.containsKey('key'), isFalse);
        expect(result.thumbnailBase64, base64Encode([1, 2, 3]));
        expect(result.deck.totalSlides, 1);

        service.dispose();
      },
    );

    test(
      'readSlide classifies route disposal during capture as context_unavailable',
      () async {
        final store = _MutableDeckStore([_slide('a')]);
        var available = true;
        final service = _service(
          store,
          isAvailable: () => available,
          captureSlide: (_) async {
            available = false;
            throw StateError('disposed');
          },
        );

        await expectLater(
          service.readSlide(ReadSlideRequestType.parse({'index': 0})),
          _throwsDeckToolCode(DeckToolErrorCode.contextUnavailable),
        );

        service.dispose();
      },
    );

    test(
      'readSlide does not capture when runtime is unavailable before capture',
      () async {
        final store = _MutableDeckStore([_slide('a')]);
        var captureCalled = false;
        final service = _service(
          store,
          isAvailable: () => false,
          captureSlide: (_) async {
            captureCalled = true;
            return Uint8List.fromList([1]);
          },
        );

        await expectLater(
          service.readSlide(ReadSlideRequestType.parse({'index': 0})),
          _throwsDeckToolCode(DeckToolErrorCode.contextUnavailable),
        );
        expect(captureCalled, isFalse);

        service.dispose();
      },
    );

    test(
      'readSlide classifies route disposal after capture as context_unavailable',
      () async {
        final store = _MutableDeckStore([_slide('a')]);
        var available = true;
        final service = _service(
          store,
          isAvailable: () => available,
          captureSlide: (_) async {
            available = false;
            return Uint8List.fromList([1]);
          },
        );

        await expectLater(
          service.readSlide(ReadSlideRequestType.parse({'index': 0})),
          _throwsDeckToolCode(DeckToolErrorCode.contextUnavailable),
        );

        service.dispose();
      },
    );

    test('readSlide maps real capture failures to capture_failed', () async {
      final store = _MutableDeckStore([_slide('a')]);
      final service = _service(
        store,
        captureSlide: (_) async => throw StateError('render failed'),
      );

      await expectLater(
        service.readSlide(ReadSlideRequestType.parse({'index': 0})),
        _throwsDeckToolCode(DeckToolErrorCode.captureFailed),
      );

      service.dispose();
    });

    test('getDeck waits for queued side effects before reading', () async {
      final writeGate = Completer<void>();
      final store = _MutableDeckStore([_slide('seed')], writeGate);
      final service = _service(store);

      final mutation = service.createSlide(
        CreateSlideRequestType.parse({
          'slide': _deckToolSlide(title: 'Queued'),
        }),
      );
      await Future<void>.delayed(Duration.zero);

      final read = service.getDeck();
      var readCompleted = false;
      unawaited(read.then((_) => readCompleted = true));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(readCompleted, isFalse);

      writeGate.complete();
      await mutation;
      final snapshot = await read;

      expect(snapshot.totalSlides, 2);
      expect(readCompleted, isTrue);

      service.dispose();
    });

    test(
      'updateStyle applies style out-of-band and keeps deck snapshot style-free',
      () async {
        final store = _MutableDeckStore([_slide('seed')]);
        DeckStyleType? appliedStyle;
        final service = _service(
          store,
          applyStyle: (style) => appliedStyle = style,
        );

        final result = await service.updateStyle(
          UpdateStyleRequestType.parse({'style': _styleMap()}),
        );

        expect(appliedStyle?.name, 'Updated');
        expect(result.deck.containsKey('style'), isFalse);

        service.dispose();
      },
    );
  });

  group('DeckToolsAdapter', () {
    test('exposes exactly seven deck-edit tools including readSlide', () {
      final store = _MutableDeckStore();
      final service = _service(store);
      final adapter = DeckToolsAdapter(service);

      expect(adapter.tools.map((tool) => tool.name), [
        'getDeck',
        'createSlide',
        'updateSlide',
        'deleteSlide',
        'moveSlide',
        'readSlide',
        'updateStyle',
      ]);

      adapter.dispose();
      service.dispose();
    });

    test(
      'maps incoming key to validation_failed without invoking service',
      () async {
        final store = _MutableDeckStore([_slide('seed')]);
        final service = _service(store);
        final adapter = DeckToolsAdapter(service);
        final tool = adapter.tools.firstWhere(
          (tool) => tool.name == 'createSlide',
        );

        final result = await tool.invoke({
          'slide': {..._deckToolSlide(), 'key': 'stale'},
        });

        expect(result['error'], isA<Map>());
        expect((result['error']! as Map)['code'], 'validation_failed');
        expect(store.slides, hasLength(1));

        adapter.dispose();
        service.dispose();
      },
    );

    test('closed session preflight wins over malformed payloads', () async {
      final store = _MutableDeckStore();
      final service = _service(store)..closeSession();
      final adapter = DeckToolsAdapter(service);
      final tool = adapter.tools.firstWhere(
        (tool) => tool.name == 'updateSlide',
      );

      final result = await tool.invoke({'not': 'a valid payload'});

      expect((result['error']! as Map)['code'], 'context_unavailable');

      adapter.dispose();
      service.dispose();
    });
  });
}

Matcher _throwsDeckToolCode(String code) => throwsA(_deckToolCodeMatcher(code));

Matcher get _rangeErrorMatcher =>
    _deckToolCodeMatcher(DeckToolErrorCode.slideIndexOutOfRange);

Matcher _deckToolCodeMatcher(String code) =>
    isA<DeckToolException>().having((error) => error.code, 'code', code);

DeckToolsService _service(
  _MutableDeckStore store, {
  bool Function()? isAvailable,
  Future<Uint8List> Function(SlideConfiguration configuration)? captureSlide,
  FutureOr<void> Function(DeckStyleType style)? applyStyle,
}) {
  final runtime = DeckToolsRuntime(
    slideConfigurationsProvider: () =>
        store.slides.asMap().entries.map((entry) {
          return SlideConfiguration(
            slideIndex: entry.key,
            style: SlideStyle(),
            slide: entry.value,
            thumbnailKey: 'thumbnail-${entry.key}.png',
          );
        }).toList(),
    captureSlide: captureSlide ?? (_) async => Uint8List(0),
    applyStyle: applyStyle ?? (_) {},
    isAvailable: isAvailable ?? () => true,
  );

  return DeckToolsService(documentStore: store, runtime: runtime);
}

class _MutableDeckStore implements DeckStore {
  _MutableDeckStore([List<Slide>? slides, this.writeGate])
    : slides = List<Slide>.from(slides ?? const []);

  final Completer<void>? writeGate;
  final List<Slide> slides;

  @override
  Future<DeckDocument> readRequired() async {
    return DeckDocument(slides: List<Slide>.unmodifiable(slides));
  }

  @override
  Future<String> flushMarkdownToCanonical(String markdown) =>
      writeCanonicalMarkdown(markdown);

  @override
  Future<void> writeCanonical(List<Slide> nextSlides) async {
    slides
      ..clear()
      ..addAll(nextSlides);
    await writeGate?.future;
  }

  @override
  Future<String> writeCanonicalMarkdown(String markdown) async => markdown;
}

Slide _slide(String key, {String title = 'Title', String content = 'Body'}) {
  return Slide(
    key: key,
    options: SlideOptions(title: title),
    sections: [
      SectionBlock([ContentBlock(content)]),
    ],
  );
}

Map<String, Object?> _deckToolSlide({String title = 'Slide'}) {
  return {
    'options': {'title': title},
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
    'name': 'Updated',
    'colors': {
      'background': '#FFFFFF',
      'heading': '#112233',
      'body': '#445566',
    },
    'fonts': {'headline': 'montserrat', 'body': 'openSans'},
  };
}
