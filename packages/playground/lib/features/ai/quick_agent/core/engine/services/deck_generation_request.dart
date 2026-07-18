import 'dart:convert';

import '../../../../../../core/domain/design/presentation_image_style_catalog.dart';
import 'source_grounding.dart';

/// A user-supplied element whose source is safe for generation to reference.
final class GroundedGenerationElement {
  const GroundedGenerationElement({
    required this.type,
    required this.source,
    required this.purpose,
    this.widgetName,
  });

  factory GroundedGenerationElement.fromMap(Map<String, Object?> map) =>
      GroundedGenerationElement(
        type: map['type']! as String,
        source: map['source']! as String,
        purpose: map['purpose']! as String,
        widgetName: map['widgetName'] as String?,
      );

  final String type;
  final String source;
  final String purpose;
  final String? widgetName;

  Map<String, Object?> toMap() => {
    'type': type,
    'source': source,
    'purpose': purpose,
    'widgetName': ?widgetName,
  };
}

/// Typed user intent passed through every phase of deck generation.
///
/// The exact slide count and explicit design choices stay separate from prose,
/// so the pipeline can validate them instead of asking the model to infer them.
final class DeckGenerationRequest {
  final String userIntent;
  final int slideCount;
  final String? audience;
  final String? approach;
  final List<String> emphasis;
  final String? themeId;
  final String? designDirection;
  final String? density;
  final List<String> colors;
  final String? headlineFont;
  final String? bodyFont;
  final String? imageStyleId;
  final int? imageStyleVersion;
  final int maxGeneratedImages;
  final List<GroundedGenerationElement> groundedElements;

  const DeckGenerationRequest({
    required this.userIntent,
    required this.slideCount,
    this.audience,
    this.approach,
    this.emphasis = const [],
    this.themeId,
    this.designDirection,
    this.density,
    this.colors = const [],
    this.headlineFont,
    this.bodyFont,
    this.imageStyleId,
    this.imageStyleVersion,
    this.maxGeneratedImages = 4,
    this.groundedElements = const [],
  }) : assert(slideCount > 0 && slideCount <= 50),
       assert(maxGeneratedImages >= 0 && maxGeneratedImages <= 4),
       assert(
         (imageStyleId == null) == (imageStyleVersion == null),
         'Image style ID and version must be supplied together.',
       );

  factory DeckGenerationRequest.fromMap(Map<String, Object?> map) =>
      DeckGenerationRequest(
        userIntent: map['userIntent']! as String,
        slideCount: map['slideCount']! as int,
        audience: map['audience'] as String?,
        approach: map['approach'] as String?,
        emphasis: _stringList(map['emphasis']),
        themeId: map['themeId'] as String?,
        designDirection: map['designDirection'] as String?,
        density: map['density'] as String?,
        colors: _stringList(map['colors']),
        headlineFont: map['headlineFont'] as String?,
        bodyFont: map['bodyFont'] as String?,
        imageStyleId: map['imageStyleId'] as String?,
        imageStyleVersion: map['imageStyleVersion'] as int?,
        maxGeneratedImages: map['maxGeneratedImages'] as int? ?? 4,
        groundedElements: switch (map['groundedElements']) {
          final List values => [
            for (final value in values)
              GroundedGenerationElement.fromMap(
                Map<String, Object?>.from(value as Map),
              ),
          ],
          _ => const [],
        },
      );

  Map<String, Object?> toMap() => {
    'userIntent': userIntent,
    'slideCount': slideCount,
    if (extractGroundedNumericFactSnippets(userIntent) case final facts
        when facts.isNotEmpty)
      'groundedNumericFacts': facts,
    'audience': ?audience,
    'approach': ?approach,
    if (emphasis.isNotEmpty) 'emphasis': emphasis,
    'themeId': ?themeId,
    'designDirection': ?designDirection,
    'density': ?density,
    if (colors.isNotEmpty) 'colors': colors,
    'headlineFont': ?headlineFont,
    'bodyFont': ?bodyFont,
    'imageStyleId': ?imageStyleId,
    'imageStyleVersion': ?imageStyleVersion,
    if (imageStyleId != null) 'maxGeneratedImages': maxGeneratedImages,
    if (groundedElements.isNotEmpty)
      'groundedElements': groundedElements
          .map((element) => element.toMap())
          .toList(),
  };

  /// JSON data supplied as the model's user content.
  String toModelInput() => const JsonEncoder.withIndent('  ').convert(toMap());

  /// Resolves the selected exact version before any provider call.
  PresentationImageStyleDescriptor? resolveImageStyle(
    PresentationImageStyleCatalog catalog,
  ) {
    final id = imageStyleId;
    final version = imageStyleVersion;
    if (id == null && version == null) return null;
    if (id == null || version == null) {
      throw ArgumentError(
        'Image style ID and version must be supplied together.',
      );
    }

    return catalog.resolve(id: id, version: version);
  }
}

List<String> _stringList(Object? value) => switch (value) {
  final List values => values.cast<String>(),
  _ => const [],
};
