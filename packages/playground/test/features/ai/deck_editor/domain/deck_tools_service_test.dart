import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_store.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_tool_error.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_tools_service.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('DeckToolsService slide operations', () {
    test('getDeck returns a style-free, keyless summary', () async {
      final service = DeckToolsService(
        deckStore: _FakeDeckStore([_slide('a', title: 'A'), _slide('b')]),
      );

      expect(await service.getDeck(), {
        'totalSlides': 2,
        'slides': [
          {'index': 0, 'title': 'A'},
          {'index': 1},
        ],
      });
    });

    test('create without atIndex appends at the live slide count', () async {
      final store = _FakeDeckStore([_slide('a')]);
      final service = DeckToolsService(deckStore: store);

      final result = await service.createSlide(_slide('b', title: 'B'));

      expect(result['index'], 1);
      expect((result['slide'] as Map<String, Object?>), isNot(contains('key')));
      expect((result['deck'] as Map<String, Object?>)['totalSlides'], 2);
      expect(store.slides.map((slide) => slide.key), ['a', 'b']);
    });

    test('create inserts at every valid boundary', () async {
      final store = _FakeDeckStore([_slide('b')]);
      final service = DeckToolsService(deckStore: store);

      await service.createSlide(_slide('a'), atIndex: 0);
      await service.createSlide(_slide('c'), atIndex: 2);

      expect(store.slides.map((slide) => slide.key), ['a', 'b', 'c']);
    });

    test('update returns the canonical post-write slide and deck', () async {
      final store = _CanonicalizingDeckStore([_slide('a')]);
      final service = DeckToolsService(deckStore: store);

      final result = await service.updateSlide(
        0,
        _slide('request-key', title: 'Updated'),
      );

      expect((result['slide'] as Map<String, Object?>), isNot(contains('key')));
      expect(
        ((result['slide'] as Map<String, Object?>)['options'] as Map)['title'],
        'Updated',
      );
      expect(store.slides.single.key, 'canonical-key');
    });

    test('delete returns the remaining deck snapshot', () async {
      final store = _FakeDeckStore([_slide('a'), _slide('b')]);
      final service = DeckToolsService(deckStore: store);

      final result = await service.deleteSlide(0);

      expect(result['totalSlides'], 1);
      expect(store.slides.single.key, 'b');
    });

    test('move toIndex is the final index after the move', () async {
      final store = _FakeDeckStore([_slide('a'), _slide('b'), _slide('c')]);
      final service = DeckToolsService(deckStore: store);

      final result = await service.moveSlide(0, 2);

      expect(store.slides.map((slide) => slide.key), ['b', 'c', 'a']);
      expect(result['fromIndex'], 0);
      expect(result['toIndex'], 2);
    });

    test('all invalid integer ranges use slide_index_out_of_range', () async {
      final service = DeckToolsService(
        deckStore: _FakeDeckStore([_slide('a')]),
      );

      final operations = <Future<Object?> Function()>[
        () => service.createSlide(_slide('b'), atIndex: -1),
        () => service.createSlide(_slide('b'), atIndex: 2),
        () => service.updateSlide(1, _slide('b')),
        () => service.deleteSlide(-1),
        () => service.moveSlide(1, 0),
        () => service.moveSlide(0, 1),
      ];

      for (final operation in operations) {
        await expectLater(
          operation(),
          throwsA(
            isA<DeckToolError>().having(
              (error) => error.code,
              'code',
              DeckToolErrorCode.slideIndexOutOfRange,
            ),
          ),
        );
      }
    });

    test(
      'two immediate creates are serialized and retain both slides',
      () async {
        final store = _FakeDeckStore([_slide('a')], writeDelay: Duration.zero);
        final service = DeckToolsService(deckStore: store);

        final first = service.createSlide(_slide('b'));
        final second = service.createSlide(_slide('c'));
        await Future.wait([first, second]);

        expect(store.slides.map((slide) => slide.key), ['a', 'b', 'c']);
      },
    );

    test(
      'a failed queued operation does not poison the next operation',
      () async {
        final store = _FakeDeckStore([_slide('a')]);
        final service = DeckToolsService(deckStore: store);

        final invalid = service.deleteSlide(9);
        final valid = service.createSlide(_slide('b'));

        await expectLater(invalid, throwsA(isA<DeckToolError>()));
        await valid;
        expect(store.slides.map((slide) => slide.key), ['a', 'b']);
      },
    );

    test('closed services reject queued work before side effects', () async {
      final writeGate = Completer<void>();
      final store = _FakeDeckStore([_slide('a')], writeGate: writeGate);
      final service = DeckToolsService(deckStore: store);

      final admitted = service.createSlide(_slide('b'));
      await store.writeStarted.future;
      service.close();
      final rejected = service.createSlide(_slide('c'));
      writeGate.complete();

      await admitted;
      await expectLater(
        rejected,
        throwsA(
          isA<DeckToolError>().having(
            (error) => error.code,
            'code',
            DeckToolErrorCode.contextUnavailable,
          ),
        ),
      );
      expect(store.slides.map((slide) => slide.key), ['a', 'b']);
    });

    test('readSlide synchronizes preview before capture', () async {
      final store = _FakeDeckStore([_slide('a')]);
      var captures = 0;
      final service = DeckToolsService(
        deckStore: store,
        readSlide: (index) {
          captures++;
          return {'index': index};
        },
      );

      expect(await service.readSlide(0), {'index': 0});
      expect(store.synchronizeCalls, 1);
      expect(captures, 1);
    });

    test('updateStyle is queued and marks the session dirty', () async {
      final store = _FakeDeckStore([_slide('a')]);
      var dirtyCount = 0;
      final service = DeckToolsService(
        deckStore: store,
        updateStyle: (style) => {'style': style},
        onDirty: () => dirtyCount++,
      );

      final result = await service.updateStyle({'name': 'Test'});

      expect(result['style'], {'name': 'Test'});
      expect(dirtyCount, 1);
    });
  });
}

Slide _slide(String key, {String? title}) {
  return Slide(
    key: key,
    options: title == null ? null : SlideOptions(title: title),
    sections: [SectionBlock.text('# ${title ?? key}')],
  );
}

class _FakeDeckStore implements DeckStore {
  _FakeDeckStore(
    List<Slide> slides, {
    this.writeDelay = Duration.zero,
    this.writeGate,
  }) : slides = List.of(slides);

  List<Slide> slides;
  final Duration writeDelay;
  final Completer<void>? writeGate;
  final writeStarted = Completer<void>();
  var synchronizeCalls = 0;

  @override
  List<Slide> read() => List.unmodifiable(slides);

  @override
  Future<List<Slide>> restore(String markdown) =>
      throw UnimplementedError('Not needed by this test');

  @override
  Future<List<Slide>> synchronize() async {
    synchronizeCalls++;
    return read();
  }

  @override
  Future<List<Slide>> write(List<Slide> updated) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    if (writeGate != null) await writeGate!.future;
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
    slides = List.of(updated);
    return read();
  }
}

class _CanonicalizingDeckStore extends _FakeDeckStore {
  _CanonicalizingDeckStore(super.slides);

  @override
  Future<List<Slide>> write(List<Slide> updated) async {
    final canonical = [
      for (final slide in updated)
        Slide(
          key: 'canonical-key',
          options: slide.options,
          sections: slide.sections,
          comments: slide.comments,
        ),
    ];
    return super.write(canonical);
  }
}
