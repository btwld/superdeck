// Self-references inside this deprecated compatibility surface.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// Specification for markdown text styling properties.
///
/// **Not used by the renderer.** Active text styling goes through
/// [SlideSpec]/[SlideStyle] (e.g. `p`, `h1`–`h6`, `strong`, `em`) and Mix
/// [TextStyler]s. Kept for source compatibility only.
@Deprecated(
  'MarkdownTextSpec is not wired into rendering. Use SlideStyle / SlideSpec '
  '(p, h1–h6, strong, em, del, link) with Mix TextStyler instead.',
)
final class MarkdownTextSpec extends Spec<MarkdownTextSpec>
    with Diagnosticable {
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final WrapAlignment? alignment;

  @Deprecated(
    'MarkdownTextSpec is not wired into rendering. Use SlideStyle / SlideSpec '
    'instead.',
  )
  const MarkdownTextSpec({this.textStyle, this.padding, this.alignment});

  @override
  MarkdownTextSpec copyWith({
    TextStyle? textStyle,
    EdgeInsets? padding,
    WrapAlignment? alignment,
  }) {
    return MarkdownTextSpec(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  MarkdownTextSpec lerp(MarkdownTextSpec? other, double t) {
    if (other == null) return this;

    return MarkdownTextSpec(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      padding: EdgeInsets.lerp(padding, other.padding, t),
      alignment: t < 0.5 ? alignment : other.alignment,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('textStyle', textStyle))
      ..add(DiagnosticsProperty('padding', padding))
      ..add(EnumProperty('alignment', alignment));
  }

  @override
  List<Object?> get props => [textStyle, padding, alignment];
}

/// Style class for configuring [MarkdownTextSpec] properties.
///
/// **Not used by the renderer.** Prefer [SlideStyle] / Mix [TextStyler] for
/// active styling. Kept exported for source compatibility.
@Deprecated(
  'MarkdownTextStyle is not wired into rendering. Use SlideStyle with Mix '
  'TextStyler (p, h1–h6, strong, em, del, link) instead.',
)
final class MarkdownTextStyle extends Style<MarkdownTextSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownTextStyle, MarkdownTextSpec>,
        VariantStyleMixin<MarkdownTextStyle, MarkdownTextSpec>,
        AnimationStyleMixin<MarkdownTextStyle, MarkdownTextSpec> {
  final Prop<TextStyle>? $textStyle;
  final Prop<EdgeInsets>? $padding;
  final Prop<WrapAlignment>? $alignment;

  @Deprecated(
    'MarkdownTextStyle is not wired into rendering. Use SlideStyle instead.',
  )
  const MarkdownTextStyle.create({
    Prop<TextStyle>? textStyle,
    Prop<EdgeInsets>? padding,
    Prop<WrapAlignment>? alignment,
    required super.variants,
    required super.animation,
    required super.modifier,
  }) : $textStyle = textStyle,
       $padding = padding,
       $alignment = alignment;

  @Deprecated(
    'MarkdownTextStyle is not wired into rendering. Use SlideStyle instead.',
  )
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

  @override
  MarkdownTextStyle variants(List<VariantStyle<MarkdownTextSpec>> value) {
    return merge(MarkdownTextStyle(variants: value));
  }

  @override
  MarkdownTextStyle animate(AnimationConfig value) {
    return merge(MarkdownTextStyle(animation: value));
  }

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
