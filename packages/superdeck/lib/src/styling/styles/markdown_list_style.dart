import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../specs/markdown_list_spec.dart';

/// Style class for configuring [MarkdownListSpec] properties.
final class MarkdownListStyle extends Style<MarkdownListSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownListStyle, MarkdownListSpec>,
        VariantStyleMixin<MarkdownListStyle, MarkdownListSpec>,
        AnimationStyleMixin<MarkdownListStyle, MarkdownListSpec> {
  final Prop<StyleSpec<TextSpec>>? $bullet;
  final Prop<StyleSpec<TextSpec>>? $text;
  final Prop<WrapAlignment>? $orderedAlignment;
  final Prop<WrapAlignment>? $unorderedAlignment;

  const MarkdownListStyle.create({
    Prop<StyleSpec<TextSpec>>? bullet,
    Prop<StyleSpec<TextSpec>>? text,
    Prop<WrapAlignment>? orderedAlignment,
    Prop<WrapAlignment>? unorderedAlignment,
    required super.variants,
    required super.animation,
    required super.modifier,
  }) : $bullet = bullet,
       $text = text,
       $orderedAlignment = orderedAlignment,
       $unorderedAlignment = unorderedAlignment;

  MarkdownListStyle({
    TextStyler? bullet,
    TextStyler? text,
    WrapAlignment? orderedAlignment,
    WrapAlignment? unorderedAlignment,
    AnimationConfig? animation,
    List<VariantStyle<MarkdownListSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
         bullet: Prop.maybeMix(bullet),
         text: Prop.maybeMix(text),
         orderedAlignment: Prop.maybe(orderedAlignment),
         unorderedAlignment: Prop.maybe(unorderedAlignment),
         animation: animation,
         variants: variants,
         modifier: modifier,
       );

  @override
  MarkdownListStyle variants(List<VariantStyle<MarkdownListSpec>> value) {
    return merge(MarkdownListStyle(variants: value));
  }

  @override
  MarkdownListStyle animate(AnimationConfig value) {
    return merge(MarkdownListStyle(animation: value));
  }

  @override
  MarkdownListStyle wrap(WidgetModifierConfig value) {
    return merge(MarkdownListStyle(modifier: value));
  }

  @override
  StyleSpec<MarkdownListSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: MarkdownListSpec(
        bullet: MixOps.resolve(context, $bullet),
        text: MixOps.resolve(context, $text),
        orderedAlignment: MixOps.resolve(context, $orderedAlignment),
        unorderedAlignment: MixOps.resolve(context, $unorderedAlignment),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  MarkdownListStyle merge(MarkdownListStyle? other) {
    if (other == null) return this;

    return MarkdownListStyle.create(
      bullet: MixOps.merge($bullet, other.$bullet),
      text: MixOps.merge($text, other.$text),
      orderedAlignment: MixOps.merge(
        $orderedAlignment,
        other.$orderedAlignment,
      ),
      unorderedAlignment: MixOps.merge(
        $unorderedAlignment,
        other.$unorderedAlignment,
      ),
      animation: MixOps.mergeAnimation($animation, other.$animation),
      variants: MixOps.mergeVariants($variants, other.$variants),
      modifier: MixOps.mergeModifier($modifier, other.$modifier),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('bullet', $bullet))
      ..add(DiagnosticsProperty('text', $text))
      ..add(DiagnosticsProperty('orderedAlignment', $orderedAlignment))
      ..add(DiagnosticsProperty('unorderedAlignment', $unorderedAlignment));
  }

  @override
  List<Object?> get props => [
    $bullet,
    $text,
    $orderedAlignment,
    $unorderedAlignment,
    $animation,
    $variants,
    $modifier,
  ];
}
