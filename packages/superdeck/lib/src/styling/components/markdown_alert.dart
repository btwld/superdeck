import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'markdown_alert_type.dart';

// ============================================================
// SPEC
// ============================================================

/// Specification for markdown alert container with all alert types.
///
/// Defines styling for different alert types: note, tip, important, warning, and caution.
final class MarkdownAlertSpec extends Spec<MarkdownAlertSpec>
    with Diagnosticable {
  final StyleSpec<MarkdownAlertTypeSpec> note;
  final StyleSpec<MarkdownAlertTypeSpec> tip;
  final StyleSpec<MarkdownAlertTypeSpec> important;
  final StyleSpec<MarkdownAlertTypeSpec> warning;
  final StyleSpec<MarkdownAlertTypeSpec> caution;

  const MarkdownAlertSpec({
    StyleSpec<MarkdownAlertTypeSpec>? note,
    StyleSpec<MarkdownAlertTypeSpec>? tip,
    StyleSpec<MarkdownAlertTypeSpec>? important,
    StyleSpec<MarkdownAlertTypeSpec>? warning,
    StyleSpec<MarkdownAlertTypeSpec>? caution,
  }) : note = note ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
       tip = tip ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
       important = important ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
       warning = warning ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
       caution = caution ?? const StyleSpec(spec: MarkdownAlertTypeSpec());

  @override
  MarkdownAlertSpec copyWith({
    StyleSpec<MarkdownAlertTypeSpec>? note,
    StyleSpec<MarkdownAlertTypeSpec>? tip,
    StyleSpec<MarkdownAlertTypeSpec>? important,
    StyleSpec<MarkdownAlertTypeSpec>? warning,
    StyleSpec<MarkdownAlertTypeSpec>? caution,
  }) {
    return MarkdownAlertSpec(
      note: note ?? this.note,
      tip: tip ?? this.tip,
      important: important ?? this.important,
      warning: warning ?? this.warning,
      caution: caution ?? this.caution,
    );
  }

  @override
  MarkdownAlertSpec lerp(MarkdownAlertSpec? other, double t) {
    if (other == null) return this;

    return MarkdownAlertSpec(
      note: MixOps.lerp(note, other.note, t)!,
      tip: MixOps.lerp(tip, other.tip, t)!,
      important: MixOps.lerp(important, other.important, t)!,
      warning: MixOps.lerp(warning, other.warning, t)!,
      caution: MixOps.lerp(caution, other.caution, t)!,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('note', note))
      ..add(DiagnosticsProperty('tip', tip))
      ..add(DiagnosticsProperty('important', important))
      ..add(DiagnosticsProperty('warning', warning))
      ..add(DiagnosticsProperty('caution', caution));
  }

  @override
  List<Object?> get props => [note, tip, important, warning, caution];
}

// ============================================================
// STYLE
// ============================================================

/// Style class for configuring [MarkdownAlertSpec] properties.
final class MarkdownAlertStyle extends Style<MarkdownAlertSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownAlertStyle, MarkdownAlertSpec>,
        VariantStyleMixin<MarkdownAlertStyle, MarkdownAlertSpec>,
        AnimationStyleMixin<MarkdownAlertStyle, MarkdownAlertSpec> {
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $note;
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $tip;
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $important;
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $warning;
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $caution;

  const MarkdownAlertStyle.create({
    Prop<StyleSpec<MarkdownAlertTypeSpec>>? note,
    Prop<StyleSpec<MarkdownAlertTypeSpec>>? tip,
    Prop<StyleSpec<MarkdownAlertTypeSpec>>? important,
    Prop<StyleSpec<MarkdownAlertTypeSpec>>? warning,
    Prop<StyleSpec<MarkdownAlertTypeSpec>>? caution,
    required super.variants,
    required super.animation,
    required super.modifier,
  }) : $note = note,
       $tip = tip,
       $important = important,
       $warning = warning,
       $caution = caution;

  MarkdownAlertStyle({
    MarkdownAlertTypeStyle? note,
    MarkdownAlertTypeStyle? tip,
    MarkdownAlertTypeStyle? important,
    MarkdownAlertTypeStyle? warning,
    MarkdownAlertTypeStyle? caution,
    AnimationConfig? animation,
    List<VariantStyle<MarkdownAlertSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
         note: Prop.maybeMix(note),
         tip: Prop.maybeMix(tip),
         important: Prop.maybeMix(important),
         warning: Prop.maybeMix(warning),
         caution: Prop.maybeMix(caution),
         animation: animation,
         variants: variants,
         modifier: modifier,
       );

  @override
  MarkdownAlertStyle variants(List<VariantStyle<MarkdownAlertSpec>> value) {
    return merge(MarkdownAlertStyle(variants: value));
  }

  @override
  MarkdownAlertStyle animate(AnimationConfig value) {
    return merge(MarkdownAlertStyle(animation: value));
  }

  @override
  MarkdownAlertStyle wrap(WidgetModifierConfig value) {
    return merge(MarkdownAlertStyle(modifier: value));
  }

  @override
  StyleSpec<MarkdownAlertSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: MarkdownAlertSpec(
        note: MixOps.resolve(context, $note),
        tip: MixOps.resolve(context, $tip),
        important: MixOps.resolve(context, $important),
        warning: MixOps.resolve(context, $warning),
        caution: MixOps.resolve(context, $caution),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  MarkdownAlertStyle merge(MarkdownAlertStyle? other) {
    if (other == null) return this;

    return MarkdownAlertStyle.create(
      note: MixOps.merge($note, other.$note),
      tip: MixOps.merge($tip, other.$tip),
      important: MixOps.merge($important, other.$important),
      warning: MixOps.merge($warning, other.$warning),
      caution: MixOps.merge($caution, other.$caution),
      animation: MixOps.mergeAnimation($animation, other.$animation),
      variants: MixOps.mergeVariants($variants, other.$variants),
      modifier: MixOps.mergeModifier($modifier, other.$modifier),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('note', $note))
      ..add(DiagnosticsProperty('tip', $tip))
      ..add(DiagnosticsProperty('important', $important))
      ..add(DiagnosticsProperty('warning', $warning))
      ..add(DiagnosticsProperty('caution', $caution));
  }

  @override
  List<Object?> get props => [
    $note,
    $tip,
    $important,
    $warning,
    $caution,
    $animation,
    $variants,
    $modifier,
  ];
}
