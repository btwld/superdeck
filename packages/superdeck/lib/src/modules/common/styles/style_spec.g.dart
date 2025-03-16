// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_spec.dart';

// **************************************************************************
// MixableSpecGenerator
// **************************************************************************

/// A mixin that provides spec functionality for [MarkdownTextSpec].
mixin _$MarkdownTextSpec on Spec<MarkdownTextSpec> {
  static MarkdownTextSpec from(MixData mix) {
    return mix.attributeOf<MarkdownTextSpecAttribute>()?.resolve(mix) ??
        const MarkdownTextSpec();
  }

  /// {@template markdown_text_spec_of}
  /// Retrieves the [MarkdownTextSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [MarkdownTextSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [MarkdownTextSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final markdownTextSpec = MarkdownTextSpec.of(context);
  /// ```
  /// {@endtemplate}
  static MarkdownTextSpec of(BuildContext context) {
    return _$MarkdownTextSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [MarkdownTextSpec] but with the given fields
  /// replaced with the new values.
  @override
  MarkdownTextSpec copyWith({
    TextStyle? textStyle,
    EdgeInsets? padding,
    WrapAlignment? alignment,
  }) {
    return MarkdownTextSpec(
      textStyle: textStyle ?? _$this.textStyle,
      padding: padding ?? _$this.padding,
      alignment: alignment ?? _$this.alignment,
    );
  }

  /// Linearly interpolates between this [MarkdownTextSpec] and another [MarkdownTextSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [MarkdownTextSpec] is returned. When [t] is 1.0, the [other] [MarkdownTextSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [MarkdownTextSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [MarkdownTextSpec] instance.
  ///
  /// The interpolation is performed on each property of the [MarkdownTextSpec] using the appropriate
  /// interpolation method:
  /// - [MixHelpers.lerpTextStyle] for [textStyle].
  /// - [EdgeInsets.lerp] for [padding].
  /// For [alignment], the interpolation is performed using a step function.
  /// If [t] is less than 0.5, the value from the current [MarkdownTextSpec] is used. Otherwise, the value
  /// from the [other] [MarkdownTextSpec] is used.
  ///
  /// This method is typically used in animations to smoothly transition between
  /// different [MarkdownTextSpec] configurations.
  @override
  MarkdownTextSpec lerp(MarkdownTextSpec? other, double t) {
    if (other == null) return _$this;

    return MarkdownTextSpec(
      textStyle: MixHelpers.lerpTextStyle(_$this.textStyle, other.textStyle, t),
      padding: EdgeInsets.lerp(_$this.padding, other.padding, t),
      alignment: t < 0.5 ? _$this.alignment : other.alignment,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownTextSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownTextSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.textStyle,
        _$this.padding,
        _$this.alignment,
      ];

  MarkdownTextSpec get _$this => this as MarkdownTextSpec;
}

/// Represents the attributes of a [MarkdownTextSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [MarkdownTextSpec].
///
/// Use this class to configure the attributes of a [MarkdownTextSpec] and pass it to
/// the [MarkdownTextSpec] constructor.
class MarkdownTextSpecAttribute extends SpecAttribute<MarkdownTextSpec> {
  final TextStyleDto? textStyle;
  final EdgeInsetsDto? padding;
  final WrapAlignment? alignment;

  const MarkdownTextSpecAttribute({
    this.textStyle,
    this.padding,
    this.alignment,
  });

  /// Resolves to [MarkdownTextSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final markdownTextSpec = MarkdownTextSpecAttribute(...).resolve(mix);
  /// ```
  @override
  MarkdownTextSpec resolve(MixData mix) {
    return MarkdownTextSpec(
      textStyle: textStyle?.resolve(mix),
      padding: padding?.resolve(mix),
      alignment: alignment,
    );
  }

  /// Merges the properties of this [MarkdownTextSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [MarkdownTextSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  MarkdownTextSpecAttribute merge(MarkdownTextSpecAttribute? other) {
    if (other == null) return this;

    return MarkdownTextSpecAttribute(
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      padding: padding?.merge(other.padding) ?? other.padding,
      alignment: other.alignment ?? alignment,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownTextSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownTextSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        textStyle,
        padding,
        alignment,
      ];
}

/// Utility class for configuring [MarkdownTextSpec] properties.
///
/// This class provides methods to set individual properties of a [MarkdownTextSpec].
/// Use the methods of this class to configure specific properties of a [MarkdownTextSpec].
class MarkdownTextSpecUtility<T extends Attribute>
    extends SpecUtility<T, MarkdownTextSpecAttribute> {
  /// Utility for defining [MarkdownTextSpecAttribute.textStyle]
  late final textStyle = TextStyleUtility((v) => only(textStyle: v));

  /// Utility for defining [MarkdownTextSpecAttribute.padding]
  late final padding = EdgeInsetsUtility((v) => only(padding: v));

  /// Utility for defining [MarkdownTextSpecAttribute.alignment]
  late final alignment = WrapAlignmentUtility((v) => only(alignment: v));

  MarkdownTextSpecUtility(super.builder, {super.mutable});

  MarkdownTextSpecUtility<T> get chain =>
      MarkdownTextSpecUtility(attributeBuilder, mutable: true);

  static MarkdownTextSpecUtility<MarkdownTextSpecAttribute> get self =>
      MarkdownTextSpecUtility((v) => v);

  /// Returns a new [MarkdownTextSpecAttribute] with the specified properties.
  @override
  T only({
    TextStyleDto? textStyle,
    EdgeInsetsDto? padding,
    WrapAlignment? alignment,
  }) {
    return builder(MarkdownTextSpecAttribute(
      textStyle: textStyle,
      padding: padding,
      alignment: alignment,
    ));
  }
}

/// A tween that interpolates between two [MarkdownTextSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [MarkdownTextSpec] specifications.
class MarkdownTextSpecTween extends Tween<MarkdownTextSpec?> {
  MarkdownTextSpecTween({
    super.begin,
    super.end,
  });

  @override
  MarkdownTextSpec lerp(double t) {
    if (begin == null && end == null) {
      return const MarkdownTextSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}

/// A mixin that provides spec functionality for [MarkdownListSpec].
mixin _$MarkdownListSpec on Spec<MarkdownListSpec> {
  static MarkdownListSpec from(MixData mix) {
    return mix.attributeOf<MarkdownListSpecAttribute>()?.resolve(mix) ??
        const MarkdownListSpec();
  }

  /// {@template markdown_list_spec_of}
  /// Retrieves the [MarkdownListSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [MarkdownListSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [MarkdownListSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final markdownListSpec = MarkdownListSpec.of(context);
  /// ```
  /// {@endtemplate}
  static MarkdownListSpec of(BuildContext context) {
    return _$MarkdownListSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [MarkdownListSpec] but with the given fields
  /// replaced with the new values.
  @override
  MarkdownListSpec copyWith({
    TextSpec? bullet,
    TextSpec? text,
    WrapAlignment? orderedAlignment,
    WrapAlignment? unorderedAlignment,
  }) {
    return MarkdownListSpec(
      bullet: bullet ?? _$this.bullet,
      text: text ?? _$this.text,
      orderedAlignment: orderedAlignment ?? _$this.orderedAlignment,
      unorderedAlignment: unorderedAlignment ?? _$this.unorderedAlignment,
    );
  }

  /// Linearly interpolates between this [MarkdownListSpec] and another [MarkdownListSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [MarkdownListSpec] is returned. When [t] is 1.0, the [other] [MarkdownListSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [MarkdownListSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [MarkdownListSpec] instance.
  ///
  /// The interpolation is performed on each property of the [MarkdownListSpec] using the appropriate
  /// interpolation method:
  /// - [TextSpec.lerp] for [bullet] and [text].
  /// For [orderedAlignment] and [unorderedAlignment], the interpolation is performed using a step function.
  /// If [t] is less than 0.5, the value from the current [MarkdownListSpec] is used. Otherwise, the value
  /// from the [other] [MarkdownListSpec] is used.
  ///
  /// This method is typically used in animations to smoothly transition between
  /// different [MarkdownListSpec] configurations.
  @override
  MarkdownListSpec lerp(MarkdownListSpec? other, double t) {
    if (other == null) return _$this;

    return MarkdownListSpec(
      bullet: _$this.bullet?.lerp(other.bullet, t) ?? other.bullet,
      text: _$this.text?.lerp(other.text, t) ?? other.text,
      orderedAlignment:
          t < 0.5 ? _$this.orderedAlignment : other.orderedAlignment,
      unorderedAlignment:
          t < 0.5 ? _$this.unorderedAlignment : other.unorderedAlignment,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownListSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownListSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.bullet,
        _$this.text,
        _$this.orderedAlignment,
        _$this.unorderedAlignment,
      ];

  MarkdownListSpec get _$this => this as MarkdownListSpec;
}

/// Represents the attributes of a [MarkdownListSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [MarkdownListSpec].
///
/// Use this class to configure the attributes of a [MarkdownListSpec] and pass it to
/// the [MarkdownListSpec] constructor.
class MarkdownListSpecAttribute extends SpecAttribute<MarkdownListSpec> {
  final TextSpecAttribute? bullet;
  final TextSpecAttribute? text;
  final WrapAlignment? orderedAlignment;
  final WrapAlignment? unorderedAlignment;

  const MarkdownListSpecAttribute({
    this.bullet,
    this.text,
    this.orderedAlignment,
    this.unorderedAlignment,
  });

  /// Resolves to [MarkdownListSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final markdownListSpec = MarkdownListSpecAttribute(...).resolve(mix);
  /// ```
  @override
  MarkdownListSpec resolve(MixData mix) {
    return MarkdownListSpec(
      bullet: bullet?.resolve(mix),
      text: text?.resolve(mix),
      orderedAlignment: orderedAlignment,
      unorderedAlignment: unorderedAlignment,
    );
  }

  /// Merges the properties of this [MarkdownListSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [MarkdownListSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  MarkdownListSpecAttribute merge(MarkdownListSpecAttribute? other) {
    if (other == null) return this;

    return MarkdownListSpecAttribute(
      bullet: bullet?.merge(other.bullet) ?? other.bullet,
      text: text?.merge(other.text) ?? other.text,
      orderedAlignment: other.orderedAlignment ?? orderedAlignment,
      unorderedAlignment: other.unorderedAlignment ?? unorderedAlignment,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownListSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownListSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        bullet,
        text,
        orderedAlignment,
        unorderedAlignment,
      ];
}

/// Utility class for configuring [MarkdownListSpec] properties.
///
/// This class provides methods to set individual properties of a [MarkdownListSpec].
/// Use the methods of this class to configure specific properties of a [MarkdownListSpec].
class MarkdownListSpecUtility<T extends Attribute>
    extends SpecUtility<T, MarkdownListSpecAttribute> {
  /// Utility for defining [MarkdownListSpecAttribute.bullet]
  late final bullet = TextSpecUtility((v) => only(bullet: v));

  /// Utility for defining [MarkdownListSpecAttribute.text]
  late final text = TextSpecUtility((v) => only(text: v));

  /// Utility for defining [MarkdownListSpecAttribute.orderedAlignment]
  late final orderedAlignment =
      WrapAlignmentUtility((v) => only(orderedAlignment: v));

  /// Utility for defining [MarkdownListSpecAttribute.unorderedAlignment]
  late final unorderedAlignment =
      WrapAlignmentUtility((v) => only(unorderedAlignment: v));

  MarkdownListSpecUtility(super.builder, {super.mutable});

  MarkdownListSpecUtility<T> get chain =>
      MarkdownListSpecUtility(attributeBuilder, mutable: true);

  static MarkdownListSpecUtility<MarkdownListSpecAttribute> get self =>
      MarkdownListSpecUtility((v) => v);

  /// Returns a new [MarkdownListSpecAttribute] with the specified properties.
  @override
  T only({
    TextSpecAttribute? bullet,
    TextSpecAttribute? text,
    WrapAlignment? orderedAlignment,
    WrapAlignment? unorderedAlignment,
  }) {
    return builder(MarkdownListSpecAttribute(
      bullet: bullet,
      text: text,
      orderedAlignment: orderedAlignment,
      unorderedAlignment: unorderedAlignment,
    ));
  }
}

/// A tween that interpolates between two [MarkdownListSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [MarkdownListSpec] specifications.
class MarkdownListSpecTween extends Tween<MarkdownListSpec?> {
  MarkdownListSpecTween({
    super.begin,
    super.end,
  });

  @override
  MarkdownListSpec lerp(double t) {
    if (begin == null && end == null) {
      return const MarkdownListSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}

/// A mixin that provides spec functionality for [MarkdownAlertSpec].
mixin _$MarkdownAlertSpec on Spec<MarkdownAlertSpec> {
  static MarkdownAlertSpec from(MixData mix) {
    return mix.attributeOf<MarkdownAlertSpecAttribute>()?.resolve(mix) ??
        const MarkdownAlertSpec();
  }

  /// {@template markdown_alert_spec_of}
  /// Retrieves the [MarkdownAlertSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [MarkdownAlertSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [MarkdownAlertSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final markdownAlertSpec = MarkdownAlertSpec.of(context);
  /// ```
  /// {@endtemplate}
  static MarkdownAlertSpec of(BuildContext context) {
    return _$MarkdownAlertSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [MarkdownAlertSpec] but with the given fields
  /// replaced with the new values.
  @override
  MarkdownAlertSpec copyWith({
    MarkdownAlertTypeSpec? note,
    MarkdownAlertTypeSpec? tip,
    MarkdownAlertTypeSpec? important,
    MarkdownAlertTypeSpec? warning,
    MarkdownAlertTypeSpec? caution,
  }) {
    return MarkdownAlertSpec(
      note: note ?? _$this.note,
      tip: tip ?? _$this.tip,
      important: important ?? _$this.important,
      warning: warning ?? _$this.warning,
      caution: caution ?? _$this.caution,
    );
  }

  /// Linearly interpolates between this [MarkdownAlertSpec] and another [MarkdownAlertSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [MarkdownAlertSpec] is returned. When [t] is 1.0, the [other] [MarkdownAlertSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [MarkdownAlertSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [MarkdownAlertSpec] instance.
  ///
  /// The interpolation is performed on each property of the [MarkdownAlertSpec] using the appropriate
  /// interpolation method:
  /// - [MarkdownAlertTypeSpec.lerp] for [note] and [tip] and [important] and [warning] and [caution].

  /// This method is typically used in animations to smoothly transition between
  /// different [MarkdownAlertSpec] configurations.
  @override
  MarkdownAlertSpec lerp(MarkdownAlertSpec? other, double t) {
    if (other == null) return _$this;

    return MarkdownAlertSpec(
      note: _$this.note.lerp(other.note, t),
      tip: _$this.tip.lerp(other.tip, t),
      important: _$this.important.lerp(other.important, t),
      warning: _$this.warning.lerp(other.warning, t),
      caution: _$this.caution.lerp(other.caution, t),
    );
  }

  /// The list of properties that constitute the state of this [MarkdownAlertSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownAlertSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.note,
        _$this.tip,
        _$this.important,
        _$this.warning,
        _$this.caution,
      ];

  MarkdownAlertSpec get _$this => this as MarkdownAlertSpec;
}

/// Represents the attributes of a [MarkdownAlertSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [MarkdownAlertSpec].
///
/// Use this class to configure the attributes of a [MarkdownAlertSpec] and pass it to
/// the [MarkdownAlertSpec] constructor.
class MarkdownAlertSpecAttribute extends SpecAttribute<MarkdownAlertSpec> {
  final MarkdownAlertTypeSpecAttribute? note;
  final MarkdownAlertTypeSpecAttribute? tip;
  final MarkdownAlertTypeSpecAttribute? important;
  final MarkdownAlertTypeSpecAttribute? warning;
  final MarkdownAlertTypeSpecAttribute? caution;

  const MarkdownAlertSpecAttribute({
    this.note,
    this.tip,
    this.important,
    this.warning,
    this.caution,
  });

  /// Resolves to [MarkdownAlertSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final markdownAlertSpec = MarkdownAlertSpecAttribute(...).resolve(mix);
  /// ```
  @override
  MarkdownAlertSpec resolve(MixData mix) {
    return MarkdownAlertSpec(
      note: note?.resolve(mix),
      tip: tip?.resolve(mix),
      important: important?.resolve(mix),
      warning: warning?.resolve(mix),
      caution: caution?.resolve(mix),
    );
  }

  /// Merges the properties of this [MarkdownAlertSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [MarkdownAlertSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  MarkdownAlertSpecAttribute merge(MarkdownAlertSpecAttribute? other) {
    if (other == null) return this;

    return MarkdownAlertSpecAttribute(
      note: note?.merge(other.note) ?? other.note,
      tip: tip?.merge(other.tip) ?? other.tip,
      important: important?.merge(other.important) ?? other.important,
      warning: warning?.merge(other.warning) ?? other.warning,
      caution: caution?.merge(other.caution) ?? other.caution,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownAlertSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownAlertSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        note,
        tip,
        important,
        warning,
        caution,
      ];
}

/// Utility class for configuring [MarkdownAlertSpec] properties.
///
/// This class provides methods to set individual properties of a [MarkdownAlertSpec].
/// Use the methods of this class to configure specific properties of a [MarkdownAlertSpec].
class MarkdownAlertSpecUtility<T extends Attribute>
    extends SpecUtility<T, MarkdownAlertSpecAttribute> {
  /// Utility for defining [MarkdownAlertSpecAttribute.note]
  late final note = MarkdownAlertTypeSpecUtility((v) => only(note: v));

  /// Utility for defining [MarkdownAlertSpecAttribute.tip]
  late final tip = MarkdownAlertTypeSpecUtility((v) => only(tip: v));

  /// Utility for defining [MarkdownAlertSpecAttribute.important]
  late final important =
      MarkdownAlertTypeSpecUtility((v) => only(important: v));

  /// Utility for defining [MarkdownAlertSpecAttribute.warning]
  late final warning = MarkdownAlertTypeSpecUtility((v) => only(warning: v));

  /// Utility for defining [MarkdownAlertSpecAttribute.caution]
  late final caution = MarkdownAlertTypeSpecUtility((v) => only(caution: v));

  MarkdownAlertSpecUtility(super.builder, {super.mutable});

  MarkdownAlertSpecUtility<T> get chain =>
      MarkdownAlertSpecUtility(attributeBuilder, mutable: true);

  static MarkdownAlertSpecUtility<MarkdownAlertSpecAttribute> get self =>
      MarkdownAlertSpecUtility((v) => v);

  /// Returns a new [MarkdownAlertSpecAttribute] with the specified properties.
  @override
  T only({
    MarkdownAlertTypeSpecAttribute? note,
    MarkdownAlertTypeSpecAttribute? tip,
    MarkdownAlertTypeSpecAttribute? important,
    MarkdownAlertTypeSpecAttribute? warning,
    MarkdownAlertTypeSpecAttribute? caution,
  }) {
    return builder(MarkdownAlertSpecAttribute(
      note: note,
      tip: tip,
      important: important,
      warning: warning,
      caution: caution,
    ));
  }
}

/// A tween that interpolates between two [MarkdownAlertSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [MarkdownAlertSpec] specifications.
class MarkdownAlertSpecTween extends Tween<MarkdownAlertSpec?> {
  MarkdownAlertSpecTween({
    super.begin,
    super.end,
  });

  @override
  MarkdownAlertSpec lerp(double t) {
    if (begin == null && end == null) {
      return const MarkdownAlertSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}

/// A mixin that provides spec functionality for [MarkdownAlertTypeSpec].
mixin _$MarkdownAlertTypeSpec on Spec<MarkdownAlertTypeSpec> {
  static MarkdownAlertTypeSpec from(MixData mix) {
    return mix.attributeOf<MarkdownAlertTypeSpecAttribute>()?.resolve(mix) ??
        const MarkdownAlertTypeSpec();
  }

  /// {@template markdown_alert_type_spec_of}
  /// Retrieves the [MarkdownAlertTypeSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [MarkdownAlertTypeSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [MarkdownAlertTypeSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final markdownAlertTypeSpec = MarkdownAlertTypeSpec.of(context);
  /// ```
  /// {@endtemplate}
  static MarkdownAlertTypeSpec of(BuildContext context) {
    return _$MarkdownAlertTypeSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [MarkdownAlertTypeSpec] but with the given fields
  /// replaced with the new values.
  @override
  MarkdownAlertTypeSpec copyWith({
    TextSpec? heading,
    TextSpec? description,
    IconSpec? icon,
    BoxSpec? container,
    FlexSpec? headingFlex,
    FlexSpec? containerFlex,
  }) {
    return MarkdownAlertTypeSpec(
      heading: heading ?? _$this.heading,
      description: description ?? _$this.description,
      icon: icon ?? _$this.icon,
      container: container ?? _$this.container,
      headingFlex: headingFlex ?? _$this.headingFlex,
      containerFlex: containerFlex ?? _$this.containerFlex,
    );
  }

  /// Linearly interpolates between this [MarkdownAlertTypeSpec] and another [MarkdownAlertTypeSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [MarkdownAlertTypeSpec] is returned. When [t] is 1.0, the [other] [MarkdownAlertTypeSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [MarkdownAlertTypeSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [MarkdownAlertTypeSpec] instance.
  ///
  /// The interpolation is performed on each property of the [MarkdownAlertTypeSpec] using the appropriate
  /// interpolation method:
  /// - [TextSpec.lerp] for [heading] and [description].
  /// - [IconSpec.lerp] for [icon].
  /// - [BoxSpec.lerp] for [container].
  /// - [FlexSpec.lerp] for [headingFlex] and [containerFlex].

  /// This method is typically used in animations to smoothly transition between
  /// different [MarkdownAlertTypeSpec] configurations.
  @override
  MarkdownAlertTypeSpec lerp(MarkdownAlertTypeSpec? other, double t) {
    if (other == null) return _$this;

    return MarkdownAlertTypeSpec(
      heading: _$this.heading.lerp(other.heading, t),
      description: _$this.description.lerp(other.description, t),
      icon: _$this.icon.lerp(other.icon, t),
      container: _$this.container.lerp(other.container, t),
      headingFlex: _$this.headingFlex.lerp(other.headingFlex, t),
      containerFlex: _$this.containerFlex.lerp(other.containerFlex, t),
    );
  }

  /// The list of properties that constitute the state of this [MarkdownAlertTypeSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownAlertTypeSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.heading,
        _$this.description,
        _$this.icon,
        _$this.container,
        _$this.headingFlex,
        _$this.containerFlex,
      ];

  MarkdownAlertTypeSpec get _$this => this as MarkdownAlertTypeSpec;
}

/// Represents the attributes of a [MarkdownAlertTypeSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [MarkdownAlertTypeSpec].
///
/// Use this class to configure the attributes of a [MarkdownAlertTypeSpec] and pass it to
/// the [MarkdownAlertTypeSpec] constructor.
class MarkdownAlertTypeSpecAttribute
    extends SpecAttribute<MarkdownAlertTypeSpec> {
  final TextSpecAttribute? heading;
  final TextSpecAttribute? description;
  final IconSpecAttribute? icon;
  final BoxSpecAttribute? container;
  final FlexSpecAttribute? headingFlex;
  final FlexSpecAttribute? containerFlex;

  const MarkdownAlertTypeSpecAttribute({
    this.heading,
    this.description,
    this.icon,
    this.container,
    this.headingFlex,
    this.containerFlex,
  });

  /// Resolves to [MarkdownAlertTypeSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final markdownAlertTypeSpec = MarkdownAlertTypeSpecAttribute(...).resolve(mix);
  /// ```
  @override
  MarkdownAlertTypeSpec resolve(MixData mix) {
    return MarkdownAlertTypeSpec(
      heading: heading?.resolve(mix),
      description: description?.resolve(mix),
      icon: icon?.resolve(mix),
      container: container?.resolve(mix),
      headingFlex: headingFlex?.resolve(mix),
      containerFlex: containerFlex?.resolve(mix),
    );
  }

  /// Merges the properties of this [MarkdownAlertTypeSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [MarkdownAlertTypeSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  MarkdownAlertTypeSpecAttribute merge(MarkdownAlertTypeSpecAttribute? other) {
    if (other == null) return this;

    return MarkdownAlertTypeSpecAttribute(
      heading: heading?.merge(other.heading) ?? other.heading,
      description: description?.merge(other.description) ?? other.description,
      icon: icon?.merge(other.icon) ?? other.icon,
      container: container?.merge(other.container) ?? other.container,
      headingFlex: headingFlex?.merge(other.headingFlex) ?? other.headingFlex,
      containerFlex:
          containerFlex?.merge(other.containerFlex) ?? other.containerFlex,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownAlertTypeSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownAlertTypeSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        heading,
        description,
        icon,
        container,
        headingFlex,
        containerFlex,
      ];
}

/// Utility class for configuring [MarkdownAlertTypeSpec] properties.
///
/// This class provides methods to set individual properties of a [MarkdownAlertTypeSpec].
/// Use the methods of this class to configure specific properties of a [MarkdownAlertTypeSpec].
class MarkdownAlertTypeSpecUtility<T extends Attribute>
    extends SpecUtility<T, MarkdownAlertTypeSpecAttribute> {
  /// Utility for defining [MarkdownAlertTypeSpecAttribute.heading]
  late final heading = TextSpecUtility((v) => only(heading: v));

  /// Utility for defining [MarkdownAlertTypeSpecAttribute.description]
  late final description = TextSpecUtility((v) => only(description: v));

  /// Utility for defining [MarkdownAlertTypeSpecAttribute.icon]
  late final icon = IconSpecUtility((v) => only(icon: v));

  /// Utility for defining [MarkdownAlertTypeSpecAttribute.container]
  late final container = BoxSpecUtility((v) => only(container: v));

  /// Utility for defining [MarkdownAlertTypeSpecAttribute.headingFlex]
  late final headingFlex = FlexSpecUtility((v) => only(headingFlex: v));

  /// Utility for defining [MarkdownAlertTypeSpecAttribute.containerFlex]
  late final containerFlex = FlexSpecUtility((v) => only(containerFlex: v));

  MarkdownAlertTypeSpecUtility(super.builder, {super.mutable});

  MarkdownAlertTypeSpecUtility<T> get chain =>
      MarkdownAlertTypeSpecUtility(attributeBuilder, mutable: true);

  static MarkdownAlertTypeSpecUtility<MarkdownAlertTypeSpecAttribute>
      get self => MarkdownAlertTypeSpecUtility((v) => v);

  /// Returns a new [MarkdownAlertTypeSpecAttribute] with the specified properties.
  @override
  T only({
    TextSpecAttribute? heading,
    TextSpecAttribute? description,
    IconSpecAttribute? icon,
    BoxSpecAttribute? container,
    FlexSpecAttribute? headingFlex,
    FlexSpecAttribute? containerFlex,
  }) {
    return builder(MarkdownAlertTypeSpecAttribute(
      heading: heading,
      description: description,
      icon: icon,
      container: container,
      headingFlex: headingFlex,
      containerFlex: containerFlex,
    ));
  }
}

/// A tween that interpolates between two [MarkdownAlertTypeSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [MarkdownAlertTypeSpec] specifications.
class MarkdownAlertTypeSpecTween extends Tween<MarkdownAlertTypeSpec?> {
  MarkdownAlertTypeSpecTween({
    super.begin,
    super.end,
  });

  @override
  MarkdownAlertTypeSpec lerp(double t) {
    if (begin == null && end == null) {
      return const MarkdownAlertTypeSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}

/// A mixin that provides spec functionality for [MarkdownTableSpec].
mixin _$MarkdownTableSpec on Spec<MarkdownTableSpec> {
  static MarkdownTableSpec from(MixData mix) {
    return mix.attributeOf<MarkdownTableSpecAttribute>()?.resolve(mix) ??
        const MarkdownTableSpec();
  }

  /// {@template markdown_table_spec_of}
  /// Retrieves the [MarkdownTableSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [MarkdownTableSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [MarkdownTableSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final markdownTableSpec = MarkdownTableSpec.of(context);
  /// ```
  /// {@endtemplate}
  static MarkdownTableSpec of(BuildContext context) {
    return _$MarkdownTableSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [MarkdownTableSpec] but with the given fields
  /// replaced with the new values.
  @override
  MarkdownTableSpec copyWith({
    TextStyle? headStyle,
    TextStyle? bodyStyle,
    TextAlign? headAlignment,
    EdgeInsets? padding,
    TableBorder? border,
    TableColumnWidth? columnWidth,
    EdgeInsets? cellPadding,
    BoxDecoration? cellDecoration,
    TableCellVerticalAlignment? verticalAlignment,
    WidgetModifiersData? modifiers,
    AnimatedData? animated,
  }) {
    return MarkdownTableSpec(
      headStyle: headStyle ?? _$this.headStyle,
      bodyStyle: bodyStyle ?? _$this.bodyStyle,
      headAlignment: headAlignment ?? _$this.headAlignment,
      padding: padding ?? _$this.padding,
      border: border ?? _$this.border,
      columnWidth: columnWidth ?? _$this.columnWidth,
      cellPadding: cellPadding ?? _$this.cellPadding,
      cellDecoration: cellDecoration ?? _$this.cellDecoration,
      verticalAlignment: verticalAlignment ?? _$this.verticalAlignment,
      modifiers: modifiers ?? _$this.modifiers,
      animated: animated ?? _$this.animated,
    );
  }

  /// Linearly interpolates between this [MarkdownTableSpec] and another [MarkdownTableSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [MarkdownTableSpec] is returned. When [t] is 1.0, the [other] [MarkdownTableSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [MarkdownTableSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [MarkdownTableSpec] instance.
  ///
  /// The interpolation is performed on each property of the [MarkdownTableSpec] using the appropriate
  /// interpolation method:
  /// - [MixHelpers.lerpTextStyle] for [headStyle] and [bodyStyle].
  /// - [EdgeInsets.lerp] for [padding] and [cellPadding].
  /// - [TableBorder.lerp] for [border].
  /// - [BoxDecoration.lerp] for [cellDecoration].
  /// For [headAlignment] and [columnWidth] and [verticalAlignment] and [modifiers] and [animated], the interpolation is performed using a step function.
  /// If [t] is less than 0.5, the value from the current [MarkdownTableSpec] is used. Otherwise, the value
  /// from the [other] [MarkdownTableSpec] is used.
  ///
  /// This method is typically used in animations to smoothly transition between
  /// different [MarkdownTableSpec] configurations.
  @override
  MarkdownTableSpec lerp(MarkdownTableSpec? other, double t) {
    if (other == null) return _$this;

    return MarkdownTableSpec(
      headStyle: MixHelpers.lerpTextStyle(_$this.headStyle, other.headStyle, t),
      bodyStyle: MixHelpers.lerpTextStyle(_$this.bodyStyle, other.bodyStyle, t),
      headAlignment: t < 0.5 ? _$this.headAlignment : other.headAlignment,
      padding: EdgeInsets.lerp(_$this.padding, other.padding, t),
      border: TableBorder.lerp(_$this.border, other.border, t),
      columnWidth: t < 0.5 ? _$this.columnWidth : other.columnWidth,
      cellPadding: EdgeInsets.lerp(_$this.cellPadding, other.cellPadding, t),
      cellDecoration:
          BoxDecoration.lerp(_$this.cellDecoration, other.cellDecoration, t),
      verticalAlignment:
          t < 0.5 ? _$this.verticalAlignment : other.verticalAlignment,
      modifiers: other.modifiers,
      animated: t < 0.5 ? _$this.animated : other.animated,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownTableSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownTableSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.headStyle,
        _$this.bodyStyle,
        _$this.headAlignment,
        _$this.padding,
        _$this.border,
        _$this.columnWidth,
        _$this.cellPadding,
        _$this.cellDecoration,
        _$this.verticalAlignment,
        _$this.modifiers,
        _$this.animated,
      ];

  MarkdownTableSpec get _$this => this as MarkdownTableSpec;
}

/// Represents the attributes of a [MarkdownTableSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [MarkdownTableSpec].
///
/// Use this class to configure the attributes of a [MarkdownTableSpec] and pass it to
/// the [MarkdownTableSpec] constructor.
class MarkdownTableSpecAttribute extends SpecAttribute<MarkdownTableSpec> {
  final TextStyleDto? headStyle;
  final TextStyleDto? bodyStyle;
  final TextAlign? headAlignment;
  final EdgeInsetsDto? padding;
  final TableBorder? border;
  final TableColumnWidth? columnWidth;
  final EdgeInsetsDto? cellPadding;
  final BoxDecorationDto? cellDecoration;
  final TableCellVerticalAlignment? verticalAlignment;

  const MarkdownTableSpecAttribute({
    this.headStyle,
    this.bodyStyle,
    this.headAlignment,
    this.padding,
    this.border,
    this.columnWidth,
    this.cellPadding,
    this.cellDecoration,
    this.verticalAlignment,
    super.modifiers,
    super.animated,
  });

  /// Resolves to [MarkdownTableSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final markdownTableSpec = MarkdownTableSpecAttribute(...).resolve(mix);
  /// ```
  @override
  MarkdownTableSpec resolve(MixData mix) {
    return MarkdownTableSpec(
      headStyle: headStyle?.resolve(mix),
      bodyStyle: bodyStyle?.resolve(mix),
      headAlignment: headAlignment,
      padding: padding?.resolve(mix),
      border: border,
      columnWidth: columnWidth,
      cellPadding: cellPadding?.resolve(mix),
      cellDecoration: cellDecoration?.resolve(mix),
      verticalAlignment: verticalAlignment,
      modifiers: modifiers?.resolve(mix),
      animated: animated?.resolve(mix) ?? mix.animation,
    );
  }

  /// Merges the properties of this [MarkdownTableSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [MarkdownTableSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  MarkdownTableSpecAttribute merge(MarkdownTableSpecAttribute? other) {
    if (other == null) return this;

    return MarkdownTableSpecAttribute(
      headStyle: headStyle?.merge(other.headStyle) ?? other.headStyle,
      bodyStyle: bodyStyle?.merge(other.bodyStyle) ?? other.bodyStyle,
      headAlignment: other.headAlignment ?? headAlignment,
      padding: padding?.merge(other.padding) ?? other.padding,
      border: other.border ?? border,
      columnWidth: other.columnWidth ?? columnWidth,
      cellPadding: cellPadding?.merge(other.cellPadding) ?? other.cellPadding,
      cellDecoration:
          cellDecoration?.merge(other.cellDecoration) ?? other.cellDecoration,
      verticalAlignment: other.verticalAlignment ?? verticalAlignment,
      modifiers: modifiers?.merge(other.modifiers) ?? other.modifiers,
      animated: animated?.merge(other.animated) ?? other.animated,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownTableSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownTableSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        headStyle,
        bodyStyle,
        headAlignment,
        padding,
        border,
        columnWidth,
        cellPadding,
        cellDecoration,
        verticalAlignment,
        modifiers,
        animated,
      ];
}

/// Utility class for configuring [MarkdownTableSpec] properties.
///
/// This class provides methods to set individual properties of a [MarkdownTableSpec].
/// Use the methods of this class to configure specific properties of a [MarkdownTableSpec].
class MarkdownTableSpecUtility<T extends Attribute>
    extends SpecUtility<T, MarkdownTableSpecAttribute> {
  /// Utility for defining [MarkdownTableSpecAttribute.headStyle]
  late final headStyle = TextStyleUtility((v) => only(headStyle: v));

  /// Utility for defining [MarkdownTableSpecAttribute.bodyStyle]
  late final bodyStyle = TextStyleUtility((v) => only(bodyStyle: v));

  /// Utility for defining [MarkdownTableSpecAttribute.headAlignment]
  late final headAlignment = TextAlignUtility((v) => only(headAlignment: v));

  /// Utility for defining [MarkdownTableSpecAttribute.padding]
  late final padding = EdgeInsetsUtility((v) => only(padding: v));

  /// Utility for defining [MarkdownTableSpecAttribute.border]
  late final border = TableBorderUtility((v) => only(border: v));

  /// Utility for defining [MarkdownTableSpecAttribute.columnWidth]
  late final columnWidth = TableColumnWidthUtility((v) => only(columnWidth: v));

  /// Utility for defining [MarkdownTableSpecAttribute.cellPadding]
  late final cellPadding = EdgeInsetsUtility((v) => only(cellPadding: v));

  /// Utility for defining [MarkdownTableSpecAttribute.cellDecoration]
  late final cellDecoration =
      BoxDecorationUtility((v) => only(cellDecoration: v));

  /// Utility for defining [MarkdownTableSpecAttribute.verticalAlignment]
  late final verticalAlignment =
      TableCellVerticalAlignmentUtility((v) => only(verticalAlignment: v));

  /// Utility for defining [MarkdownTableSpecAttribute.modifiers]
  late final wrap = SpecModifierUtility((v) => only(modifiers: v));

  /// Utility for defining [MarkdownTableSpecAttribute.animated]
  late final animated = AnimatedUtility((v) => only(animated: v));

  MarkdownTableSpecUtility(super.builder, {super.mutable});

  MarkdownTableSpecUtility<T> get chain =>
      MarkdownTableSpecUtility(attributeBuilder, mutable: true);

  static MarkdownTableSpecUtility<MarkdownTableSpecAttribute> get self =>
      MarkdownTableSpecUtility((v) => v);

  /// Returns a new [MarkdownTableSpecAttribute] with the specified properties.
  @override
  T only({
    TextStyleDto? headStyle,
    TextStyleDto? bodyStyle,
    TextAlign? headAlignment,
    EdgeInsetsDto? padding,
    TableBorder? border,
    TableColumnWidth? columnWidth,
    EdgeInsetsDto? cellPadding,
    BoxDecorationDto? cellDecoration,
    TableCellVerticalAlignment? verticalAlignment,
    WidgetModifiersDataDto? modifiers,
    AnimatedDataDto? animated,
  }) {
    return builder(MarkdownTableSpecAttribute(
      headStyle: headStyle,
      bodyStyle: bodyStyle,
      headAlignment: headAlignment,
      padding: padding,
      border: border,
      columnWidth: columnWidth,
      cellPadding: cellPadding,
      cellDecoration: cellDecoration,
      verticalAlignment: verticalAlignment,
      modifiers: modifiers,
      animated: animated,
    ));
  }
}

/// A tween that interpolates between two [MarkdownTableSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [MarkdownTableSpec] specifications.
class MarkdownTableSpecTween extends Tween<MarkdownTableSpec?> {
  MarkdownTableSpecTween({
    super.begin,
    super.end,
  });

  @override
  MarkdownTableSpec lerp(double t) {
    if (begin == null && end == null) {
      return const MarkdownTableSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}

/// A mixin that provides spec functionality for [MarkdownBlockquoteSpec].
mixin _$MarkdownBlockquoteSpec on Spec<MarkdownBlockquoteSpec> {
  static MarkdownBlockquoteSpec from(MixData mix) {
    return mix.attributeOf<MarkdownBlockquoteSpecAttribute>()?.resolve(mix) ??
        const MarkdownBlockquoteSpec();
  }

  /// {@template markdown_blockquote_spec_of}
  /// Retrieves the [MarkdownBlockquoteSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [MarkdownBlockquoteSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [MarkdownBlockquoteSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final markdownBlockquoteSpec = MarkdownBlockquoteSpec.of(context);
  /// ```
  /// {@endtemplate}
  static MarkdownBlockquoteSpec of(BuildContext context) {
    return _$MarkdownBlockquoteSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [MarkdownBlockquoteSpec] but with the given fields
  /// replaced with the new values.
  @override
  MarkdownBlockquoteSpec copyWith({
    TextStyle? textStyle,
    EdgeInsets? padding,
    BoxDecoration? decoration,
    WrapAlignment? alignment,
    WidgetModifiersData? modifiers,
    AnimatedData? animated,
  }) {
    return MarkdownBlockquoteSpec(
      textStyle: textStyle ?? _$this.textStyle,
      padding: padding ?? _$this.padding,
      decoration: decoration ?? _$this.decoration,
      alignment: alignment ?? _$this.alignment,
      modifiers: modifiers ?? _$this.modifiers,
      animated: animated ?? _$this.animated,
    );
  }

  /// Linearly interpolates between this [MarkdownBlockquoteSpec] and another [MarkdownBlockquoteSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [MarkdownBlockquoteSpec] is returned. When [t] is 1.0, the [other] [MarkdownBlockquoteSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [MarkdownBlockquoteSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [MarkdownBlockquoteSpec] instance.
  ///
  /// The interpolation is performed on each property of the [MarkdownBlockquoteSpec] using the appropriate
  /// interpolation method:
  /// - [MixHelpers.lerpTextStyle] for [textStyle].
  /// - [EdgeInsets.lerp] for [padding].
  /// - [BoxDecoration.lerp] for [decoration].
  /// For [alignment] and [modifiers] and [animated], the interpolation is performed using a step function.
  /// If [t] is less than 0.5, the value from the current [MarkdownBlockquoteSpec] is used. Otherwise, the value
  /// from the [other] [MarkdownBlockquoteSpec] is used.
  ///
  /// This method is typically used in animations to smoothly transition between
  /// different [MarkdownBlockquoteSpec] configurations.
  @override
  MarkdownBlockquoteSpec lerp(MarkdownBlockquoteSpec? other, double t) {
    if (other == null) return _$this;

    return MarkdownBlockquoteSpec(
      textStyle: MixHelpers.lerpTextStyle(_$this.textStyle, other.textStyle, t),
      padding: EdgeInsets.lerp(_$this.padding, other.padding, t),
      decoration: BoxDecoration.lerp(_$this.decoration, other.decoration, t),
      alignment: t < 0.5 ? _$this.alignment : other.alignment,
      modifiers: other.modifiers,
      animated: t < 0.5 ? _$this.animated : other.animated,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownBlockquoteSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownBlockquoteSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.textStyle,
        _$this.padding,
        _$this.decoration,
        _$this.alignment,
        _$this.modifiers,
        _$this.animated,
      ];

  MarkdownBlockquoteSpec get _$this => this as MarkdownBlockquoteSpec;
}

/// Represents the attributes of a [MarkdownBlockquoteSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [MarkdownBlockquoteSpec].
///
/// Use this class to configure the attributes of a [MarkdownBlockquoteSpec] and pass it to
/// the [MarkdownBlockquoteSpec] constructor.
class MarkdownBlockquoteSpecAttribute
    extends SpecAttribute<MarkdownBlockquoteSpec> {
  final TextStyleDto? textStyle;
  final EdgeInsetsDto? padding;
  final BoxDecorationDto? decoration;
  final WrapAlignment? alignment;

  const MarkdownBlockquoteSpecAttribute({
    this.textStyle,
    this.padding,
    this.decoration,
    this.alignment,
    super.modifiers,
    super.animated,
  });

  /// Resolves to [MarkdownBlockquoteSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final markdownBlockquoteSpec = MarkdownBlockquoteSpecAttribute(...).resolve(mix);
  /// ```
  @override
  MarkdownBlockquoteSpec resolve(MixData mix) {
    return MarkdownBlockquoteSpec(
      textStyle: textStyle?.resolve(mix),
      padding: padding?.resolve(mix),
      decoration: decoration?.resolve(mix),
      alignment: alignment,
      modifiers: modifiers?.resolve(mix),
      animated: animated?.resolve(mix) ?? mix.animation,
    );
  }

  /// Merges the properties of this [MarkdownBlockquoteSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [MarkdownBlockquoteSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  MarkdownBlockquoteSpecAttribute merge(
      MarkdownBlockquoteSpecAttribute? other) {
    if (other == null) return this;

    return MarkdownBlockquoteSpecAttribute(
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      padding: padding?.merge(other.padding) ?? other.padding,
      decoration: decoration?.merge(other.decoration) ?? other.decoration,
      alignment: other.alignment ?? alignment,
      modifiers: modifiers?.merge(other.modifiers) ?? other.modifiers,
      animated: animated?.merge(other.animated) ?? other.animated,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownBlockquoteSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownBlockquoteSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        textStyle,
        padding,
        decoration,
        alignment,
        modifiers,
        animated,
      ];
}

/// Utility class for configuring [MarkdownBlockquoteSpec] properties.
///
/// This class provides methods to set individual properties of a [MarkdownBlockquoteSpec].
/// Use the methods of this class to configure specific properties of a [MarkdownBlockquoteSpec].
class MarkdownBlockquoteSpecUtility<T extends Attribute>
    extends SpecUtility<T, MarkdownBlockquoteSpecAttribute> {
  /// Utility for defining [MarkdownBlockquoteSpecAttribute.textStyle]
  late final textStyle = TextStyleUtility((v) => only(textStyle: v));

  /// Utility for defining [MarkdownBlockquoteSpecAttribute.padding]
  late final padding = EdgeInsetsUtility((v) => only(padding: v));

  /// Utility for defining [MarkdownBlockquoteSpecAttribute.decoration]
  late final decoration = BoxDecorationUtility((v) => only(decoration: v));

  /// Utility for defining [MarkdownBlockquoteSpecAttribute.alignment]
  late final alignment = WrapAlignmentUtility((v) => only(alignment: v));

  /// Utility for defining [MarkdownBlockquoteSpecAttribute.modifiers]
  late final wrap = SpecModifierUtility((v) => only(modifiers: v));

  /// Utility for defining [MarkdownBlockquoteSpecAttribute.animated]
  late final animated = AnimatedUtility((v) => only(animated: v));

  MarkdownBlockquoteSpecUtility(super.builder, {super.mutable});

  MarkdownBlockquoteSpecUtility<T> get chain =>
      MarkdownBlockquoteSpecUtility(attributeBuilder, mutable: true);

  static MarkdownBlockquoteSpecUtility<MarkdownBlockquoteSpecAttribute>
      get self => MarkdownBlockquoteSpecUtility((v) => v);

  /// Returns a new [MarkdownBlockquoteSpecAttribute] with the specified properties.
  @override
  T only({
    TextStyleDto? textStyle,
    EdgeInsetsDto? padding,
    BoxDecorationDto? decoration,
    WrapAlignment? alignment,
    WidgetModifiersDataDto? modifiers,
    AnimatedDataDto? animated,
  }) {
    return builder(MarkdownBlockquoteSpecAttribute(
      textStyle: textStyle,
      padding: padding,
      decoration: decoration,
      alignment: alignment,
      modifiers: modifiers,
      animated: animated,
    ));
  }
}

/// A tween that interpolates between two [MarkdownBlockquoteSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [MarkdownBlockquoteSpec] specifications.
class MarkdownBlockquoteSpecTween extends Tween<MarkdownBlockquoteSpec?> {
  MarkdownBlockquoteSpecTween({
    super.begin,
    super.end,
  });

  @override
  MarkdownBlockquoteSpec lerp(double t) {
    if (begin == null && end == null) {
      return const MarkdownBlockquoteSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}

/// A mixin that provides spec functionality for [MarkdownCodeblockSpec].
mixin _$MarkdownCodeblockSpec on Spec<MarkdownCodeblockSpec> {
  static MarkdownCodeblockSpec from(MixData mix) {
    return mix.attributeOf<MarkdownCodeblockSpecAttribute>()?.resolve(mix) ??
        const MarkdownCodeblockSpec();
  }

  /// {@template markdown_codeblock_spec_of}
  /// Retrieves the [MarkdownCodeblockSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [MarkdownCodeblockSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [MarkdownCodeblockSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final markdownCodeblockSpec = MarkdownCodeblockSpec.of(context);
  /// ```
  /// {@endtemplate}
  static MarkdownCodeblockSpec of(BuildContext context) {
    return _$MarkdownCodeblockSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [MarkdownCodeblockSpec] but with the given fields
  /// replaced with the new values.
  @override
  MarkdownCodeblockSpec copyWith({
    TextStyle? textStyle,
    BoxSpec? container,
    WrapAlignment? alignment,
    WidgetModifiersData? modifiers,
    AnimatedData? animated,
  }) {
    return MarkdownCodeblockSpec(
      textStyle: textStyle ?? _$this.textStyle,
      container: container ?? _$this.container,
      alignment: alignment ?? _$this.alignment,
      modifiers: modifiers ?? _$this.modifiers,
      animated: animated ?? _$this.animated,
    );
  }

  /// Linearly interpolates between this [MarkdownCodeblockSpec] and another [MarkdownCodeblockSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [MarkdownCodeblockSpec] is returned. When [t] is 1.0, the [other] [MarkdownCodeblockSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [MarkdownCodeblockSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [MarkdownCodeblockSpec] instance.
  ///
  /// The interpolation is performed on each property of the [MarkdownCodeblockSpec] using the appropriate
  /// interpolation method:
  /// - [MixHelpers.lerpTextStyle] for [textStyle].
  /// - [BoxSpec.lerp] for [container].
  /// For [alignment] and [modifiers] and [animated], the interpolation is performed using a step function.
  /// If [t] is less than 0.5, the value from the current [MarkdownCodeblockSpec] is used. Otherwise, the value
  /// from the [other] [MarkdownCodeblockSpec] is used.
  ///
  /// This method is typically used in animations to smoothly transition between
  /// different [MarkdownCodeblockSpec] configurations.
  @override
  MarkdownCodeblockSpec lerp(MarkdownCodeblockSpec? other, double t) {
    if (other == null) return _$this;

    return MarkdownCodeblockSpec(
      textStyle: MixHelpers.lerpTextStyle(_$this.textStyle, other.textStyle, t),
      container: _$this.container?.lerp(other.container, t) ?? other.container,
      alignment: t < 0.5 ? _$this.alignment : other.alignment,
      modifiers: other.modifiers,
      animated: t < 0.5 ? _$this.animated : other.animated,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownCodeblockSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownCodeblockSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.textStyle,
        _$this.container,
        _$this.alignment,
        _$this.modifiers,
        _$this.animated,
      ];

  MarkdownCodeblockSpec get _$this => this as MarkdownCodeblockSpec;
}

/// Represents the attributes of a [MarkdownCodeblockSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [MarkdownCodeblockSpec].
///
/// Use this class to configure the attributes of a [MarkdownCodeblockSpec] and pass it to
/// the [MarkdownCodeblockSpec] constructor.
class MarkdownCodeblockSpecAttribute
    extends SpecAttribute<MarkdownCodeblockSpec> {
  final TextStyleDto? textStyle;
  final BoxSpecAttribute? container;
  final WrapAlignment? alignment;

  const MarkdownCodeblockSpecAttribute({
    this.textStyle,
    this.container,
    this.alignment,
    super.modifiers,
    super.animated,
  });

  /// Resolves to [MarkdownCodeblockSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final markdownCodeblockSpec = MarkdownCodeblockSpecAttribute(...).resolve(mix);
  /// ```
  @override
  MarkdownCodeblockSpec resolve(MixData mix) {
    return MarkdownCodeblockSpec(
      textStyle: textStyle?.resolve(mix),
      container: container?.resolve(mix),
      alignment: alignment,
      modifiers: modifiers?.resolve(mix),
      animated: animated?.resolve(mix) ?? mix.animation,
    );
  }

  /// Merges the properties of this [MarkdownCodeblockSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [MarkdownCodeblockSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  MarkdownCodeblockSpecAttribute merge(MarkdownCodeblockSpecAttribute? other) {
    if (other == null) return this;

    return MarkdownCodeblockSpecAttribute(
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      container: container?.merge(other.container) ?? other.container,
      alignment: other.alignment ?? alignment,
      modifiers: modifiers?.merge(other.modifiers) ?? other.modifiers,
      animated: animated?.merge(other.animated) ?? other.animated,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownCodeblockSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownCodeblockSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        textStyle,
        container,
        alignment,
        modifiers,
        animated,
      ];
}

/// Utility class for configuring [MarkdownCodeblockSpec] properties.
///
/// This class provides methods to set individual properties of a [MarkdownCodeblockSpec].
/// Use the methods of this class to configure specific properties of a [MarkdownCodeblockSpec].
class MarkdownCodeblockSpecUtility<T extends Attribute>
    extends SpecUtility<T, MarkdownCodeblockSpecAttribute> {
  /// Utility for defining [MarkdownCodeblockSpecAttribute.textStyle]
  late final textStyle = TextStyleUtility((v) => only(textStyle: v));

  /// Utility for defining [MarkdownCodeblockSpecAttribute.container]
  late final container = BoxSpecUtility((v) => only(container: v));

  /// Utility for defining [MarkdownCodeblockSpecAttribute.alignment]
  late final alignment = WrapAlignmentUtility((v) => only(alignment: v));

  /// Utility for defining [MarkdownCodeblockSpecAttribute.modifiers]
  late final wrap = SpecModifierUtility((v) => only(modifiers: v));

  /// Utility for defining [MarkdownCodeblockSpecAttribute.animated]
  late final animated = AnimatedUtility((v) => only(animated: v));

  MarkdownCodeblockSpecUtility(super.builder, {super.mutable});

  MarkdownCodeblockSpecUtility<T> get chain =>
      MarkdownCodeblockSpecUtility(attributeBuilder, mutable: true);

  static MarkdownCodeblockSpecUtility<MarkdownCodeblockSpecAttribute>
      get self => MarkdownCodeblockSpecUtility((v) => v);

  /// Returns a new [MarkdownCodeblockSpecAttribute] with the specified properties.
  @override
  T only({
    TextStyleDto? textStyle,
    BoxSpecAttribute? container,
    WrapAlignment? alignment,
    WidgetModifiersDataDto? modifiers,
    AnimatedDataDto? animated,
  }) {
    return builder(MarkdownCodeblockSpecAttribute(
      textStyle: textStyle,
      container: container,
      alignment: alignment,
      modifiers: modifiers,
      animated: animated,
    ));
  }
}

/// A tween that interpolates between two [MarkdownCodeblockSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [MarkdownCodeblockSpec] specifications.
class MarkdownCodeblockSpecTween extends Tween<MarkdownCodeblockSpec?> {
  MarkdownCodeblockSpecTween({
    super.begin,
    super.end,
  });

  @override
  MarkdownCodeblockSpec lerp(double t) {
    if (begin == null && end == null) {
      return const MarkdownCodeblockSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}

/// A mixin that provides spec functionality for [MarkdownCheckboxSpec].
mixin _$MarkdownCheckboxSpec on Spec<MarkdownCheckboxSpec> {
  static MarkdownCheckboxSpec from(MixData mix) {
    return mix.attributeOf<MarkdownCheckboxSpecAttribute>()?.resolve(mix) ??
        const MarkdownCheckboxSpec();
  }

  /// {@template markdown_checkbox_spec_of}
  /// Retrieves the [MarkdownCheckboxSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [MarkdownCheckboxSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [MarkdownCheckboxSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final markdownCheckboxSpec = MarkdownCheckboxSpec.of(context);
  /// ```
  /// {@endtemplate}
  static MarkdownCheckboxSpec of(BuildContext context) {
    return _$MarkdownCheckboxSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [MarkdownCheckboxSpec] but with the given fields
  /// replaced with the new values.
  @override
  MarkdownCheckboxSpec copyWith({
    TextStyle? textStyle,
    IconSpec? icon,
    WidgetModifiersData? modifiers,
    AnimatedData? animated,
  }) {
    return MarkdownCheckboxSpec(
      textStyle: textStyle ?? _$this.textStyle,
      icon: icon ?? _$this.icon,
      modifiers: modifiers ?? _$this.modifiers,
      animated: animated ?? _$this.animated,
    );
  }

  /// Linearly interpolates between this [MarkdownCheckboxSpec] and another [MarkdownCheckboxSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [MarkdownCheckboxSpec] is returned. When [t] is 1.0, the [other] [MarkdownCheckboxSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [MarkdownCheckboxSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [MarkdownCheckboxSpec] instance.
  ///
  /// The interpolation is performed on each property of the [MarkdownCheckboxSpec] using the appropriate
  /// interpolation method:
  /// - [MixHelpers.lerpTextStyle] for [textStyle].
  /// - [IconSpec.lerp] for [icon].
  /// For [modifiers] and [animated], the interpolation is performed using a step function.
  /// If [t] is less than 0.5, the value from the current [MarkdownCheckboxSpec] is used. Otherwise, the value
  /// from the [other] [MarkdownCheckboxSpec] is used.
  ///
  /// This method is typically used in animations to smoothly transition between
  /// different [MarkdownCheckboxSpec] configurations.
  @override
  MarkdownCheckboxSpec lerp(MarkdownCheckboxSpec? other, double t) {
    if (other == null) return _$this;

    return MarkdownCheckboxSpec(
      textStyle: MixHelpers.lerpTextStyle(_$this.textStyle, other.textStyle, t),
      icon: _$this.icon?.lerp(other.icon, t) ?? other.icon,
      modifiers: other.modifiers,
      animated: t < 0.5 ? _$this.animated : other.animated,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownCheckboxSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownCheckboxSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.textStyle,
        _$this.icon,
        _$this.modifiers,
        _$this.animated,
      ];

  MarkdownCheckboxSpec get _$this => this as MarkdownCheckboxSpec;
}

/// Represents the attributes of a [MarkdownCheckboxSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [MarkdownCheckboxSpec].
///
/// Use this class to configure the attributes of a [MarkdownCheckboxSpec] and pass it to
/// the [MarkdownCheckboxSpec] constructor.
class MarkdownCheckboxSpecAttribute
    extends SpecAttribute<MarkdownCheckboxSpec> {
  final TextStyleDto? textStyle;
  final IconSpecAttribute? icon;

  const MarkdownCheckboxSpecAttribute({
    this.textStyle,
    this.icon,
    super.modifiers,
    super.animated,
  });

  /// Resolves to [MarkdownCheckboxSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final markdownCheckboxSpec = MarkdownCheckboxSpecAttribute(...).resolve(mix);
  /// ```
  @override
  MarkdownCheckboxSpec resolve(MixData mix) {
    return MarkdownCheckboxSpec(
      textStyle: textStyle?.resolve(mix),
      icon: icon?.resolve(mix),
      modifiers: modifiers?.resolve(mix),
      animated: animated?.resolve(mix) ?? mix.animation,
    );
  }

  /// Merges the properties of this [MarkdownCheckboxSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [MarkdownCheckboxSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  MarkdownCheckboxSpecAttribute merge(MarkdownCheckboxSpecAttribute? other) {
    if (other == null) return this;

    return MarkdownCheckboxSpecAttribute(
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      icon: icon?.merge(other.icon) ?? other.icon,
      modifiers: modifiers?.merge(other.modifiers) ?? other.modifiers,
      animated: animated?.merge(other.animated) ?? other.animated,
    );
  }

  /// The list of properties that constitute the state of this [MarkdownCheckboxSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [MarkdownCheckboxSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        textStyle,
        icon,
        modifiers,
        animated,
      ];
}

/// Utility class for configuring [MarkdownCheckboxSpec] properties.
///
/// This class provides methods to set individual properties of a [MarkdownCheckboxSpec].
/// Use the methods of this class to configure specific properties of a [MarkdownCheckboxSpec].
class MarkdownCheckboxSpecUtility<T extends Attribute>
    extends SpecUtility<T, MarkdownCheckboxSpecAttribute> {
  /// Utility for defining [MarkdownCheckboxSpecAttribute.textStyle]
  late final textStyle = TextStyleUtility((v) => only(textStyle: v));

  /// Utility for defining [MarkdownCheckboxSpecAttribute.icon]
  late final icon = IconSpecUtility((v) => only(icon: v));

  /// Utility for defining [MarkdownCheckboxSpecAttribute.modifiers]
  late final wrap = SpecModifierUtility((v) => only(modifiers: v));

  /// Utility for defining [MarkdownCheckboxSpecAttribute.animated]
  late final animated = AnimatedUtility((v) => only(animated: v));

  MarkdownCheckboxSpecUtility(super.builder, {super.mutable});

  MarkdownCheckboxSpecUtility<T> get chain =>
      MarkdownCheckboxSpecUtility(attributeBuilder, mutable: true);

  static MarkdownCheckboxSpecUtility<MarkdownCheckboxSpecAttribute> get self =>
      MarkdownCheckboxSpecUtility((v) => v);

  /// Returns a new [MarkdownCheckboxSpecAttribute] with the specified properties.
  @override
  T only({
    TextStyleDto? textStyle,
    IconSpecAttribute? icon,
    WidgetModifiersDataDto? modifiers,
    AnimatedDataDto? animated,
  }) {
    return builder(MarkdownCheckboxSpecAttribute(
      textStyle: textStyle,
      icon: icon,
      modifiers: modifiers,
      animated: animated,
    ));
  }
}

/// A tween that interpolates between two [MarkdownCheckboxSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [MarkdownCheckboxSpec] specifications.
class MarkdownCheckboxSpecTween extends Tween<MarkdownCheckboxSpec?> {
  MarkdownCheckboxSpecTween({
    super.begin,
    super.end,
  });

  @override
  MarkdownCheckboxSpec lerp(double t) {
    if (begin == null && end == null) {
      return const MarkdownCheckboxSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}

/// A mixin that provides spec functionality for [SlideSpec].
mixin _$SlideSpec on Spec<SlideSpec> {
  static SlideSpec from(MixData mix) {
    return mix.attributeOf<SlideSpecAttribute>()?.resolve(mix) ??
        const SlideSpec();
  }

  /// {@template slide_spec_of}
  /// Retrieves the [SlideSpec] from the nearest [Mix] ancestor in the widget tree.
  ///
  /// This method uses [Mix.of] to obtain the [Mix] instance associated with the
  /// given [BuildContext], and then retrieves the [SlideSpec] from that [Mix].
  /// If no ancestor [Mix] is found, this method returns an empty [SlideSpec].
  ///
  /// Example:
  ///
  /// ```dart
  /// final slideSpec = SlideSpec.of(context);
  /// ```
  /// {@endtemplate}
  static SlideSpec of(BuildContext context) {
    return _$SlideSpec.from(Mix.of(context));
  }

  /// Creates a copy of this [SlideSpec] but with the given fields
  /// replaced with the new values.
  @override
  SlideSpec copyWith({
    TextSpec? h1,
    TextSpec? h2,
    TextSpec? h3,
    TextSpec? h4,
    TextSpec? h5,
    TextSpec? h6,
    TextSpec? p,
    TextStyle? link,
    MarkdownBlockquoteSpec? blockquote,
    MarkdownListSpec? list,
    MarkdownTableSpec? table,
    MarkdownCheckboxSpec? checkbox,
    MarkdownCodeblockSpec? code,
    TextStyle? a,
    TextStyle? em,
    TextStyle? strong,
    TextStyle? del,
    TextStyle? img,
    BoxDecoration? horizontalRuleDecoration,
    TextScaler? textScaleFactor,
    BoxSpec? blockContainer,
    ImageSpec? image,
    MarkdownAlertSpec? alert,
    WidgetModifiersData? modifiers,
    AnimatedData? animated,
  }) {
    return SlideSpec(
      h1: h1 ?? _$this.h1,
      h2: h2 ?? _$this.h2,
      h3: h3 ?? _$this.h3,
      h4: h4 ?? _$this.h4,
      h5: h5 ?? _$this.h5,
      h6: h6 ?? _$this.h6,
      p: p ?? _$this.p,
      link: link ?? _$this.link,
      blockquote: blockquote ?? _$this.blockquote,
      list: list ?? _$this.list,
      table: table ?? _$this.table,
      checkbox: checkbox ?? _$this.checkbox,
      code: code ?? _$this.code,
      a: a ?? _$this.a,
      em: em ?? _$this.em,
      strong: strong ?? _$this.strong,
      del: del ?? _$this.del,
      img: img ?? _$this.img,
      horizontalRuleDecoration:
          horizontalRuleDecoration ?? _$this.horizontalRuleDecoration,
      textScaleFactor: textScaleFactor ?? _$this.textScaleFactor,
      blockContainer: blockContainer ?? _$this.blockContainer,
      image: image ?? _$this.image,
      alert: alert ?? _$this.alert,
      modifiers: modifiers ?? _$this.modifiers,
      animated: animated ?? _$this.animated,
    );
  }

  /// Linearly interpolates between this [SlideSpec] and another [SlideSpec] based on the given parameter [t].
  ///
  /// The parameter [t] represents the interpolation factor, typically ranging from 0.0 to 1.0.
  /// When [t] is 0.0, the current [SlideSpec] is returned. When [t] is 1.0, the [other] [SlideSpec] is returned.
  /// For values of [t] between 0.0 and 1.0, an interpolated [SlideSpec] is returned.
  ///
  /// If [other] is null, this method returns the current [SlideSpec] instance.
  ///
  /// The interpolation is performed on each property of the [SlideSpec] using the appropriate
  /// interpolation method:
  /// - [TextSpec.lerp] for [h1] and [h2] and [h3] and [h4] and [h5] and [h6] and [p].
  /// - [MixHelpers.lerpTextStyle] for [link] and [a] and [em] and [strong] and [del] and [img].
  /// - [MarkdownBlockquoteSpec.lerp] for [blockquote].
  /// - [MarkdownListSpec.lerp] for [list].
  /// - [MarkdownTableSpec.lerp] for [table].
  /// - [MarkdownCheckboxSpec.lerp] for [checkbox].
  /// - [MarkdownCodeblockSpec.lerp] for [code].
  /// - [BoxDecoration.lerp] for [horizontalRuleDecoration].
  /// - [BoxSpec.lerp] for [blockContainer].
  /// - [ImageSpec.lerp] for [image].
  /// - [MarkdownAlertSpec.lerp] for [alert].
  /// For [textScaleFactor] and [modifiers] and [animated], the interpolation is performed using a step function.
  /// If [t] is less than 0.5, the value from the current [SlideSpec] is used. Otherwise, the value
  /// from the [other] [SlideSpec] is used.
  ///
  /// This method is typically used in animations to smoothly transition between
  /// different [SlideSpec] configurations.
  @override
  SlideSpec lerp(SlideSpec? other, double t) {
    if (other == null) return _$this;

    return SlideSpec(
      h1: _$this.h1?.lerp(other.h1, t) ?? other.h1,
      h2: _$this.h2?.lerp(other.h2, t) ?? other.h2,
      h3: _$this.h3?.lerp(other.h3, t) ?? other.h3,
      h4: _$this.h4?.lerp(other.h4, t) ?? other.h4,
      h5: _$this.h5?.lerp(other.h5, t) ?? other.h5,
      h6: _$this.h6?.lerp(other.h6, t) ?? other.h6,
      p: _$this.p?.lerp(other.p, t) ?? other.p,
      link: MixHelpers.lerpTextStyle(_$this.link, other.link, t),
      blockquote:
          _$this.blockquote?.lerp(other.blockquote, t) ?? other.blockquote,
      list: _$this.list?.lerp(other.list, t) ?? other.list,
      table: _$this.table?.lerp(other.table, t) ?? other.table,
      checkbox: _$this.checkbox?.lerp(other.checkbox, t) ?? other.checkbox,
      code: _$this.code?.lerp(other.code, t) ?? other.code,
      a: MixHelpers.lerpTextStyle(_$this.a, other.a, t),
      em: MixHelpers.lerpTextStyle(_$this.em, other.em, t),
      strong: MixHelpers.lerpTextStyle(_$this.strong, other.strong, t),
      del: MixHelpers.lerpTextStyle(_$this.del, other.del, t),
      img: MixHelpers.lerpTextStyle(_$this.img, other.img, t),
      horizontalRuleDecoration: BoxDecoration.lerp(
          _$this.horizontalRuleDecoration, other.horizontalRuleDecoration, t),
      textScaleFactor: t < 0.5 ? _$this.textScaleFactor : other.textScaleFactor,
      blockContainer: _$this.blockContainer.lerp(other.blockContainer, t),
      image: _$this.image.lerp(other.image, t),
      alert: _$this.alert.lerp(other.alert, t),
      modifiers: other.modifiers,
      animated: t < 0.5 ? _$this.animated : other.animated,
    );
  }

  /// The list of properties that constitute the state of this [SlideSpec].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [SlideSpec] instances for equality.
  @override
  List<Object?> get props => [
        _$this.h1,
        _$this.h2,
        _$this.h3,
        _$this.h4,
        _$this.h5,
        _$this.h6,
        _$this.p,
        _$this.link,
        _$this.blockquote,
        _$this.list,
        _$this.table,
        _$this.checkbox,
        _$this.code,
        _$this.a,
        _$this.em,
        _$this.strong,
        _$this.del,
        _$this.img,
        _$this.horizontalRuleDecoration,
        _$this.textScaleFactor,
        _$this.blockContainer,
        _$this.image,
        _$this.alert,
        _$this.modifiers,
        _$this.animated,
      ];

  SlideSpec get _$this => this as SlideSpec;
}

/// Represents the attributes of a [SlideSpec].
///
/// This class encapsulates properties defining the layout and
/// appearance of a [SlideSpec].
///
/// Use this class to configure the attributes of a [SlideSpec] and pass it to
/// the [SlideSpec] constructor.
class SlideSpecAttribute extends SpecAttribute<SlideSpec> {
  final TextSpecAttribute? h1;
  final TextSpecAttribute? h2;
  final TextSpecAttribute? h3;
  final TextSpecAttribute? h4;
  final TextSpecAttribute? h5;
  final TextSpecAttribute? h6;
  final TextSpecAttribute? p;
  final TextStyleDto? link;
  final MarkdownBlockquoteSpecAttribute? blockquote;
  final MarkdownListSpecAttribute? list;
  final MarkdownTableSpecAttribute? table;
  final MarkdownCheckboxSpecAttribute? checkbox;
  final MarkdownCodeblockSpecAttribute? code;
  final TextStyleDto? a;
  final TextStyleDto? em;
  final TextStyleDto? strong;
  final TextStyleDto? del;
  final TextStyleDto? img;
  final BoxDecorationDto? horizontalRuleDecoration;
  final TextScaler? textScaleFactor;
  final BoxSpecAttribute? blockContainer;
  final ImageSpecAttribute? image;
  final MarkdownAlertSpecAttribute? alert;

  const SlideSpecAttribute({
    this.h1,
    this.h2,
    this.h3,
    this.h4,
    this.h5,
    this.h6,
    this.p,
    this.link,
    this.blockquote,
    this.list,
    this.table,
    this.checkbox,
    this.code,
    this.a,
    this.em,
    this.strong,
    this.del,
    this.img,
    this.horizontalRuleDecoration,
    this.textScaleFactor,
    this.blockContainer,
    this.image,
    this.alert,
    super.modifiers,
    super.animated,
  });

  /// Resolves to [SlideSpec] using the provided [MixData].
  ///
  /// If a property is null in the [MixData], it falls back to the
  /// default value defined in the `defaultValue` for that property.
  ///
  /// ```dart
  /// final slideSpec = SlideSpecAttribute(...).resolve(mix);
  /// ```
  @override
  SlideSpec resolve(MixData mix) {
    return SlideSpec(
      h1: h1?.resolve(mix),
      h2: h2?.resolve(mix),
      h3: h3?.resolve(mix),
      h4: h4?.resolve(mix),
      h5: h5?.resolve(mix),
      h6: h6?.resolve(mix),
      p: p?.resolve(mix),
      link: link?.resolve(mix),
      blockquote: blockquote?.resolve(mix),
      list: list?.resolve(mix),
      table: table?.resolve(mix),
      checkbox: checkbox?.resolve(mix),
      code: code?.resolve(mix),
      a: a?.resolve(mix),
      em: em?.resolve(mix),
      strong: strong?.resolve(mix),
      del: del?.resolve(mix),
      img: img?.resolve(mix),
      horizontalRuleDecoration: horizontalRuleDecoration?.resolve(mix),
      textScaleFactor: textScaleFactor,
      blockContainer: blockContainer?.resolve(mix),
      image: image?.resolve(mix),
      alert: alert?.resolve(mix),
      modifiers: modifiers?.resolve(mix),
      animated: animated?.resolve(mix) ?? mix.animation,
    );
  }

  /// Merges the properties of this [SlideSpecAttribute] with the properties of [other].
  ///
  /// If [other] is null, returns this instance unchanged. Otherwise, returns a new
  /// [SlideSpecAttribute] with the properties of [other] taking precedence over
  /// the corresponding properties of this instance.
  ///
  /// Properties from [other] that are null will fall back
  /// to the values from this instance.
  @override
  SlideSpecAttribute merge(SlideSpecAttribute? other) {
    if (other == null) return this;

    return SlideSpecAttribute(
      h1: h1?.merge(other.h1) ?? other.h1,
      h2: h2?.merge(other.h2) ?? other.h2,
      h3: h3?.merge(other.h3) ?? other.h3,
      h4: h4?.merge(other.h4) ?? other.h4,
      h5: h5?.merge(other.h5) ?? other.h5,
      h6: h6?.merge(other.h6) ?? other.h6,
      p: p?.merge(other.p) ?? other.p,
      link: link?.merge(other.link) ?? other.link,
      blockquote: blockquote?.merge(other.blockquote) ?? other.blockquote,
      list: list?.merge(other.list) ?? other.list,
      table: table?.merge(other.table) ?? other.table,
      checkbox: checkbox?.merge(other.checkbox) ?? other.checkbox,
      code: code?.merge(other.code) ?? other.code,
      a: a?.merge(other.a) ?? other.a,
      em: em?.merge(other.em) ?? other.em,
      strong: strong?.merge(other.strong) ?? other.strong,
      del: del?.merge(other.del) ?? other.del,
      img: img?.merge(other.img) ?? other.img,
      horizontalRuleDecoration:
          horizontalRuleDecoration?.merge(other.horizontalRuleDecoration) ??
              other.horizontalRuleDecoration,
      textScaleFactor: other.textScaleFactor ?? textScaleFactor,
      blockContainer:
          blockContainer?.merge(other.blockContainer) ?? other.blockContainer,
      image: image?.merge(other.image) ?? other.image,
      alert: alert?.merge(other.alert) ?? other.alert,
      modifiers: modifiers?.merge(other.modifiers) ?? other.modifiers,
      animated: animated?.merge(other.animated) ?? other.animated,
    );
  }

  /// The list of properties that constitute the state of this [SlideSpecAttribute].
  ///
  /// This property is used by the [==] operator and the [hashCode] getter to
  /// compare two [SlideSpecAttribute] instances for equality.
  @override
  List<Object?> get props => [
        h1,
        h2,
        h3,
        h4,
        h5,
        h6,
        p,
        link,
        blockquote,
        list,
        table,
        checkbox,
        code,
        a,
        em,
        strong,
        del,
        img,
        horizontalRuleDecoration,
        textScaleFactor,
        blockContainer,
        image,
        alert,
        modifiers,
        animated,
      ];
}

/// Utility class for configuring [SlideSpec] properties.
///
/// This class provides methods to set individual properties of a [SlideSpec].
/// Use the methods of this class to configure specific properties of a [SlideSpec].
class SlideSpecUtility<T extends Attribute>
    extends SpecUtility<T, SlideSpecAttribute> {
  /// Utility for defining [SlideSpecAttribute.h1]
  late final h1 = TextSpecUtility((v) => only(h1: v));

  /// Utility for defining [SlideSpecAttribute.h2]
  late final h2 = TextSpecUtility((v) => only(h2: v));

  /// Utility for defining [SlideSpecAttribute.h3]
  late final h3 = TextSpecUtility((v) => only(h3: v));

  /// Utility for defining [SlideSpecAttribute.h4]
  late final h4 = TextSpecUtility((v) => only(h4: v));

  /// Utility for defining [SlideSpecAttribute.h5]
  late final h5 = TextSpecUtility((v) => only(h5: v));

  /// Utility for defining [SlideSpecAttribute.h6]
  late final h6 = TextSpecUtility((v) => only(h6: v));

  /// Utility for defining [SlideSpecAttribute.p]
  late final p = TextSpecUtility((v) => only(p: v));

  /// Utility for defining [SlideSpecAttribute.link]
  late final link = TextStyleUtility((v) => only(link: v));

  /// Utility for defining [SlideSpecAttribute.blockquote]
  late final blockquote =
      MarkdownBlockquoteSpecUtility((v) => only(blockquote: v));

  /// Utility for defining [SlideSpecAttribute.list]
  late final list = MarkdownListSpecUtility((v) => only(list: v));

  /// Utility for defining [SlideSpecAttribute.table]
  late final table = MarkdownTableSpecUtility((v) => only(table: v));

  /// Utility for defining [SlideSpecAttribute.checkbox]
  late final checkbox = MarkdownCheckboxSpecUtility((v) => only(checkbox: v));

  /// Utility for defining [SlideSpecAttribute.code]
  late final code = MarkdownCodeblockSpecUtility((v) => only(code: v));

  /// Utility for defining [SlideSpecAttribute.a]
  late final a = TextStyleUtility((v) => only(a: v));

  /// Utility for defining [SlideSpecAttribute.em]
  late final em = TextStyleUtility((v) => only(em: v));

  /// Utility for defining [SlideSpecAttribute.strong]
  late final strong = TextStyleUtility((v) => only(strong: v));

  /// Utility for defining [SlideSpecAttribute.del]
  late final del = TextStyleUtility((v) => only(del: v));

  /// Utility for defining [SlideSpecAttribute.img]
  late final img = TextStyleUtility((v) => only(img: v));

  /// Utility for defining [SlideSpecAttribute.horizontalRuleDecoration]
  late final divider =
      BoxDecorationUtility((v) => only(horizontalRuleDecoration: v));

  /// Utility for defining [SlideSpecAttribute.textScaleFactor]
  late final textScaleFactor =
      TextScalerUtility((v) => only(textScaleFactor: v));

  /// Utility for defining [SlideSpecAttribute.blockContainer]
  late final blockContainer = BoxSpecUtility((v) => only(blockContainer: v));

  /// Utility for defining [SlideSpecAttribute.image]
  late final image = ImageSpecUtility((v) => only(image: v));

  /// Utility for defining [SlideSpecAttribute.alert]
  late final alert = MarkdownAlertSpecUtility((v) => only(alert: v));

  /// Utility for defining [SlideSpecAttribute.modifiers]
  late final wrap = SpecModifierUtility((v) => only(modifiers: v));

  /// Utility for defining [SlideSpecAttribute.animated]
  late final animated = AnimatedUtility((v) => only(animated: v));

  SlideSpecUtility(super.builder, {super.mutable});

  SlideSpecUtility<T> get chain =>
      SlideSpecUtility(attributeBuilder, mutable: true);

  static SlideSpecUtility<SlideSpecAttribute> get self =>
      SlideSpecUtility((v) => v);

  /// Returns a new [SlideSpecAttribute] with the specified properties.
  @override
  T only({
    TextSpecAttribute? h1,
    TextSpecAttribute? h2,
    TextSpecAttribute? h3,
    TextSpecAttribute? h4,
    TextSpecAttribute? h5,
    TextSpecAttribute? h6,
    TextSpecAttribute? p,
    TextStyleDto? link,
    MarkdownBlockquoteSpecAttribute? blockquote,
    MarkdownListSpecAttribute? list,
    MarkdownTableSpecAttribute? table,
    MarkdownCheckboxSpecAttribute? checkbox,
    MarkdownCodeblockSpecAttribute? code,
    TextStyleDto? a,
    TextStyleDto? em,
    TextStyleDto? strong,
    TextStyleDto? del,
    TextStyleDto? img,
    BoxDecorationDto? horizontalRuleDecoration,
    TextScaler? textScaleFactor,
    BoxSpecAttribute? blockContainer,
    ImageSpecAttribute? image,
    MarkdownAlertSpecAttribute? alert,
    WidgetModifiersDataDto? modifiers,
    AnimatedDataDto? animated,
  }) {
    return builder(SlideSpecAttribute(
      h1: h1,
      h2: h2,
      h3: h3,
      h4: h4,
      h5: h5,
      h6: h6,
      p: p,
      link: link,
      blockquote: blockquote,
      list: list,
      table: table,
      checkbox: checkbox,
      code: code,
      a: a,
      em: em,
      strong: strong,
      del: del,
      img: img,
      horizontalRuleDecoration: horizontalRuleDecoration,
      textScaleFactor: textScaleFactor,
      blockContainer: blockContainer,
      image: image,
      alert: alert,
      modifiers: modifiers,
      animated: animated,
    ));
  }
}

/// A tween that interpolates between two [SlideSpec] instances.
///
/// This class can be used in animations to smoothly transition between
/// different [SlideSpec] specifications.
class SlideSpecTween extends Tween<SlideSpec?> {
  SlideSpecTween({
    super.begin,
    super.end,
  });

  @override
  SlideSpec lerp(double t) {
    if (begin == null && end == null) {
      return const SlideSpec();
    }

    if (begin == null) {
      return end!;
    }

    return begin!.lerp(end!, t);
  }
}
