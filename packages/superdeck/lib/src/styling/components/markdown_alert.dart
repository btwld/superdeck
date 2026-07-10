// The styler below stays hand-written on the legacy @MixableStyler mixin
// path: its fields nest same-package generated stylers
// (MarkdownAlertTypeStyler), which @MixableSpec's spec_styler_generator can
// only wire up through @MixableField(setterType:) — and annotation type
// arguments cannot reference same-package generated classes (build phases
// hide them from the resolver, degrading silently to value semantics).
// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

import 'markdown_alert_type.dart';

part 'markdown_alert.g.dart';

/// Specification for markdown alert container with all alert types.
///
/// Defines styling for different alert types: note, tip, important, warning, and caution.
@MixableSpec()
@immutable
final class MarkdownAlertSpec with _$MarkdownAlertSpec {
  @override
  final StyleSpec<MarkdownAlertTypeSpec> note;
  @override
  final StyleSpec<MarkdownAlertTypeSpec> tip;
  @override
  final StyleSpec<MarkdownAlertTypeSpec> important;
  @override
  final StyleSpec<MarkdownAlertTypeSpec> warning;
  @override
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
}

/// Style class for configuring [MarkdownAlertSpec] properties.
@MixableStyler()
final class MarkdownAlertStyler
    extends MixStyler<MarkdownAlertStyler, MarkdownAlertSpec>
    with _$MarkdownAlertStylerMixin {
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $note;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $tip;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $important;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $warning;
  @override
  @MixableField(ignoreSetter: true)
  final Prop<StyleSpec<MarkdownAlertTypeSpec>>? $caution;

  const MarkdownAlertStyler.create({
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

  MarkdownAlertStyler({
    MarkdownAlertTypeStyler? note,
    MarkdownAlertTypeStyler? tip,
    MarkdownAlertTypeStyler? important,
    MarkdownAlertTypeStyler? warning,
    MarkdownAlertTypeStyler? caution,
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

  /// Sets the note alert style.
  MarkdownAlertStyler note(MarkdownAlertTypeStyler value) {
    return merge(MarkdownAlertStyler(note: value));
  }

  /// Sets the tip alert style.
  MarkdownAlertStyler tip(MarkdownAlertTypeStyler value) {
    return merge(MarkdownAlertStyler(tip: value));
  }

  /// Sets the important alert style.
  MarkdownAlertStyler important(MarkdownAlertTypeStyler value) {
    return merge(MarkdownAlertStyler(important: value));
  }

  /// Sets the warning alert style.
  MarkdownAlertStyler warning(MarkdownAlertTypeStyler value) {
    return merge(MarkdownAlertStyler(warning: value));
  }

  /// Sets the caution alert style.
  MarkdownAlertStyler caution(MarkdownAlertTypeStyler value) {
    return merge(MarkdownAlertStyler(caution: value));
  }
}

/// Legacy alias for [MarkdownAlertStyler] (the pre-codegen class name).
typedef MarkdownAlertStyle = MarkdownAlertStyler;
