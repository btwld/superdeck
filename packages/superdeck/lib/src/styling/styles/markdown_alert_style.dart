import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../specs/markdown_alert_spec.dart';
import '../specs/markdown_alert_type_spec.dart';
import 'markdown_alert_type_style.dart';

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
