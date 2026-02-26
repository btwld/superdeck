import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';
// ignore: implementation_imports
import 'package:superdeck/src/deck/slide_configuration_builder.dart';
// ignore: implementation_imports
import 'package:superdeck/src/export/slide_capture_service.dart';
import '../ai/schemas/deck_schemas.dart';
import '../ai/services/slide_key_utils.dart';
import './deck_document_store.dart';
import './deck_mutation_helpers.dart' as mutation;
import './deck_tools_schemas.dart';
import './errors.dart';
import '../utils/deck_style_service.dart';
import '../utils/style_builder.dart';
import '../presentation/thumbnail_preview_service.dart';

typedef BuildContextProvider = BuildContext? Function();

/// Builds the slide configuration used by `readSlide`.
///
/// The default implementation uses `SlideConfigurationBuilder`. Tests can
/// inject a lightweight builder to avoid font/asset side effects.
typedef ReadSlideConfigurationBuilder =
    SlideConfiguration Function({
      required Slide slide,
      required DeckConfiguration configuration,
      required DeckStyleType? style,
      required int index,
    });

/// In-app deck tooling service for slide CRUD and style updates.
class DeckToolsService {
  DeckToolsService({
    DeckDocumentStore? documentStore,
    BuildContextProvider? contextProvider,
    SlideCaptureFn? captureSlide,
    ReadSlideConfigurationBuilder? buildReadSlideConfiguration,
  }) : _documentStore = documentStore ?? DeckDocumentStore(),
       _contextProvider = contextProvider ?? _defaultContextProvider,
       _captureSlide = captureSlide,
       _buildReadSlideConfiguration =
           buildReadSlideConfiguration ?? _defaultReadSlideConfigurationBuilder;

  final DeckDocumentStore _documentStore;
  final BuildContextProvider _contextProvider;
  final SlideCaptureFn? _captureSlide;
  final ReadSlideConfigurationBuilder _buildReadSlideConfiguration;

  SlideCaptureService? _captureService;
  Future<void> _mutationQueue = Future.value();

  Future<DeckSnapshotType> getDeck() async {
    final document = await _documentStore.readRequired();
    return mutation.buildDeckSnapshot(document.slides, style: document.style);
  }

  Future<ReadSlideResultType> readSlide(ReadSlideRequestType request) async {
    final document = await _documentStore.readRequired();
    final index = request.index;
    mutation.validateReadIndex(index, document.slides.length);

    final context = _requireMountedContext();
    final slide = document.slides[index];
    final slideConfiguration = _buildReadSlideConfiguration(
      slide: slide,
      configuration: _documentStore.configuration,
      style: document.style,
      index: index,
    ).copyWith(slideIndex: index);

    // ignore: use_build_context_synchronously
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
      'deck': snapshot.toJson(),
    });
  }

  Future<SlideMutationResultType> createSlide(
    CreateSlideRequestType request,
  ) async {
    return _runSerializedMutation(() async {
      final document = await _documentStore.readRequired();
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
        slideMap['key'] = existingKey;
      }

      final slide = _parseSlideOrThrow(slideMap);
      mutation.ensureUniqueSlideKeyForCreate(document.slides, slide.key);

      final updatedSlides = mutation.insertSlideAt(
        document.slides,
        slide,
        insertIndex,
      );
      await _documentStore.writeCanonical(
        slides: updatedSlides,
        style: document.style,
      );

      final snapshot = mutation.buildDeckSnapshot(
        updatedSlides,
        style: document.style,
      );
      return SlideMutationResultType.parse({
        'slide': snapshot.slides[insertIndex].toJson(),
        'deck': snapshot.toJson(),
      });
    });
  }

  Future<SlideMutationResultType> updateSlide(
    UpdateSlideRequestType request,
  ) async {
    return _runSerializedMutation(() async {
      final document = await _documentStore.readRequired();
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
      await _documentStore.writeCanonical(
        slides: updatedSlides,
        style: document.style,
      );

      final snapshot = mutation.buildDeckSnapshot(
        updatedSlides,
        style: document.style,
      );
      return SlideMutationResultType.parse({
        'slide': snapshot.slides[index].toJson(),
        'deck': snapshot.toJson(),
      });
    });
  }

  Future<DeckSnapshotType> deleteSlide(DeleteSlideRequestType request) async {
    return _runSerializedMutation(() async {
      final document = await _documentStore.readRequired();
      final index = request.index;
      final updatedSlides = mutation.removeSlideAt(document.slides, index);

      await _documentStore.writeCanonical(
        slides: updatedSlides,
        style: document.style,
      );

      return mutation.buildDeckSnapshot(updatedSlides, style: document.style);
    });
  }

  Future<SlideMoveResultType> moveSlide(MoveSlideRequestType request) async {
    return _runSerializedMutation(() async {
      final document = await _documentStore.readRequired();
      final updatedSlides = mutation.moveSlide(
        document.slides,
        request.fromIndex,
        request.toIndex,
      );

      await _documentStore.writeCanonical(
        slides: updatedSlides,
        style: document.style,
      );

      final snapshot = mutation.buildDeckSnapshot(
        updatedSlides,
        style: document.style,
      );
      return SlideMoveResultType.parse({
        'slide': snapshot.slides[request.toIndex].toJson(),
        'deck': snapshot.toJson(),
      });
    });
  }

  Future<StyleUpdateResultType> updateStyle(
    UpdateStyleRequestType request,
  ) async {
    return _runSerializedMutation(() async {
      final parsedStyle = DeckStyleType.safeParse(request.style).getOrNull();
      if (parsedStyle == null) {
        throw DeckToolException.styleInvalid(
          'Expected a valid DeckStyle payload',
        );
      }

      final document = await _documentStore.readRequired();
      await _documentStore.writeCanonical(
        slides: document.slides,
        style: parsedStyle,
      );

      DeckStyleService.setStyle(parsedStyle);

      final snapshot = mutation.buildDeckSnapshot(
        document.slides,
        style: parsedStyle,
      );
      return StyleUpdateResultType.parse({
        'style': parsedStyle.toJson(),
        'deck': snapshot.toJson(),
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
    const maxAttempts = 1024;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = generateSlideKey(slideMap, insertIndex + attempt);
      if (!existingKeys.contains(candidate)) {
        return candidate;
      }
    }
    throw DeckToolException.slideKeyConflict(
      'Could not generate unique key after $maxAttempts attempts',
    );
  }

  Future<T> _runSerializedMutation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _mutationQueue = _mutationQueue
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('DeckToolsService: previous mutation failed: $error');
        })
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

  static SlideConfiguration _defaultReadSlideConfigurationBuilder({
    required Slide slide,
    required DeckConfiguration configuration,
    required DeckStyleType? style,
    required int index,
  }) {
    final slideBuilder = SlideConfigurationBuilder(
      configuration: configuration,
    );
    final options = buildDeckOptionsFromStyle(style);
    return slideBuilder
        .buildConfigurations([slide], options)
        .single
        .copyWith(slideIndex: index);
  }
}
