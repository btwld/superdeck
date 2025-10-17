import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'markdown_codeblock_spec.dart';

/// Style class for configuring [MarkdownCodeblockSpec] properties.
final class MarkdownCodeblockStyle extends Style<MarkdownCodeblockSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownCodeblockStyle,
            MarkdownCodeblockSpec>,
        VariantStyleMixin<MarkdownCodeblockStyle, MarkdownCodeblockSpec>,
        AnimationStyleMixin<MarkdownCodeblockStyle, MarkdownCodeblockSpec> {
  final Prop<TextStyle>? $textStyle;
  final Prop<StyleSpec<BoxSpec>>? $container;
  final Prop<WrapAlignment>? $alignment;

  const MarkdownCodeblockStyle.create({
    Prop<TextStyle>? textStyle,
    Prop<StyleSpec<BoxSpec>>? container,
    Prop<WrapAlignment>? alignment,
    required super.variants,
    required super.animation,
    required super.modifier,
  })  : $textStyle = textStyle,
        $container = container,
        $alignment = alignment;

  MarkdownCodeblockStyle({
    TextStyle? textStyle,
    BoxStyler? container,
    WrapAlignment? alignment,
    AnimationConfig? animation,
    List<VariantStyle<MarkdownCodeblockSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
          textStyle: Prop.maybe(textStyle),
          container: Prop.maybeMix(container),
          alignment: Prop.maybe(alignment),
          animation: animation,
          variants: variants,
          modifier: modifier,
        );

  @override
  MarkdownCodeblockStyle variants(
      List<VariantStyle<MarkdownCodeblockSpec>> value) {
    return merge(MarkdownCodeblockStyle(variants: value));
  }

  @override
  MarkdownCodeblockStyle animate(AnimationConfig value) {
    return merge(MarkdownCodeblockStyle(animation: value));
  }

  @override
  MarkdownCodeblockStyle wrap(WidgetModifierConfig value) {
    return merge(MarkdownCodeblockStyle(modifier: value));
  }

  @override
  StyleSpec<MarkdownCodeblockSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: MarkdownCodeblockSpec(
        textStyle: MixOps.resolve(context, $textStyle),
        container: MixOps.resolve(context, $container),
        alignment: MixOps.resolve(context, $alignment),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  MarkdownCodeblockStyle merge(MarkdownCodeblockStyle? other) {
    if (other == null) return this;

    return MarkdownCodeblockStyle.create(
      textStyle: MixOps.merge($textStyle, other.$textStyle),
      container: MixOps.merge($container, other.$container),
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
      ..add(DiagnosticsProperty('container', $container))
      ..add(DiagnosticsProperty('alignment', $alignment));
  }

  @override
  List<Object?> get props => [
        $textStyle,
        $container,
        $alignment,
        $animation,
        $variants,
        $modifier,
      ];
}
