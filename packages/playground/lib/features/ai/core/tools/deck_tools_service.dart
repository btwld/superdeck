import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/ai/services/slide_key_utils.dart';
import 'package:playground/features/ai/core/ai/services/style_json_serializer.dart';
import 'package:playground/features/ai/core/superdeck_slide_configurations.dart';
import 'package:playground/features/ai/core/tools/deck_mutation_helpers.dart' as mutation;
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/deck_tools_schemas.dart';
import 'package:playground/features/ai/core/tools/errors.dart';
import 'package:playground/features/ai/core/utils/deck_style_service.dart';
import 'package:playground/features/ai/core/utils/style_builder.dart';
import 'package:playground/features/ai/presentation/thumbnail_preview_service.dart';

typedef BuildContextProvider = BuildContext? Function();

/// Builds the slide configuration used by `readSlide`.
///
/// Tests can inject a lightweight builder to avoid font/asset side effects.
typedef ReadSlideConfigurationBuilder =
    FutureOr<SlideConfiguration> Function({
      required Slide slide,
      required DeckStyleType? style,
      required int index,
    });

/// In-app deck tooling service for slide CRUD and style updates.
class DeckToolsService {
  DeckToolsService({
    DeckStore? documentStore,
    BuildContextProvider? contextProvider,
    SlideCaptureFn? captureSlide,
    ReadSlideConfigurationBuilder? buildReadSlideConfiguration,
  }) : _documentStore = documentStore,
       _contextProvider = contextProvider ?? _defaultContextProvider,
       _captureSlide = captureSlide,
       _buildReadSlideConfiguration =
           buildReadSlideConfiguration ?? _defaultReadSlideConfigurationBuilder;

  final DeckStore? _documentStore;
  final BuildContextProvider _contextProvider;
  final SlideCaptureFn? _captureSlide;
  final ReadSlideConfigurationBuilder _buildReadSlideConfiguration;

  SlideCaptureService? _captureService;
  Future<void> _mutationQueue = Future.value();

  DeckStore _store() {
    final store = _documentStore;
    if (store == null) {
      throw StateError(
        'DeckToolsService: no DeckStore provided. '
        'Inject an InMemoryDeckStore.',
      );
    }
    return store;
  }

  Future<DeckSnapshotType> getDeck() async {
    final document = await _store().readRequired();
    return mutation.buildDeckSnapshot(document.slides, style: document.style);
  }

  Future<ReadSlideResultType> readSlide(ReadSlideRequestType request) async {
    final document = await _store().readRequired();
    final index = request.index;
    mutation.validateReadIndex(index, document.slides.length);

    final context = _requireMountedContext();
    final slide = document.slides[index];
    final slideConfiguration = (await _buildReadSlideConfiguration(
      slide: slide,
      style: document.style,
      index: index,
    )).copyWith(slideIndex: index);

    if (!context.mounted) {
      throw DeckToolException.contextUnavailable();
    }

    final imageBytes = await _captureSlideBytes(slideConfiguration, context);
    final snapshot = mutation.buildDeckSnapshot(
      document.slides,
      style: document.style,
    );

    return ReadSlideResultType.parse({
      'slide': {
        'index': index,
        'key': slide.key,
        'schema': slide.toMap(),
        'thumbnail': base64Encode(imageBytes),
      },
      'deck': deckSnapshotSchema.encode(snapshot)!,
    });
  }

  Future<SlideMutationResultType> createSlide(
    CreateSlideRequestType request,
  ) async {
    return _runSerializedMutation(() async {
      final document = await _store().readRequired();
      final insertIndex = request.atIndex ?? document.slides.length;
      mutation.validateInsertIndex(insertIndex, document.slides.length);

      final slideMap = _validatedSlideSchemaMap(
        request.schema,
        allowMissingKey: true,
      );
      final existingKey = slideMap['key']?.toString().trim();
      if (existingKey == null || existingKey.isEmpty) {
        slideMap['key'] = _generateUniqueSlideKey(
          slideMap,
          document.slides,
          insertIndex,
        );
      } else {
        if (!isSafeSlideKey(existingKey)) {
          throw DeckToolException.slideKeyInvalid(existingKey);
        }
        slideMap['key'] = existingKey;
      }

      final slide = _parseSlideOrThrow(slideMap);
      mutation.ensureUniqueSlideKeyForCreate(document.slides, slide.key);

      final updatedSlides = mutation.insertSlideAt(
        document.slides,
        slide,
        insertIndex,
      );
      await _store().writeCanonical(
        slides: updatedSlides,
        style: document.style,
      );

      final snapshot = mutation.buildDeckSnapshot(
        updatedSlides,
        style: document.style,
      );
      return SlideMutationResultType.parse({
        'slide': slideSummarySchema.encode(snapshot.slides[insertIndex])!,
        'deck': deckSnapshotSchema.encode(snapshot)!,
      });
    });
  }

  Future<SlideMutationResultType> updateSlide(
    UpdateSlideRequestType request,
  ) async {
    return _runSerializedMutation(() async {
      final document = await _store().readRequired();
      final index = request.index;
      mutation.validateReadIndex(index, document.slides.length);

      final existingSlide = document.slides[index];
      final slideMap = _validatedSlideSchemaMap(
        request.schema,
        allowMissingKey: true,
      );
      slideMap['key'] = existingSlide.key;

      final updatedSlide = _parseSlideOrThrow(slideMap);
      mutation.ensureUniqueSlideKeyForUpdate(
        document.slides,
        index,
        updatedSlide.key,
      );

      final updatedSlides = mutation.replaceSlideAt(
        document.slides,
        index,
        updatedSlide,
      );
      await _store().writeCanonical(
        slides: updatedSlides,
        style: document.style,
      );

      final snapshot = mutation.buildDeckSnapshot(
        updatedSlides,
        style: document.style,
      );
      return SlideMutationResultType.parse({
        'slide': slideSummarySchema.encode(snapshot.slides[index])!,
        'deck': deckSnapshotSchema.encode(snapshot)!,
      });
    });
  }

  Future<DeckSnapshotType> deleteSlide(DeleteSlideRequestType request) async {
    return _runSerializedMutation(() async {
      final document = await _store().readRequired();
      final index = request.index;
      final updatedSlides = mutation.removeSlideAt(document.slides, index);

      await _store().writeCanonical(
        slides: updatedSlides,
        style: document.style,
      );

      return mutation.buildDeckSnapshot(updatedSlides, style: document.style);
    });
  }

  Future<SlideMoveResultType> moveSlide(MoveSlideRequestType request) async {
    return _runSerializedMutation(() async {
      final document = await _store().readRequired();
      final updatedSlides = mutation.moveSlide(
        document.slides,
        request.fromIndex,
        request.toIndex,
      );

      await _store().writeCanonical(
        slides: updatedSlides,
        style: document.style,
      );

      final snapshot = mutation.buildDeckSnapshot(
        updatedSlides,
        style: document.style,
      );
      return SlideMoveResultType.parse({
        'slide': slideSummarySchema.encode(snapshot.slides[request.toIndex])!,
        'deck': deckSnapshotSchema.encode(snapshot)!,
      });
    });
  }

  Future<StyleUpdateResultType> updateStyle(
    UpdateStyleRequestType request,
  ) async {
    return _runSerializedMutation(() async {
      final parsedStyle = _validatedStyleFromRequest(request);
      if (parsedStyle == null) {
        throw DeckToolException.styleInvalid(
          'Expected a valid DeckStyle payload',
        );
      }

      final document = await _store().readRequired();
      await _store().writeCanonical(
        slides: document.slides,
        style: parsedStyle,
      );

      DeckStyleService.setStyle(parsedStyle);

      final snapshot = mutation.buildDeckSnapshot(
        document.slides,
        style: parsedStyle,
      );
      return StyleUpdateResultType.parse({
        'style': serializeDeckStyleForJson(parsedStyle),
        'deck': deckSnapshotSchema.encode(snapshot)!,
      });
    });
  }

  Map<String, dynamic> _validatedSlideSchemaMap(
    Object? rawSchema, {
    bool allowMissingKey = false,
  }) {
    if (rawSchema is! Map) {
      throw DeckToolException.deckSchemaInvalid('Invalid slide schema payload');
    }

    final schemaMap = Map<String, dynamic>.from(rawSchema);
    if (allowMissingKey) {
      final typedSchema = CreateSlideType.safeParse(schemaMap).getOrNull();
      if (typedSchema == null) {
        throw DeckToolException.deckSchemaInvalid(
          'Invalid slide schema payload',
        );
      }

      return Map<String, dynamic>.from(typedSchema);
    }

    final typedSchema = SlideType.safeParse(schemaMap).getOrNull();
    if (typedSchema == null) {
      throw DeckToolException.deckSchemaInvalid('Invalid slide schema payload');
    }

    return Map<String, dynamic>.from(typedSchema);
  }

  DeckStyleType? _validatedStyleFromRequest(UpdateStyleRequestType request) {
    final boundaryStyle = DeckStyleType.safeParse(request.style).getOrNull();
    if (boundaryStyle != null) return boundaryStyle;

    final runtimeStyle = request.style;
    if (styleSchema.safeEncode(runtimeStyle).isOk) {
      return runtimeStyle;
    }

    return null;
  }

  Slide _parseSlideOrThrow(Map<String, dynamic> slideMap) {
    try {
      return Slide.parse(slideMap);
    } catch (error) {
      throw DeckToolException.deckSchemaInvalid('Invalid slide schema: $error');
    }
  }

  String _generateUniqueSlideKey(
    Map<String, dynamic> slideMap,
    List<Slide> existingSlides,
    int insertIndex,
  ) {
    final existingKeys = existingSlides.map((slide) => slide.key).toSet();
    return generateUniqueSlideKey(slideMap, insertIndex, existingKeys);
  }

  Future<T> _runSerializedMutation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _mutationQueue = _mutationQueue
        .catchError((Object ignoredError, StackTrace ignoredStackTrace) {})
        .then((_) async {
          try {
            completer.complete(await operation());
          } catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        });
    return completer.future;
  }

  BuildContext _requireMountedContext() {
    final context = _contextProvider();
    if (context == null || !context.mounted) {
      throw DeckToolException.contextUnavailable();
    }

    return context;
  }

  Future<Uint8List> _captureSlideBytes(
    SlideConfiguration slide,
    BuildContext context,
  ) {
    if (_captureSlide case final capture?) {
      return capture(slide, context);
    }

    _captureService ??= SlideCaptureService();
    return _captureService!.capture(
      quality: SlideCaptureQuality.good,
      slide: slide,
      context: context,
    );
  }

  static BuildContext? _defaultContextProvider() => null;

  static Future<SlideConfiguration> _defaultReadSlideConfigurationBuilder({
    required Slide slide,
    required DeckStyleType? style,
    required int index,
  }) async {
    final options = buildDeckOptionsFromStyle(style);
    final configurations = await buildRuntimeSlideConfigurations(
      slides: [slide],
      options: options,
    );
    return configurations.single.copyWith(slideIndex: index);
  }
}
