import 'dart:convert';

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
  const DeckGenerationRequest({
    required this.userIntent,
    required this.slideCount,
    this.audience,
    this.approach,
    this.emphasis = const [],
    this.designDirection,
    this.colors = const [],
    this.headlineFont,
    this.bodyFont,
    this.imageStyleName,
    this.imageStyleDescription,
    this.groundedElements = const [],
  }) : assert(slideCount > 0 && slideCount <= 50);

  factory DeckGenerationRequest.fromMap(Map<String, Object?> map) =>
      DeckGenerationRequest(
        userIntent: map['userIntent']! as String,
        slideCount: map['slideCount']! as int,
        audience: map['audience'] as String?,
        approach: map['approach'] as String?,
        emphasis: _stringList(map['emphasis']),
        designDirection: map['designDirection'] as String?,
        colors: _stringList(map['colors']),
        headlineFont: map['headlineFont'] as String?,
        bodyFont: map['bodyFont'] as String?,
        imageStyleName: map['imageStyleName'] as String?,
        imageStyleDescription: map['imageStyleDescription'] as String?,
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

  final String userIntent;
  final int slideCount;
  final String? audience;
  final String? approach;
  final List<String> emphasis;
  final String? designDirection;
  final List<String> colors;
  final String? headlineFont;
  final String? bodyFont;
  final String? imageStyleName;
  final String? imageStyleDescription;
  final List<GroundedGenerationElement> groundedElements;

  Map<String, Object?> toMap() => {
    'userIntent': userIntent,
    'slideCount': slideCount,
    if (extractGroundedNumericFactSnippets(userIntent) case final facts
        when facts.isNotEmpty)
      'groundedNumericFacts': facts,
    'audience': ?audience,
    'approach': ?approach,
    if (emphasis.isNotEmpty) 'emphasis': emphasis,
    'designDirection': ?designDirection,
    if (colors.isNotEmpty) 'colors': colors,
    'headlineFont': ?headlineFont,
    'bodyFont': ?bodyFont,
    'imageStyleName': ?imageStyleName,
    'imageStyleDescription': ?imageStyleDescription,
    if (groundedElements.isNotEmpty)
      'groundedElements': groundedElements
          .map((element) => element.toMap())
          .toList(),
  };

  /// JSON data supplied as the model's user content.
  String toModelInput() => const JsonEncoder.withIndent('  ').convert(toMap());
}

List<String> _stringList(Object? value) => switch (value) {
  final List values => values.cast<String>(),
  _ => const [],
};
