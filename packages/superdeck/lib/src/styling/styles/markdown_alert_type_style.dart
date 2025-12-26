import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../specs/markdown_alert_type_spec.dart';

/// Style class for configuring [MarkdownAlertTypeSpec] properties.
final class MarkdownAlertTypeStyle extends Style<MarkdownAlertTypeSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownAlertTypeStyle, MarkdownAlertTypeSpec>,
        VariantStyleMixin<MarkdownAlertTypeStyle, MarkdownAlertTypeSpec>,
        AnimationStyleMixin<MarkdownAlertTypeStyle, MarkdownAlertTypeSpec> {
  final Prop<StyleSpec<TextSpec>>? $heading;
  final Prop<StyleSpec<TextSpec>>? $description;
  final Prop<StyleSpec<IconSpec>>? $icon;
  final Prop<StyleSpec<BoxSpec>>? $container;
  final Prop<StyleSpec<FlexBoxSpec>>? $containerFlex;
  final Prop<StyleSpec<FlexBoxSpec>>? $headingFlex;

  const MarkdownAlertTypeStyle.create({
    Prop<StyleSpec<TextSpec>>? heading,
    Prop<StyleSpec<TextSpec>>? description,
    Prop<StyleSpec<IconSpec>>? icon,
    Prop<StyleSpec<BoxSpec>>? container,
    Prop<StyleSpec<FlexBoxSpec>>? containerFlex,
    Prop<StyleSpec<FlexBoxSpec>>? headingFlex,
    required super.variants,
    required super.animation,
    required super.modifier,
  }) : $heading = heading,
       $description = description,
       $icon = icon,
       $container = container,
       $containerFlex = containerFlex,
       $headingFlex = headingFlex;

  MarkdownAlertTypeStyle({
    TextStyler? heading,
    TextStyler? description,
    IconStyler? icon,
    BoxStyler? container,
    FlexBoxStyler? containerFlex,
    FlexBoxStyler? headingFlex,
    AnimationConfig? animation,
    List<VariantStyle<MarkdownAlertTypeSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
         heading: Prop.maybeMix(heading),
         description: Prop.maybeMix(description),
         icon: Prop.maybeMix(icon),
         container: Prop.maybeMix(container),
         containerFlex: Prop.maybeMix(containerFlex),
         headingFlex: Prop.maybeMix(headingFlex),
         animation: animation,
         variants: variants,
         modifier: modifier,
       );

  @override
  MarkdownAlertTypeStyle variants(
    List<VariantStyle<MarkdownAlertTypeSpec>> value,
  ) {
    return merge(MarkdownAlertTypeStyle(variants: value));
  }

  @override
  MarkdownAlertTypeStyle animate(AnimationConfig value) {
    return merge(MarkdownAlertTypeStyle(animation: value));
  }

  @override
  MarkdownAlertTypeStyle wrap(WidgetModifierConfig value) {
    return merge(MarkdownAlertTypeStyle(modifier: value));
  }

  @override
  StyleSpec<MarkdownAlertTypeSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: MarkdownAlertTypeSpec(
        heading: MixOps.resolve(context, $heading),
        description: MixOps.resolve(context, $description),
        icon: MixOps.resolve(context, $icon),
        container: MixOps.resolve(context, $container),
        containerFlex: MixOps.resolve(context, $containerFlex),
        headingFlex: MixOps.resolve(context, $headingFlex),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  MarkdownAlertTypeStyle merge(MarkdownAlertTypeStyle? other) {
    if (other == null) return this;

    return MarkdownAlertTypeStyle.create(
      heading: MixOps.merge($heading, other.$heading),
      description: MixOps.merge($description, other.$description),
      icon: MixOps.merge($icon, other.$icon),
      container: MixOps.merge($container, other.$container),
      containerFlex: MixOps.merge($containerFlex, other.$containerFlex),
      headingFlex: MixOps.merge($headingFlex, other.$headingFlex),
      animation: MixOps.mergeAnimation($animation, other.$animation),
      variants: MixOps.mergeVariants($variants, other.$variants),
      modifier: MixOps.mergeModifier($modifier, other.$modifier),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('heading', $heading))
      ..add(DiagnosticsProperty('description', $description))
      ..add(DiagnosticsProperty('icon', $icon))
      ..add(DiagnosticsProperty('container', $container))
      ..add(DiagnosticsProperty('containerFlex', $containerFlex))
      ..add(DiagnosticsProperty('headingFlex', $headingFlex));
  }

  @override
  List<Object?> get props => [
    $heading,
    $description,
    $icon,
    $container,
    $containerFlex,
    $headingFlex,
    $animation,
    $variants,
    $modifier,
  ];
}
