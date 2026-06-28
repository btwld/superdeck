import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart' show SlideConfiguration;
import 'package:superdeck_core/superdeck_core.dart';

import '../ai/services/style_json_serializer.dart';
import 'deck_mutation_helpers.dart' as mutation;
import 'deck_store.dart';
import 'deck_tools_runtime.dart';
import 'deck_tools_schemas.dart';
import 'errors.dart';

/// In-app deck tooling service for slide CRUD, capture, and style updates.
class DeckToolsService {
  DeckToolsService({
    required DeckStore documentStore,
    required DeckToolsRuntime runtime,
  }) : _documentStore = documentStore,
       _runtime = runtime;

  final DeckStore _documentStore;
  final DeckToolsRuntime _runtime;

  final Signal<int> _outstandingSideEffects = signal<int>(0);
  Future<void> _sideEffectQueue = Future<void>.value();
  bool _closed = false;
  bool _disposed = false;

  bool get isClosed => _closed;

  late final Computed<bool> isSideEffectQueueIdle = computed(() {
    return _outstandingSideEffects.value == 0;
  });

  void closeSession() {
    _closed = true;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    closeSession();
    _disposeSignalsIfIdle();
  }

  Future<DeckSnapshotType> getDeck() async {
    _ensureAvailable();
    await _drainSideEffects();
    _ensureAvailable();

    final document = await _documentStore.readRequired();
    _ensureAvailable();
    return mutation.buildDeckSnapshot(document.slides);
  }

  Future<ReadSlideResultType> readSlide(ReadSlideRequestType request) async {
    _ensureAvailable();
    await _drainSideEffects();
    _ensureAvailable();

    final snapshot = _runtime.snapshotSlideConfigurations();
    final index = request.index;
    mutation.validateReadIndex(index, snapshot.length);

    final configuration = snapshot[index];
    final slide = configuration.slide;

    _ensureAvailable();
    final bytes = await _captureSlideBytes(configuration);
    _ensureAvailable();

    return ReadSlideResultType.parse({
      'index': index,
      if (slide.options?.title case final title?) 'title': title,
      'slide': _deckToolSlideMap(slide),
      'thumbnailBase64': base64Encode(bytes),
      'deck': deckSnapshotSchema.encode(
        mutation.buildDeckSnapshot(snapshot.map((c) => c.slide).toList()),
      )!,
    });
  }

  Future<SlideMutationResultType> createSlide(CreateSlideRequestType request) {
    return _runSideEffect(() async {
      final document = await _documentStore.readRequired();
      final insertIndex = request.atIndex ?? document.slides.length;
      mutation.validateInsertIndex(insertIndex, document.slides.length);

      final slide = _parseToolSlide(request.slide);
      final updatedSlides = mutation.insertSlideAt(
        document.slides,
        slide,
        insertIndex,
      );

      _ensureAvailable();
      await _documentStore.writeCanonical(updatedSlides);
      _ensureAvailable();

      final postWrite = await _documentStore.readRequired();
      mutation.validateReadIndex(insertIndex, postWrite.slides.length);
      return SlideMutationResultType.parse({
        'index': insertIndex,
        'slide': _deckToolSlideMap(postWrite.slides[insertIndex]),
        'deck': deckSnapshotSchema.encode(
          mutation.buildDeckSnapshot(postWrite.slides),
        )!,
      });
    });
  }

  Future<SlideMutationResultType> updateSlide(UpdateSlideRequestType request) {
    return _runSideEffect(() async {
      final document = await _documentStore.readRequired();
      final index = request.index;
      mutation.validateReadIndex(index, document.slides.length);

      final updatedSlide = _parseToolSlide(request.slide);
      final updatedSlides = mutation.replaceSlideAt(
        document.slides,
        index,
        updatedSlide,
      );

      _ensureAvailable();
      await _documentStore.writeCanonical(updatedSlides);
      _ensureAvailable();

      final postWrite = await _documentStore.readRequired();
      mutation.validateReadIndex(index, postWrite.slides.length);
      return SlideMutationResultType.parse({
        'index': index,
        'slide': _deckToolSlideMap(postWrite.slides[index]),
        'deck': deckSnapshotSchema.encode(
          mutation.buildDeckSnapshot(postWrite.slides),
        )!,
      });
    });
  }

  Future<DeckSnapshotType> deleteSlide(DeleteSlideRequestType request) {
    return _runSideEffect(() async {
      final document = await _documentStore.readRequired();
      final updatedSlides = mutation.removeSlideAt(
        document.slides,
        request.index,
      );

      _ensureAvailable();
      await _documentStore.writeCanonical(updatedSlides);
      _ensureAvailable();

      final postWrite = await _documentStore.readRequired();
      return mutation.buildDeckSnapshot(postWrite.slides);
    });
  }

  Future<SlideMoveResultType> moveSlide(MoveSlideRequestType request) {
    return _runSideEffect(() async {
      final document = await _documentStore.readRequired();
      final updatedSlides = mutation.moveSlide(
        document.slides,
        request.fromIndex,
        request.toIndex,
      );

      _ensureAvailable();
      await _documentStore.writeCanonical(updatedSlides);
      _ensureAvailable();

      final postWrite = await _documentStore.readRequired();
      return SlideMoveResultType.parse({
        'fromIndex': request.fromIndex,
        'toIndex': request.toIndex,
        'deck': deckSnapshotSchema.encode(
          mutation.buildDeckSnapshot(postWrite.slides),
        )!,
      });
    });
  }

  Future<StyleUpdateResultType> updateStyle(UpdateStyleRequestType request) {
    return _runSideEffect(() async {
      final style = request.style;
      final document = await _documentStore.readRequired();

      _ensureAvailable();
      await _runtime.applyStyle(style);
      await Future<void>.delayed(Duration.zero);
      _ensureAvailable();

      final postStyle = await _documentStore.readRequired();
      return StyleUpdateResultType.parse({
        'style': serializeDeckStyleForJson(style),
        'deck': deckSnapshotSchema.encode(
          mutation.buildDeckSnapshot(
            postStyle.slides.isEmpty ? document.slides : postStyle.slides,
          ),
        )!,
      });
    });
  }

  Future<T> _runSideEffect<T>(Future<T> Function() operation) {
    _ensureAvailable();

    final completer = Completer<T>();
    _outstandingSideEffects.value++;

    _sideEffectQueue = _sideEffectQueue
        .catchError((Object _, StackTrace _) {})
        .then((_) async {
          try {
            _ensureAvailable();
            completer.complete(await operation());
          } catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          } finally {
            _outstandingSideEffects.value--;
            if (_disposed) {
              _disposeSignalsIfIdle();
            }
          }
        });

    return completer.future;
  }

  void _disposeSignalsIfIdle() {
    if (_outstandingSideEffects.value > 0) {
      return;
    }

    isSideEffectQueueIdle.dispose();
    _outstandingSideEffects.dispose();
  }

  Future<void> _drainSideEffects() async {
    try {
      await _sideEffectQueue;
    } catch (_) {
      // The caller should read the live state after any failed write attempt.
    }
  }

  Slide _parseToolSlide(DeckToolSlideType toolSlide) {
    final map = Map<String, Object?>.from(toolSlide);
    if (map.containsKey('key')) {
      throw DeckToolException.invalidArgument(
        'DeckToolSlide must not include key',
      );
    }

    try {
      return Slide.parse({'key': _transientKeyFor(map), ...map});
    } catch (error) {
      throw DeckToolException.invalidArgument('Invalid slide payload: $error');
    }
  }

  Map<String, Object?> _deckToolSlideMap(Slide slide) {
    final map = Map<String, Object?>.from(slide.toMap())..remove('key');
    return Map<String, Object?>.from(
      deckToolSlideSchema.encode(DeckToolSlideType.parse(map))!,
    );
  }

  String _transientKeyFor(Map<String, Object?> slideMap) {
    return 'ai-${base64Url.encode(utf8.encode(jsonEncode(slideMap))).replaceAll('=', '').take(24)}';
  }

  void _ensureAvailable() {
    if (_closed || !_runtime.isAvailable()) {
      throw DeckToolException.contextUnavailable();
    }
  }

  Future<Uint8List> _captureSlideBytes(SlideConfiguration configuration) async {
    try {
      _ensureAvailable();
      return await _runtime.captureSlide(configuration);
    } on DeckToolException {
      rethrow;
    } catch (error) {
      if (_closed || !_runtime.isAvailable()) {
        throw DeckToolException.contextUnavailable();
      }
      throw DeckToolException.captureFailed(error);
    }
  }
}

extension on String {
  String take(int maxLength) {
    if (length <= maxLength) return this;
    return substring(0, maxLength);
  }
}
