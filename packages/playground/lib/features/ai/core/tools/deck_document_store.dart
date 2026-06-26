import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/ai/services/style_json_serializer.dart';
import 'package:playground/features/ai/core/constants/paths.dart';
import 'package:playground/features/ai/core/superdeck_workspace.dart';
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/errors.dart';

/// Disk-backed [DeckStore].
///
/// Reads/writes the deck from the filesystem via [DeckWorkspace].
/// Not suitable for web — use [InMemoryDeckStore] instead.
class DeckDocumentStore implements DeckStore {
  DeckDocumentStore({DeckWorkspace? workspace})
    : workspace = workspace ?? runtimeDeckWorkspace();

  final DeckWorkspace workspace;

  File get _metadataFile =>
      File(p.join(workspace.superdeckDir.path, Paths.aiMetadataFile));

  @override
  Future<DeckDocument> readRequired() async {
    final file = workspace.deckJson;
    if (!await file.exists()) {
      throw DeckToolException.deckFileNotFound(file.path);
    }

    final content = await file.readAsString();

    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (error) {
      throw DeckToolException.deckJsonInvalid(error.message);
    }

    if (decoded is List) {
      return DeckDocument(
        slides: _parseSlides(decoded),
        style: await _readMetadataStyle(),
      );
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final rawSlides = map['slides'];
      if (rawSlides is! List) {
        throw DeckToolException.deckSchemaInvalid(
          'Expected "slides" as a JSON array',
        );
      }

      return DeckDocument(
        slides: _parseSlides(rawSlides),
        style: await _readMetadataStyle() ?? _parseLegacyStyle(map['style']),
      );
    }

    throw DeckToolException.deckSchemaInvalid(
      'Root must be a JSON array or object',
    );
  }

  @override
  Future<void> writeCanonical({
    required List<Slide> slides,
    DeckStyleType? style,
  }) async {
    final file = workspace.deckJson;
    final payload = slides
        .map((slide) => slide.toMap())
        .toList(growable: false);

    final encoded = const JsonEncoder.withIndent('  ').convert(payload);

    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(encoded);
      await _writeMetadata(style);
      await _writeBuildStatus(slideCount: slides.length);
    } on FileSystemException catch (error) {
      throw DeckToolException.deckWriteFailed(
        path: file.path,
        details: error.message,
      );
    }
  }

  List<Slide> _parseSlides(List<Object?> rawSlides) {
    final slides = <Slide>[];
    for (var index = 0; index < rawSlides.length; index++) {
      final rawSlide = rawSlides[index];
      if (rawSlide is! Map) {
        throw DeckToolException.deckSchemaInvalid(
          'Slide at index $index must be a JSON object',
        );
      }

      try {
        final slideMap = Map<String, Object?>.from(rawSlide);
        slides.add(Slide.parse(slideMap));
      } catch (error) {
        throw DeckToolException.deckSchemaInvalid(
          'Invalid slide at index $index: $error',
        );
      }
    }
    return slides;
  }

  DeckStyleType? _parseLegacyStyle(Object? rawStyle) {
    if (rawStyle == null) return null;

    final style = DeckStyleType.safeParse(rawStyle).getOrNull();
    if (style == null) {
      throw DeckToolException.deckSchemaInvalid('Invalid "style" object');
    }
    return style;
  }

  Future<DeckStyleType?> _readMetadataStyle() async {
    if (!await _metadataFile.exists()) return null;

    dynamic decoded;
    try {
      decoded = jsonDecode(await _metadataFile.readAsString());
    } on FormatException catch (error) {
      throw DeckToolException.deckJsonInvalid(error.message);
    }

    if (decoded is! Map) {
      throw DeckToolException.deckSchemaInvalid(
        'AI metadata root must be a JSON object',
      );
    }

    final style = DeckStyleType.safeParse(decoded['style']).getOrNull();
    if (decoded['style'] != null && style == null) {
      throw DeckToolException.deckSchemaInvalid(
        'Invalid AI metadata "style" object',
      );
    }
    return style;
  }

  Future<void> _writeMetadata(DeckStyleType? style) async {
    if (style == null) {
      if (await _metadataFile.exists()) {
        await _metadataFile.delete();
      }
      return;
    }

    final payload = {'style': serializeDeckStyleForJson(style)};
    final encoded = const JsonEncoder.withIndent('  ').convert(payload);
    await _metadataFile.parent.create(recursive: true);
    await _metadataFile.writeAsString(encoded);
  }

  Future<void> _writeBuildStatus({required int slideCount}) async {
    final status = DeckBuildStatus(
      phase: DeckBuildPhase.success,
      timestamp: DateTime.now(),
      slideCount: slideCount,
    );
    final encoded = const JsonEncoder.withIndent('  ').convert(status.toMap());
    await workspace.buildStatusJson.writeAsString(encoded);
  }
}
