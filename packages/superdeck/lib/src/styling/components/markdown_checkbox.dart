import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

// ============================================================
// SPEC
// ============================================================

/// Specification for markdown checkbox styling properties.
///
/// Defines styling for checkbox elements including text style and icon.
final class MarkdownCheckboxSpec extends Spec<MarkdownCheckboxSpec>
    with Diagnosticable {
  final TextStyle? textStyle;
  final StyleSpec<IconSpec>? icon;

  const MarkdownCheckboxSpec({this.textStyle, this.icon});

  @override
  MarkdownCheckboxSpec copyWith({
    TextStyle? textStyle,
    StyleSpec<IconSpec>? icon,
  }) {
    return MarkdownCheckboxSpec(
      textStyle: textStyle ?? this.textStyle,
      icon: icon ?? this.icon,
    );
  }

  @override
  MarkdownCheckboxSpec lerp(MarkdownCheckboxSpec? other, double t) {
    if (other == null) return this;

    return MarkdownCheckboxSpec(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      icon: MixOps.lerp(icon, other.icon, t),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('textStyle', textStyle))
      ..add(DiagnosticsProperty('icon', icon));
  }

  @override
  List<Object?> get props => [textStyle, icon];
}

// ============================================================
// STYLE
// ============================================================

/// Style class for configuring [MarkdownCheckboxSpec] properties.
final class MarkdownCheckboxStyle extends Style<MarkdownCheckboxSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownCheckboxStyle, MarkdownCheckboxSpec>,
        VariantStyleMixin<MarkdownCheckboxStyle, MarkdownCheckboxSpec>,
        AnimationStyleMixin<MarkdownCheckboxStyle, MarkdownCheckboxSpec> {
  final Prop<TextStyle>? $textStyle;
  final Prop<StyleSpec<IconSpec>>? $icon;

  const MarkdownCheckboxStyle.create({
    Prop<TextStyle>? textStyle,
    Prop<StyleSpec<IconSpec>>? icon,
    required super.variants,
    required super.animation,
    required super.modifier,
  }) : $textStyle = textStyle,
       $icon = icon;

  MarkdownCheckboxStyle({
    TextStyle? textStyle,
    IconStyler? icon,
    AnimationConfig? animation,
    List<VariantStyle<MarkdownCheckboxSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
         textStyle: Prop.maybe(textStyle),
         icon: Prop.maybeMix(icon),
         animation: animation,
         variants: variants,
         modifier: modifier,
       );

  @override
  MarkdownCheckboxStyle variants(
    List<VariantStyle<MarkdownCheckboxSpec>> value,
  ) {
    return merge(MarkdownCheckboxStyle(variants: value));
  }

  @override
  MarkdownCheckboxStyle animate(AnimationConfig value) {
    return merge(MarkdownCheckboxStyle(animation: value));
  }

  @override
  MarkdownCheckboxStyle wrap(WidgetModifierConfig value) {
    return merge(MarkdownCheckboxStyle(modifier: value));
  }

  @override
  StyleSpec<MarkdownCheckboxSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: MarkdownCheckboxSpec(
        textStyle: MixOps.resolve(context, $textStyle),
        icon: MixOps.resolve(context, $icon),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  MarkdownCheckboxStyle merge(MarkdownCheckboxStyle? other) {
    if (other == null) return this;

    return MarkdownCheckboxStyle.create(
      textStyle: MixOps.merge($textStyle, other.$textStyle),
      icon: MixOps.merge($icon, other.$icon),
      animation: MixOps.mergeAnimation($animation, other.$animation),
      variants: MixOps.mergeVariants($variants, other.$variants),
      modifier: MixOps.mergeModifier($modifier, other.$modifier),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('textStyle', $textStyle))
      ..add(DiagnosticsProperty('icon', $icon));
  }

  @override
  List<Object?> get props => [
    $textStyle,
    $icon,
    $animation,
    $variants,
    $modifier,
  ];
}
