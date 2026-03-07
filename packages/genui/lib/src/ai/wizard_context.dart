import 'package:dart_mappable/dart_mappable.dart';

import './schemas/wizard_context_keys.dart';

part 'wizard_context.mapper.dart';

/// Typed representation of wizard context data used for generation.
///
/// Keeps dynamic maps at the AI boundary while providing type safety
/// in domain/business logic.
@MappableClass(ignoreNull: true)
class WizardContext with WizardContextMappable {
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
  @override
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
    return WizardContextMapper.fromMap({
      WizardContextKeys.topic: _stringOrNull(map[WizardContextKeys.topic]),
      WizardContextKeys.audience: _stringOrNull(
        map[WizardContextKeys.audience],
      ),
      WizardContextKeys.approach: _stringOrNull(
        map[WizardContextKeys.approach],
      ),
      WizardContextKeys.emphasis: _stringListOrNull(
        map[WizardContextKeys.emphasis],
      ),
      WizardContextKeys.slideCount: _intOrNull(
        map[WizardContextKeys.slideCount],
      ),
      WizardContextKeys.style: _stringOrNull(map[WizardContextKeys.style]),
      WizardContextKeys.colors: _stringListOrNull(
        map[WizardContextKeys.colors],
      ),
      WizardContextKeys.headlineFont: _stringOrNull(
        map[WizardContextKeys.headlineFont],
      ),
      WizardContextKeys.bodyFont: _stringOrNull(
        map[WizardContextKeys.bodyFont],
      ),
      WizardContextKeys.imageStyleId: _stringOrNull(
        map[WizardContextKeys.imageStyleId],
      ),
      WizardContextKeys.imageStyleName: _stringOrNull(
        map[WizardContextKeys.imageStyleName],
      ),
      WizardContextKeys.imageStyleDescription: _stringOrNull(
        map[WizardContextKeys.imageStyleDescription],
      ),
    });
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
