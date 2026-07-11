import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// Constrained style for the framework-owned block container.
///
/// Resolves to a Mix [BoxSpec] so the existing `Box` renderer and
/// interpolation path are reused, but deliberately exposes only the surface a
/// block container owns:
///
/// - `padding` and `margin` (plus Mix spacing convenience methods);
/// - `decoration` and `foregroundDecoration` (color, gradient, border,
///   radius, shadow, and image helpers);
/// - `clipBehavior`;
/// - context and `BlockVariant` variants;
/// - Mix animation metadata.
///
/// It intentionally cannot express widget modifiers, width/height or other
/// constraints, transforms, box alignment, or widget-state variants — those
/// would create competing geometry owners with section `spacing`, block
/// `flex`, and block/section `align`. Extending this allow-list is a design
/// decision, not a convenience patch; see `.planning` notes for PR #99.
final class BlockStyler extends Style<BoxSpec>
    with
        Diagnosticable,
        SpacingStyleMixin<BlockStyler>,
        DecorationStyleMixin<BlockStyler>,
        BorderStyleMixin<BlockStyler>,
        BorderRadiusStyleMixin<BlockStyler>,
        ShadowStyleMixin<BlockStyler>,
        VariantStyleMixin<BlockStyler, BoxSpec>,
        AnimationStyleMixin<BlockStyler, BoxSpec> {
  final Prop<EdgeInsetsGeometry>? $padding;
  final Prop<EdgeInsetsGeometry>? $margin;
  final Prop<Decoration>? $decoration;
  final Prop<Decoration>? $foregroundDecoration;
  final Prop<Clip>? $clipBehavior;

  const BlockStyler.create({
    Prop<EdgeInsetsGeometry>? padding,
    Prop<EdgeInsetsGeometry>? margin,
    Prop<Decoration>? decoration,
    Prop<Decoration>? foregroundDecoration,
    Prop<Clip>? clipBehavior,
    super.variants,
    super.animation,
  }) : $padding = padding,
       $margin = margin,
       $decoration = decoration,
       $foregroundDecoration = foregroundDecoration,
       $clipBehavior = clipBehavior,
       // The block frame is framework-owned; widget modifiers stay
       // unrepresentable so no wrapper can change block geometry.
       super(modifier: null);

  BlockStyler({
    EdgeInsetsGeometryMix? padding,
    EdgeInsetsGeometryMix? margin,
    DecorationMix? decoration,
    DecorationMix? foregroundDecoration,
    Clip? clipBehavior,
    AnimationConfig? animation,
    List<VariantStyle<BoxSpec>>? variants,
  }) : this.create(
         padding: Prop.maybeMix(padding),
         margin: Prop.maybeMix(margin),
         decoration: Prop.maybeMix(decoration),
         foregroundDecoration: Prop.maybeMix(foregroundDecoration),
         clipBehavior: Prop.maybe(clipBehavior),
         variants: variants,
         animation: animation,
       );

  /// Sets the padding.
  @override
  BlockStyler padding(EdgeInsetsGeometryMix value) {
    return merge(BlockStyler(padding: value));
  }

  /// Sets the margin.
  @override
  BlockStyler margin(EdgeInsetsGeometryMix value) {
    return merge(BlockStyler(margin: value));
  }

  /// Sets the decoration.
  @override
  BlockStyler decoration(DecorationMix value) {
    return merge(BlockStyler(decoration: value));
  }

  /// Sets the foregroundDecoration.
  @override
  BlockStyler foregroundDecoration(DecorationMix value) {
    return merge(BlockStyler(foregroundDecoration: value));
  }

  /// Sets the clipBehavior.
  BlockStyler clipBehavior(Clip value) {
    return merge(BlockStyler(clipBehavior: value));
  }

  /// Sets the style variants.
  @override
  BlockStyler variants(List<VariantStyle<BoxSpec>> value) {
    return merge(BlockStyler(variants: value));
  }

  /// Sets the animation configuration.
  @override
  BlockStyler animate(AnimationConfig value) {
    return merge(BlockStyler(animation: value));
  }

  @override
  BlockStyler merge(BlockStyler? other) {
    if (other == null) return this;

    return BlockStyler.create(
      padding: MixOps.merge($padding, other.$padding),
      margin: MixOps.merge($margin, other.$margin),
      decoration: MixOps.merge($decoration, other.$decoration),
      foregroundDecoration: MixOps.merge(
        $foregroundDecoration,
        other.$foregroundDecoration,
      ),
      clipBehavior: MixOps.merge($clipBehavior, other.$clipBehavior),
      variants: MixOps.mergeVariants($variants, other.$variants),
      animation: MixOps.mergeAnimation($animation, other.$animation),
    );
  }

  @override
  StyleSpec<BoxSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: BoxSpec(
        padding: MixOps.resolve(context, $padding),
        margin: MixOps.resolve(context, $margin),
        decoration: MixOps.resolve(context, $decoration),
        foregroundDecoration: MixOps.resolve(context, $foregroundDecoration),
        clipBehavior: MixOps.resolve(context, $clipBehavior),
      ),
      animation: $animation,
      // widgetModifiers intentionally stays null for block containers.
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('padding', $padding))
      ..add(DiagnosticsProperty('margin', $margin))
      ..add(DiagnosticsProperty('decoration', $decoration))
      ..add(DiagnosticsProperty('foregroundDecoration', $foregroundDecoration))
      ..add(DiagnosticsProperty('clipBehavior', $clipBehavior));
  }

  @override
  List<Object?> get props => [
    $padding,
    $margin,
    $decoration,
    $foregroundDecoration,
    $clipBehavior,
    $animation,
    $variants,
  ];
}
