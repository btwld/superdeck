// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'outline_schema.dart';

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

/// Immutable model generated from `deckPlanSectionSchema`.
/// A narrative section or act in the deck blueprint
@AckType.jsonSerializable
final class DeckPlanSection {
  DeckPlanSection({
    required this.key,
    required this.title,
    required this.purpose,
    required this.transition,
    required List<String> slideKeys,
  }) : slideKeys = List<String>.unmodifiable(slideKeys.map((item) => item));

  factory DeckPlanSection.parse(Object? input) {
    return $ack.parse(input);
  }

  factory DeckPlanSection.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Unique section or act identifier
  final String key;

  /// Short internal title for this story section
  final String title;

  /// Narrative job performed by this section
  final String purpose;

  /// How this section hands the story to the next section
  final String transition;

  /// Ordered slide keys belonging to this section
  final List<String> slideKeys;

  static final $ack = AckModelAdapter(
    schema: () => deckPlanSectionSchema,
    fromRuntime: DeckPlanSection._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<DeckPlanSection> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  DeckPlanSection copyWith({
    String? key,
    String? title,
    String? purpose,
    String? transition,
    List<String>? slideKeys,
  }) => DeckPlanSection(
    key: key ?? this.key,
    title: title ?? this.title,
    purpose: purpose ?? this.purpose,
    transition: transition ?? this.transition,
    slideKeys: slideKeys ?? this.slideKeys,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckPlanSection &&
          runtimeType == other.runtimeType &&
          deepEquals(key, other.key) &&
          deepEquals(title, other.title) &&
          deepEquals(purpose, other.purpose) &&
          deepEquals(transition, other.transition) &&
          deepEquals(slideKeys, other.slideKeys));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(key),
    deepHashCode(title),
    deepHashCode(purpose),
    deepHashCode(transition),
    deepHashCode(slideKeys),
  ]);

  @override
  String toString() =>
      'DeckPlanSection(key: $key, title: $title, purpose: $purpose, transition: $transition, slideKeys: $slideKeys)';

  static DeckPlanSection _fromAckRuntime(Map<String, Object?> value) =>
      _$DeckPlanSectionFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$DeckPlanSectionToJson(this),
  };

  static String _ackFromRuntimeKey(Object? value) => value as String;

  static Object? _ackToRuntimeKey(String value) => value;

  static String _ackFromRuntimeTitle(Object? value) => value as String;

  static Object? _ackToRuntimeTitle(String value) => value;

  static String _ackFromRuntimePurpose(Object? value) => value as String;

  static Object? _ackToRuntimePurpose(String value) => value;

  static String _ackFromRuntimeTransition(Object? value) => value as String;

  static Object? _ackToRuntimeTransition(String value) => value;

  static List<String> _ackFromRuntimeSlideKeys(Object? value) =>
      (value as List).map((item) => item as String).toList();

  static Object? _ackToRuntimeSlideKeys(List<String> value) =>
      value.map((item) => item).toList(growable: false);
}

/// Immutable model generated from `deckPlanElementSchema`.
/// An element requirement for later slide composition
@AckType.jsonSerializable
final class DeckPlanElement {
  DeckPlanElement({
    required this.type,
    required this.purpose,
    this.source,
    this.generationPrompt,
    this.widgetName,
  });

  factory DeckPlanElement.parse(Object? input) {
    return $ack.parse(input);
  }

  factory DeckPlanElement.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Generation-capable element needed by the slide
  final String type;

  /// Why this element belongs on the slide
  final String purpose;

  /// User-supplied asset path, URL, text, or gist identifier when available
  final String? source;

  /// Concrete visual subject to generate when an image style is configured
  final String? generationPrompt;

  /// Registered widget name when type is custom
  final String? widgetName;

  static final $ack = AckModelAdapter(
    schema: () => deckPlanElementSchema,
    fromRuntime: DeckPlanElement._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<DeckPlanElement> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  DeckPlanElement copyWith({
    String? type,
    String? purpose,
    String? source,
    String? generationPrompt,
    String? widgetName,
  }) => DeckPlanElement(
    type: type ?? this.type,
    purpose: purpose ?? this.purpose,
    source: source ?? this.source,
    generationPrompt: generationPrompt ?? this.generationPrompt,
    widgetName: widgetName ?? this.widgetName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckPlanElement &&
          runtimeType == other.runtimeType &&
          deepEquals(type, other.type) &&
          deepEquals(purpose, other.purpose) &&
          deepEquals(source, other.source) &&
          deepEquals(generationPrompt, other.generationPrompt) &&
          deepEquals(widgetName, other.widgetName));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(type),
    deepHashCode(purpose),
    deepHashCode(source),
    deepHashCode(generationPrompt),
    deepHashCode(widgetName),
  ]);

  @override
  String toString() =>
      'DeckPlanElement(type: $type, purpose: $purpose, source: $source, generationPrompt: $generationPrompt, widgetName: $widgetName)';

  static DeckPlanElement _fromAckRuntime(Map<String, Object?> value) =>
      _$DeckPlanElementFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$DeckPlanElementToJson(this),
  };

  static String _ackFromRuntimeType(Object? value) => value as String;

  static Object? _ackToRuntimeType(String value) => value;

  static String _ackFromRuntimePurpose(Object? value) => value as String;

  static Object? _ackToRuntimePurpose(String value) => value;

  static String? _ackFromRuntimeSource(Object? value) => value as String?;

  static Object? _ackToRuntimeSource(String? value) => value;

  static String? _ackFromRuntimeGenerationPrompt(Object? value) =>
      value as String?;

  static Object? _ackToRuntimeGenerationPrompt(String? value) => value;

  static String? _ackFromRuntimeWidgetName(Object? value) => value as String?;

  static Object? _ackToRuntimeWidgetName(String? value) => value;
}

/// Immutable model generated from `deckPlanSlideSchema`.
/// A single slide in the presentation deck plan
@AckType.jsonSerializable
final class DeckPlanSlide {
  DeckPlanSlide({
    required this.key,
    required this.title,
    required this.purpose,
    required this.sectionKey,
    required this.assertion,
    required List<String> contentUnits,
    required this.narrativeRole,
    required this.contentBrief,
    required this.continuity,
    required this.composition,
    required this.treatment,
    required this.density,
    List<DeckPlanElement>? elements,
  }) : contentUnits = List<String>.unmodifiable(
         contentUnits.map((item) => item),
       ),
       elements = switch (elements) {
         null => null,
         final fieldValue => List<DeckPlanElement>.unmodifiable(
           fieldValue.map((item) => item),
         ),
       };

  factory DeckPlanSlide.parse(Object? input) {
    return $ack.parse(input);
  }

  factory DeckPlanSlide.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Unique identifier for this slide (e.g., "intro", "slide-1", "conclusion")
  final String key;

  /// Working title for this slide (may be refined in final generation)
  final String title;

  /// Brief description of what this slide will communicate (1-2 sentences)
  final String purpose;

  /// Key of the narrative section containing this slide
  final String sectionKey;

  /// The single audience-facing claim this slide must make
  final String assertion;

  /// Concrete evidence, examples, or implications to compose
  final List<String> contentUnits;

  /// The job this slide performs in the presentation story
  final String narrativeRole;

  /// Specific facts, examples, and emphasis the composed slide must include
  final String contentBrief;

  /// How this slide connects the previous and next ideas
  final String continuity;

  /// Semantic composition intent; the slide composer owns exact geometry
  final String composition;

  /// Semantic theme treatment selected for this slide
  final String treatment;

  /// Slide-specific density override within the shared system
  final String density;

  /// Optional non-Markdown elements required by this slide
  final List<DeckPlanElement>? elements;

  static final $ack = AckModelAdapter(
    schema: () => deckPlanSlideSchema,
    fromRuntime: DeckPlanSlide._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<DeckPlanSlide> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  DeckPlanSlide copyWith({
    String? key,
    String? title,
    String? purpose,
    String? sectionKey,
    String? assertion,
    List<String>? contentUnits,
    String? narrativeRole,
    String? contentBrief,
    String? continuity,
    String? composition,
    String? treatment,
    String? density,
    List<DeckPlanElement>? elements,
  }) => DeckPlanSlide(
    key: key ?? this.key,
    title: title ?? this.title,
    purpose: purpose ?? this.purpose,
    sectionKey: sectionKey ?? this.sectionKey,
    assertion: assertion ?? this.assertion,
    contentUnits: contentUnits ?? this.contentUnits,
    narrativeRole: narrativeRole ?? this.narrativeRole,
    contentBrief: contentBrief ?? this.contentBrief,
    continuity: continuity ?? this.continuity,
    composition: composition ?? this.composition,
    treatment: treatment ?? this.treatment,
    density: density ?? this.density,
    elements: elements ?? this.elements,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckPlanSlide &&
          runtimeType == other.runtimeType &&
          deepEquals(key, other.key) &&
          deepEquals(title, other.title) &&
          deepEquals(purpose, other.purpose) &&
          deepEquals(sectionKey, other.sectionKey) &&
          deepEquals(assertion, other.assertion) &&
          deepEquals(contentUnits, other.contentUnits) &&
          deepEquals(narrativeRole, other.narrativeRole) &&
          deepEquals(contentBrief, other.contentBrief) &&
          deepEquals(continuity, other.continuity) &&
          deepEquals(composition, other.composition) &&
          deepEquals(treatment, other.treatment) &&
          deepEquals(density, other.density) &&
          deepEquals(elements, other.elements));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(key),
    deepHashCode(title),
    deepHashCode(purpose),
    deepHashCode(sectionKey),
    deepHashCode(assertion),
    deepHashCode(contentUnits),
    deepHashCode(narrativeRole),
    deepHashCode(contentBrief),
    deepHashCode(continuity),
    deepHashCode(composition),
    deepHashCode(treatment),
    deepHashCode(density),
    deepHashCode(elements),
  ]);

  @override
  String toString() =>
      'DeckPlanSlide(key: $key, title: $title, purpose: $purpose, sectionKey: $sectionKey, assertion: $assertion, contentUnits: $contentUnits, narrativeRole: $narrativeRole, contentBrief: $contentBrief, continuity: $continuity, composition: $composition, treatment: $treatment, density: $density, elements: $elements)';

  static DeckPlanSlide _fromAckRuntime(Map<String, Object?> value) =>
      _$DeckPlanSlideFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$DeckPlanSlideToJson(this),
  };

  static String _ackFromRuntimeKey(Object? value) => value as String;

  static Object? _ackToRuntimeKey(String value) => value;

  static String _ackFromRuntimeTitle(Object? value) => value as String;

  static Object? _ackToRuntimeTitle(String value) => value;

  static String _ackFromRuntimePurpose(Object? value) => value as String;

  static Object? _ackToRuntimePurpose(String value) => value;

  static String _ackFromRuntimeSectionKey(Object? value) => value as String;

  static Object? _ackToRuntimeSectionKey(String value) => value;

  static String _ackFromRuntimeAssertion(Object? value) => value as String;

  static Object? _ackToRuntimeAssertion(String value) => value;

  static List<String> _ackFromRuntimeContentUnits(Object? value) =>
      (value as List).map((item) => item as String).toList();

  static Object? _ackToRuntimeContentUnits(List<String> value) =>
      value.map((item) => item).toList(growable: false);

  static String _ackFromRuntimeNarrativeRole(Object? value) => value as String;

  static Object? _ackToRuntimeNarrativeRole(String value) => value;

  static String _ackFromRuntimeContentBrief(Object? value) => value as String;

  static Object? _ackToRuntimeContentBrief(String value) => value;

  static String _ackFromRuntimeContinuity(Object? value) => value as String;

  static Object? _ackToRuntimeContinuity(String value) => value;

  static String _ackFromRuntimeComposition(Object? value) => value as String;

  static Object? _ackToRuntimeComposition(String value) => value;

  static String _ackFromRuntimeTreatment(Object? value) => value as String;

  static Object? _ackToRuntimeTreatment(String value) => value;

  static String _ackFromRuntimeDensity(Object? value) => value as String;

  static Object? _ackToRuntimeDensity(String value) => value;

  static List<DeckPlanElement>? _ackFromRuntimeElements(Object? value) =>
      switch (value) {
        null => null,
        final fieldValue =>
          (fieldValue as List)
              .map(
                (item) => DeckPlanElement.$ack.fromRuntime(
                  item as Map<String, Object?>,
                ),
              )
              .toList(),
      };

  static Object? _ackToRuntimeElements(List<DeckPlanElement>? value) =>
      switch (value) {
        null => null,
        final fieldValue =>
          fieldValue
              .map((item) => DeckPlanElement.$ack.toRuntime(item))
              .toList(growable: false),
      };
}

/// Immutable model generated from `deckPlanSchema`.
/// Presentation deck plan with narrative, theme, and composition intent
@AckType.jsonSerializable
final class DeckPlan {
  DeckPlan({
    required this.topic,
    required this.story,
    required this.theme,
    required List<DeckPlanSection> sections,
    required List<DeckPlanSlide> slides,
  }) : sections = List<DeckPlanSection>.unmodifiable(
         sections.map((item) => item),
       ),
       slides = List<DeckPlanSlide>.unmodifiable(slides.map((item) => item));

  factory DeckPlan.parse(Object? input) {
    return $ack.parse(input);
  }

  factory DeckPlan.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Main topic of the presentation
  final String topic;

  /// One-sentence narrative through-line for the complete presentation
  final String story;

  /// Application-resolved theme reference for the complete deck
  final DeckThemeReference theme;

  /// Ordered narrative sections whose slide keys partition the deck
  final List<DeckPlanSection> sections;

  /// Ordered list of slides in the presentation
  final List<DeckPlanSlide> slides;

  static final $ack = AckModelAdapter(
    schema: () => deckPlanSchema,
    fromRuntime: DeckPlan._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<DeckPlan> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  DeckPlan copyWith({
    String? topic,
    String? story,
    DeckThemeReference? theme,
    List<DeckPlanSection>? sections,
    List<DeckPlanSlide>? slides,
  }) => DeckPlan(
    topic: topic ?? this.topic,
    story: story ?? this.story,
    theme: theme ?? this.theme,
    sections: sections ?? this.sections,
    slides: slides ?? this.slides,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckPlan &&
          runtimeType == other.runtimeType &&
          deepEquals(topic, other.topic) &&
          deepEquals(story, other.story) &&
          deepEquals(theme, other.theme) &&
          deepEquals(sections, other.sections) &&
          deepEquals(slides, other.slides));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(topic),
    deepHashCode(story),
    deepHashCode(theme),
    deepHashCode(sections),
    deepHashCode(slides),
  ]);

  @override
  String toString() =>
      'DeckPlan(topic: $topic, story: $story, theme: $theme, sections: $sections, slides: $slides)';

  static DeckPlan _fromAckRuntime(Map<String, Object?> value) =>
      _$DeckPlanFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$DeckPlanToJson(this),
  };

  static String _ackFromRuntimeTopic(Object? value) => value as String;

  static Object? _ackToRuntimeTopic(String value) => value;

  static String _ackFromRuntimeStory(Object? value) => value as String;

  static Object? _ackToRuntimeStory(String value) => value;

  static DeckThemeReference _ackFromRuntimeTheme(Object? value) =>
      DeckThemeReference.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimeTheme(DeckThemeReference value) =>
      DeckThemeReference.$ack.toRuntime(value);

  static List<DeckPlanSection> _ackFromRuntimeSections(Object? value) =>
      (value as List)
          .map(
            (item) =>
                DeckPlanSection.$ack.fromRuntime(item as Map<String, Object?>),
          )
          .toList();

  static Object? _ackToRuntimeSections(List<DeckPlanSection> value) => value
      .map((item) => DeckPlanSection.$ack.toRuntime(item))
      .toList(growable: false);

  static List<DeckPlanSlide> _ackFromRuntimeSlides(Object? value) =>
      (value as List)
          .map(
            (item) =>
                DeckPlanSlide.$ack.fromRuntime(item as Map<String, Object?>),
          )
          .toList();

  static Object? _ackToRuntimeSlides(List<DeckPlanSlide> value) => value
      .map((item) => DeckPlanSlide.$ack.toRuntime(item))
      .toList(growable: false);
}
