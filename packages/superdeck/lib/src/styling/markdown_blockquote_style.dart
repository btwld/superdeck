import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'markdown_blockquote_spec.dart';

/// Style class for configuring [MarkdownBlockquoteSpec] properties.
final class MarkdownBlockquoteStyle extends Style<MarkdownBlockquoteSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownBlockquoteStyle,
            MarkdownBlockquoteSpec>,
        VariantStyleMixin<MarkdownBlockquoteStyle, MarkdownBlockquoteSpec>,
        AnimationStyleMixin<MarkdownBlockquoteStyle, MarkdownBlockquoteSpec> {
  final Prop<TextStyle>? $textStyle;
  final Prop<EdgeInsets>? $padding;
  final Prop<BoxDecoration>? $decoration;
  final Prop<WrapAlignment>? $alignment;

  const MarkdownBlockquoteStyle.create({
    Prop<TextStyle>? textStyle,
    Prop<EdgeInsets>? padding,
    Prop<BoxDecoration>? decoration,
    Prop<WrapAlignment>? alignment,
    required super.variants,
    required super.animation,
    required super.modifier,
  })  : $textStyle = textStyle,
        $padding = padding,
        $decoration = decoration,
        $alignment = alignment;

  MarkdownBlockquoteStyle({
    TextStyle? textStyle,
    EdgeInsets? padding,
    BoxDecoration? decoration,
    WrapAlignment? alignment,
    AnimationConfig? animation,
    List<VariantStyle<MarkdownBlockquoteSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
          textStyle: Prop.maybe(textStyle),
          padding: Prop.maybe(padding),
          decoration: Prop.maybe(decoration),
          alignment: Prop.maybe(alignment),
          animation: animation,
          variants: variants,
          modifier: modifier,
        );

  @override
  MarkdownBlockquoteStyle variants(
      List<VariantStyle<MarkdownBlockquoteSpec>> value) {
    return merge(MarkdownBlockquoteStyle(variants: value));
  }

  @override
  MarkdownBlockquoteStyle animate(AnimationConfig value) {
    return merge(MarkdownBlockquoteStyle(animation: value));
  }

  @override
  MarkdownBlockquoteStyle wrap(WidgetModifierConfig value) {
    return merge(MarkdownBlockquoteStyle(modifier: value));
  }

  @override
  StyleSpec<MarkdownBlockquoteSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: MarkdownBlockquoteSpec(
        textStyle: MixOps.resolve(context, $textStyle),
        padding: MixOps.resolve(context, $padding),
        decoration: MixOps.resolve(context, $decoration),
        alignment: MixOps.resolve(context, $alignment),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  MarkdownBlockquoteStyle merge(MarkdownBlockquoteStyle? other) {
    if (other == null) return this;

    return MarkdownBlockquoteStyle.create(
      textStyle: MixOps.merge($textStyle, other.$textStyle),
      padding: MixOps.merge($padding, other.$padding),
      decoration: MixOps.merge($decoration, other.$decoration),
      alignment: MixOps.merge($alignment, other.$alignment),
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
      ..add(DiagnosticsProperty('padding', $padding))
      ..add(DiagnosticsProperty('decoration', $decoration))
      ..add(DiagnosticsProperty('alignment', $alignment));
  }

  @override
  List<Object?> get props => [
        $textStyle,
        $padding,
        $decoration,
        $alignment,
        $animation,
        $variants,
        $modifier,
      ];
}
