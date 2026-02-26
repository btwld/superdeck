import 'package:superdeck_ai/core/ai/schemas/wizard_context_keys.dart';

/// Typed representation of wizard context data used for generation.
///
/// Keeps dynamic maps at the AI boundary while providing type safety
/// in domain/business logic.
class WizardContext {
  final String? topic;
  final String? audience;
  final String? approach;
  final List<String>? emphasis;
  final int? slideCount;
  final String? style;
  final List<String>? colors;
  final String? headlineFont;
  final String? bodyFont;
  final String? imageStyleId;
  final String? imageStyleName;
  final String? imageStyleDescription;

  const WizardContext({
    this.topic,
    this.audience,
    this.approach,
    this.emphasis,
    this.slideCount,
    this.style,
    this.colors,
    this.headlineFont,
    this.bodyFont,
    this.imageStyleId,
    this.imageStyleName,
    this.imageStyleDescription,
  });

  WizardContext copyWith({
    String? topic,
    String? audience,
    String? approach,
    List<String>? emphasis,
    int? slideCount,
    String? style,
    List<String>? colors,
    String? headlineFont,
    String? bodyFont,
    String? imageStyleId,
    String? imageStyleName,
    String? imageStyleDescription,
  }) {
    return WizardContext(
      topic: topic ?? this.topic,
      audience: audience ?? this.audience,
      approach: approach ?? this.approach,
      emphasis: emphasis ?? this.emphasis,
      slideCount: slideCount ?? this.slideCount,
      style: style ?? this.style,
      colors: colors ?? this.colors,
      headlineFont: headlineFont ?? this.headlineFont,
      bodyFont: bodyFont ?? this.bodyFont,
      imageStyleId: imageStyleId ?? this.imageStyleId,
      imageStyleName: imageStyleName ?? this.imageStyleName,
      imageStyleDescription:
          imageStyleDescription ?? this.imageStyleDescription,
    );
  }

  /// Merge [other] into this context, preferring non-null values from [other].
  WizardContext merge(WizardContext other) {
    return WizardContext(
      topic: other.topic ?? topic,
      audience: other.audience ?? audience,
      approach: other.approach ?? approach,
      emphasis: other.emphasis ?? emphasis,
      slideCount: other.slideCount ?? slideCount,
      style: other.style ?? style,
      colors: other.colors ?? colors,
      headlineFont: other.headlineFont ?? headlineFont,
      bodyFont: other.bodyFont ?? bodyFont,
      imageStyleId: other.imageStyleId ?? imageStyleId,
      imageStyleName: other.imageStyleName ?? imageStyleName,
      imageStyleDescription:
          other.imageStyleDescription ?? imageStyleDescription,
    );
  }

  /// Convert to a map using [WizardContextKeys].
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    void setIfNonNull(String key, Object? value) {
      if (value != null) map[key] = value;
    }

    setIfNonNull(WizardContextKeys.topic, topic);
    setIfNonNull(WizardContextKeys.audience, audience);
    setIfNonNull(WizardContextKeys.approach, approach);
    setIfNonNull(WizardContextKeys.emphasis, emphasis);
    setIfNonNull(WizardContextKeys.slideCount, slideCount);
    setIfNonNull(WizardContextKeys.style, style);
    setIfNonNull(WizardContextKeys.colors, colors);
    setIfNonNull(WizardContextKeys.headlineFont, headlineFont);
    setIfNonNull(WizardContextKeys.bodyFont, bodyFont);
    setIfNonNull(WizardContextKeys.imageStyleId, imageStyleId);
    setIfNonNull(WizardContextKeys.imageStyleName, imageStyleName);
    setIfNonNull(
      WizardContextKeys.imageStyleDescription,
      imageStyleDescription,
    );

    return map;
  }

  /// Parse a [WizardContext] from a loose map.
  factory WizardContext.fromMap(Map<String, dynamic> map) {
    return WizardContext(
      topic: _stringOrNull(map[WizardContextKeys.topic]),
      audience: _stringOrNull(map[WizardContextKeys.audience]),
      approach: _stringOrNull(map[WizardContextKeys.approach]),
      emphasis: _stringListOrNull(map[WizardContextKeys.emphasis]),
      slideCount: _intOrNull(map[WizardContextKeys.slideCount]),
      style: _stringOrNull(map[WizardContextKeys.style]),
      colors: _stringListOrNull(map[WizardContextKeys.colors]),
      headlineFont: _stringOrNull(map[WizardContextKeys.headlineFont]),
      bodyFont: _stringOrNull(map[WizardContextKeys.bodyFont]),
      imageStyleId: _stringOrNull(map[WizardContextKeys.imageStyleId]),
      imageStyleName: _stringOrNull(map[WizardContextKeys.imageStyleName]),
      imageStyleDescription: _stringOrNull(
        map[WizardContextKeys.imageStyleDescription],
      ),
    );
  }
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<String>? _stringListOrNull(Object? value) {
  if (value == null) return null;
  if (value is List) {
    final items = value
        .map((item) => _stringOrNull(item))
        .whereType<String>()
        .toList();
    return items.isEmpty ? null : items;
  }
  final text = _stringOrNull(value);
  if (text == null) return null;
  return [text];
}

int? _intOrNull(Object? value) {
  if (value is int) return value > 0 ? value : null;
  if (value is num) {
    final i = value.toInt();
    return i > 0 ? i : null;
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null && parsed > 0) return parsed;
  }
  return null;
}
