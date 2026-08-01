import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

import 'deck_store.dart';
import 'deck_tool_error.dart';

typedef ReadSlideOperation = FutureOr<Map<String, Object?>> Function(int index);
typedef UpdateStyleOperation =
    FutureOr<Map<String, Object?>> Function(Object? style);

/// Serializes all deck tool operations through one error-recovering FIFO queue.
final class DeckToolsService {
  DeckToolsService({
    required DeckStore deckStore,
    ReadSlideOperation? readSlide,
    UpdateStyleOperation? updateStyle,
    void Function()? onDirty,
  }) : _deckStore = deckStore,
       _readSlide = readSlide,
       _updateStyle = updateStyle,
       _onDirty = onDirty;

  final DeckStore _deckStore;
  final ReadSlideOperation? _readSlide;
  final UpdateStyleOperation? _updateStyle;
  final void Function()? _onDirty;

  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  void close() => _closed = true;

  Future<Map<String, Object?>> getDeck() {
    return _enqueue(() => _snapshot(_deckStore.read()));
  }

  Future<Map<String, Object?>> createSlide(Slide slide, {int? atIndex}) {
    return _enqueue(() async {
      final current = _deckStore.read();
      final index = atIndex ?? current.length;
      _validateInsertionIndex(index, current.length);
      final updated = List<Slide>.of(current)..insert(index, slide);
      final written = await _write(updated);
      return {
        'index': index,
        'slide': _keyless(written[index]),
        'deck': _snapshot(written),
      };
    });
  }

  Future<Map<String, Object?>> updateSlide(int index, Slide slide) {
    return _enqueue(() async {
      final current = _deckStore.read();
      _validateExistingIndex(index, current.length);
      final updated = List<Slide>.of(current)..[index] = slide;
      final written = await _write(updated);
      return {
        'index': index,
        'slide': _keyless(written[index]),
        'deck': _snapshot(written),
      };
    });
  }

  Future<Map<String, Object?>> deleteSlide(int index) {
    return _enqueue(() async {
      final current = _deckStore.read();
      _validateExistingIndex(index, current.length);
      final updated = List<Slide>.of(current)..removeAt(index);
      return _snapshot(await _write(updated));
    });
  }

  Future<Map<String, Object?>> moveSlide(int fromIndex, int toIndex) {
    return _enqueue(() async {
      final current = _deckStore.read();
      _validateExistingIndex(fromIndex, current.length);
      _validateExistingIndex(toIndex, current.length);
      final updated = List<Slide>.of(current);
      final slide = updated.removeAt(fromIndex);
      updated.insert(toIndex, slide);
      final written = await _write(updated);
      return {
        'fromIndex': fromIndex,
        'toIndex': toIndex,
        'deck': _snapshot(written),
      };
    });
  }

  Future<Map<String, Object?>> readSlide(int index) {
    return _enqueue(() async {
      final current = await _deckStore.synchronize();
      _validateExistingIndex(index, current.length);
      final operation = _readSlide;
      if (operation == null) {
        throw const DeckToolError(
          DeckToolErrorCode.contextUnavailable,
          'Slide capture is unavailable in this session.',
        );
      }
      _ensureOpen();
      return operation(index);
    });
  }

  Future<Map<String, Object?>> updateStyle(Object? style) {
    return _enqueue(() async {
      final operation = _updateStyle;
      if (operation == null) {
        throw const DeckToolError(
          DeckToolErrorCode.contextUnavailable,
          'Style editing is unavailable in this session.',
        );
      }
      _ensureOpen();
      final result = operation(style);
      _onDirty?.call();
      return result;
    });
  }

  Future<List<Slide>> _write(List<Slide> slides) {
    _ensureOpen();
    final barrier = _deckStore.write(slides);
    _onDirty?.call();
    return barrier;
  }

  Future<T> _enqueue<T>(FutureOr<T> Function() operation) {
    final result = _tail.then((_) async {
      _ensureOpen();
      return operation();
    });
    _tail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  void _ensureOpen() {
    if (_closed) {
      throw const DeckToolError(
        DeckToolErrorCode.contextUnavailable,
        'The deck editing session is closed.',
      );
    }
  }

  void _validateInsertionIndex(int index, int length) {
    if (index < 0 || index > length) {
      throw DeckToolError(
        DeckToolErrorCode.slideIndexOutOfRange,
        'Slide insertion index $index is outside 0..$length.',
      );
    }
  }

  void _validateExistingIndex(int index, int length) {
    if (index < 0 || index >= length) {
      throw DeckToolError(
        DeckToolErrorCode.slideIndexOutOfRange,
        'Slide index $index is outside 0..<$length.',
      );
    }
  }

  Map<String, Object?> _keyless(Slide slide) {
    return Map<String, Object?>.from(slide.toMap())..remove('key');
  }

  Map<String, Object?> _snapshot(List<Slide> slides) {
    return {
      'totalSlides': slides.length,
      'slides': [
        for (final (index, slide) in slides.indexed)
          {'index': index, 'title': ?slide.options?.title},
      ],
    };
  }
}
