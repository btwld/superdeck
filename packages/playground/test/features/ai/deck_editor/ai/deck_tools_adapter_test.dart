import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/deck_editor/ai/deck_tools_adapter.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_store.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_tools_service.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  test('registers exactly the six deck-edit tools with provider schemas', () {
    final adapter = DeckToolsAdapter(
      DeckToolsService(deckStore: _MemoryDeckStore([_slide('a')])),
    );

    expect(adapter.tools.map((tool) => tool.name), [
      'getDeck',
      'createSlide',
      'updateSlide',
      'deleteSlide',
      'moveSlide',
      'readSlide',
    ]);
    for (final tool in adapter.tools) {
      expect(tool.inputSchema.value, isA<Map<String, Object?>>());
    }
  });

  test('calls the service and returns JSON-encodable success data', () async {
    final adapter = DeckToolsAdapter(
      DeckToolsService(deckStore: _MemoryDeckStore([_slide('a')])),
    );
    final tool = adapter.tools.singleWhere(
      (tool) => tool.name == 'createSlide',
    );

    final result = await tool.call({
      'slide': {
        'options': {'title': 'Created'},
        'sections': [
          {
            'blocks': [
              {'type': 'block', 'content': '# Created'},
            ],
          },
        ],
      },
    });

    expect(result, isA<Map<String, Object?>>());
    expect((result as Map)['error'], isNull);
    expect(result['index'], 1);
  });

  test('maps Ack validation failures to validation_failed', () async {
    final adapter = DeckToolsAdapter(
      DeckToolsService(deckStore: _MemoryDeckStore([_slide('a')])),
    );
    final tool = adapter.tools.singleWhere(
      (tool) => tool.name == 'updateSlide',
    );

    final result = await tool.call({
      'index': 0,
      'slide': {'key': 'forbidden', 'sections': <Object?>[]},
    });

    expect(result, {
      'error': {'code': 'validation_failed', 'message': isA<String>()},
    });
  });

  test('maps typed service failures to their stable code', () async {
    final adapter = DeckToolsAdapter(
      DeckToolsService(deckStore: _MemoryDeckStore([_slide('a')])),
    );
    final tool = adapter.tools.singleWhere(
      (tool) => tool.name == 'deleteSlide',
    );

    final result = await tool.call({'index': 9});

    expect((result as Map)['error'], {
      'code': 'slide_index_out_of_range',
      'message': isA<String>(),
    });
  });

  test('sanitizes unexpected failures as internal_error', () async {
    final adapter = DeckToolsAdapter(
      DeckToolsService(deckStore: _ThrowingDeckStore()),
    );
    final tool = adapter.tools.singleWhere((tool) => tool.name == 'getDeck');

    final result = await tool.call({});

    expect(result, {
      'error': {
        'code': 'internal_error',
        'message': 'The deck tool could not complete the request.',
      },
    });
    expect(result.toString(), isNot(contains('provider-secret-token')));
  });

  test('readSlide reaches its queued service operation', () async {
    final service = DeckToolsService(
      deckStore: _MemoryDeckStore([_slide('a')]),
      readSlide: (index) => {'index': index, 'thumbnailBase64': 'iVBORw=='},
    );
    final adapter = DeckToolsAdapter(service);

    final readResult = await adapter.tools
        .singleWhere((tool) => tool.name == 'readSlide')
        .call({'index': 0});

    expect(readResult['thumbnailBase64'], 'iVBORw==');
  });
}

Slide _slide(String key) =>
    Slide(key: key, sections: [SectionBlock.text('# $key')]);

class _MemoryDeckStore implements DeckStore {
  _MemoryDeckStore(List<Slide> slides) : _slides = List.of(slides);

  List<Slide> _slides;

  @override
  List<Slide> read() => List.unmodifiable(_slides);

  @override
  Future<List<Slide>> restore(String markdown) =>
      throw UnimplementedError('Not used');

  @override
  Future<List<Slide>> synchronize() async => read();

  @override
  Future<List<Slide>> write(List<Slide> slides) async {
    _slides = List.of(slides);
    return read();
  }
}

class _ThrowingDeckStore implements DeckStore {
  @override
  List<Slide> read() => throw StateError('provider-secret-token');

  @override
  Future<List<Slide>> restore(String markdown) => throw UnimplementedError();

  @override
  Future<List<Slide>> synchronize() => throw UnimplementedError();

  @override
  Future<List<Slide>> write(List<Slide> slides) => throw UnimplementedError();
}
