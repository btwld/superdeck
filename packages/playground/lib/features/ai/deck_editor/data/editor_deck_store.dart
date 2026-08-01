import 'dart:async';

import 'package:signals/signals.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../../core/data/mappers/deck_markdown_codec.dart';
import '../../../editor/domain/stores/deck_document_store.dart';
import '../domain/deck_store.dart';
import '../domain/deck_tool_error.dart';

/// Bridges queued tool operations to the live editor and rendered preview.
final class EditorDeckStore implements DeckStore {
  EditorDeckStore({
    required DeckDocumentStore documentStore,
    required DeckController deckController,
    DeckMarkdownCodec codec = const DeckMarkdownCodec(),
    Duration barrierTimeout = const Duration(seconds: 2),
  }) : _documentStore = documentStore,
       _deckController = deckController,
       _codec = codec,
       _barrierTimeout = barrierTimeout;

  final DeckDocumentStore _documentStore;
  final DeckController _deckController;
  final DeckMarkdownCodec _codec;
  final Duration _barrierTimeout;

  @override
  List<Slide> read() {
    try {
      return _codec.decode(_documentStore.markdown);
    } catch (error) {
      throw DeckToolError(
        DeckToolErrorCode.deckParseFailed,
        'The current editor document could not be parsed.',
        cause: error,
      );
    }
  }

  @override
  Future<List<Slide>> write(List<Slide> slides) {
    final expected = _codec.encode(slides);
    try {
      _documentStore.replaceMarkdown(expected);
    } catch (error) {
      throw DeckToolError(
        DeckToolErrorCode.deckWriteFailed,
        'The editor document could not be replaced.',
        cause: error,
      );
    }
    return _awaitPreview(expected);
  }

  @override
  Future<List<Slide>> restore(String markdown) {
    final decoded = _decodeForWrite(markdown);
    final expected = _codec.encode(decoded);
    try {
      _documentStore.replaceMarkdown(markdown);
    } catch (error) {
      throw DeckToolError(
        DeckToolErrorCode.deckWriteFailed,
        'The baseline editor document could not be restored.',
        cause: error,
      );
    }
    return _awaitPreview(expected);
  }

  @override
  Future<List<Slide>> synchronize() {
    final expected = _codec.encode(read());
    return _awaitPreview(expected);
  }

  List<Slide> _decodeForWrite(String markdown) {
    try {
      return _codec.decode(markdown);
    } catch (error) {
      throw DeckToolError(
        DeckToolErrorCode.deckWriteFailed,
        'The baseline editor document is not a valid deck.',
        cause: error,
      );
    }
  }

  Future<List<Slide>> _awaitPreview(String expectedMarkdown) {
    final completer = Completer<List<Slide>>();
    EffectCleanup? cleanup;
    late final Timer timer;

    void completeError(Object error) {
      if (completer.isCompleted) return;
      completer.completeError(
        DeckToolError(
          DeckToolErrorCode.deckWriteFailed,
          'The live preview did not observe the editor document.',
          cause: error,
        ),
      );
    }

    timer = Timer(
      _barrierTimeout,
      () =>
          completeError(TimeoutException('Preview synchronization timed out.')),
    );

    cleanup = effect(() {
      try {
        final configurations = _deckController.slides.value;
        final sessionError =
            _deckController.session.error.value ??
            _deckController.session.buildFailure.value;
        if (sessionError != null) {
          completeError(sessionError);
          return;
        }

        final observed = [
          for (final configuration in configurations) configuration.slide,
        ];
        if (_codec.encode(observed) == expectedMarkdown &&
            !completer.isCompleted) {
          completer.complete(List<Slide>.unmodifiable(observed));
        }
      } catch (error) {
        completeError(error);
      }
    });

    return completer.future.whenComplete(() {
      timer.cancel();
      cleanup?.call();
    });
  }
}
