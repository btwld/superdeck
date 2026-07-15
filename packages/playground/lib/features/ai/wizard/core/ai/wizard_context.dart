import 'schemas/wizard_context_keys.dart';

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
  final String? themeId;
  final String? style;
  final String? density;
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
    this.themeId,
    this.style,
    this.density,
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
    String? themeId,
    String? style,
    String? density,
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
      themeId: themeId ?? this.themeId,
      style: style ?? this.style,
      density: density ?? this.density,
      colors: colors ?? this.colors,
      headlineFont: headlineFont ?? this.headlineFont,
      bodyFont: bodyFont ?? this.bodyFont,
      imageStyleId: imageStyleId ?? this.imageStyleId,
      imageStyleName: imageStyleName ?? this.imageStyleName,
      imageStyleDescription:
          imageStyleDescription ?? this.imageStyleDescription,
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
    setIfNonNull(WizardContextKeys.themeId, themeId);
    setIfNonNull(WizardContextKeys.style, style);
    setIfNonNull(WizardContextKeys.density, density);
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
}
