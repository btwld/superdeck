import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'markdown_text_spec.dart';

/// Style class for configuring [MarkdownTextSpec] properties.
///
/// Provides a fluent API for building markdown text styles with support
/// for animations, variants, and widget modifiers.
final class MarkdownTextStyle extends Style<MarkdownTextSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownTextStyle, MarkdownTextSpec>,
        VariantStyleMixin<MarkdownTextStyle, MarkdownTextSpec>,
        AnimationStyleMixin<MarkdownTextStyle, MarkdownTextSpec> {
  final Prop<TextStyle>? $textStyle;
  final Prop<EdgeInsets>? $padding;
  final Prop<WrapAlignment>? $alignment;

  const MarkdownTextStyle.create({
    Prop<TextStyle>? textStyle,
    Prop<EdgeInsets>? padding,
    Prop<WrapAlignment>? alignment,
    required super.variants,
    required super.animation,
    required super.modifier,
  })  : $textStyle = textStyle,
        $padding = padding,
        $alignment = alignment;

  MarkdownTextStyle({
    TextStyle? textStyle,
    EdgeInsets? padding,
    WrapAlignment? alignment,
    AnimationConfig? animation,
    List<VariantStyle<MarkdownTextSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
          textStyle: Prop.maybe(textStyle),
          padding: Prop.maybe(padding),
          alignment: Prop.maybe(alignment),
          animation: animation,
          variants: variants,
          modifier: modifier,
        );

  /// Sets text style
  MarkdownTextStyle textStyle(TextStyle value) {
    return merge(MarkdownTextStyle(textStyle: value));
  }

  /// Sets padding
  MarkdownTextStyle padding(EdgeInsets value) {
    return merge(MarkdownTextStyle(padding: value));
  }

  /// Sets alignment
  MarkdownTextStyle alignment(WrapAlignment value) {
    return merge(MarkdownTextStyle(alignment: value));
  }

  /// Applies variants to this style (required by VariantStyleMixin)
  @override
  MarkdownTextStyle variants(List<VariantStyle<MarkdownTextSpec>> value) {
    return merge(MarkdownTextStyle(variants: value));
  }

  /// Applies animation configuration (required by AnimationStyleMixin)
  @override
  MarkdownTextStyle animate(AnimationConfig value) {
    return merge(MarkdownTextStyle(animation: value));
  }

  /// Applies widget modifier (required by WidgetModifierStyleMixin)
  @override
  MarkdownTextStyle wrap(WidgetModifierConfig value) {
    return merge(MarkdownTextStyle(modifier: value));
  }

  @override
  StyleSpec<MarkdownTextSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: MarkdownTextSpec(
        textStyle: MixOps.resolve(context, $textStyle),
        padding: MixOps.resolve(context, $padding),
        alignment: MixOps.resolve(context, $alignment),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  MarkdownTextStyle merge(MarkdownTextStyle? other) {
    if (other == null) return this;

    return MarkdownTextStyle.create(
      textStyle: MixOps.merge($textStyle, other.$textStyle),
      padding: MixOps.merge($padding, other.$padding),
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
      ..add(DiagnosticsProperty('alignment', $alignment));
  }

  @override
  List<Object?> get props => [
        $textStyle,
        $padding,
        $alignment,
        $animation,
        $variants,
        $modifier,
      ];
}
