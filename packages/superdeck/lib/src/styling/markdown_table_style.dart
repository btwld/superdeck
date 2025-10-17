import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:mix/mix.dart';

import 'markdown_table_spec.dart';

/// Style class for configuring [MarkdownTableSpec] properties.
///
/// Provides a fluent API for building markdown table styles.
final class MarkdownTableStyle extends Style<MarkdownTableSpec>
    with
        Diagnosticable,
        WidgetModifierStyleMixin<MarkdownTableStyle, MarkdownTableSpec>,
        VariantStyleMixin<MarkdownTableStyle, MarkdownTableSpec>,
        AnimationStyleMixin<MarkdownTableStyle, MarkdownTableSpec> {
  final Prop<TextStyle>? $headStyle;
  final Prop<TextStyle>? $bodyStyle;
  final Prop<TextAlign>? $headAlignment;
  final Prop<EdgeInsets>? $padding;
  final Prop<TableBorder>? $border;
  final Prop<TableColumnWidth>? $columnWidth;
  final Prop<EdgeInsets>? $cellPadding;
  final Prop<BoxDecoration>? $cellDecoration;
  final Prop<TableCellVerticalAlignment>? $verticalAlignment;

  const MarkdownTableStyle.create({
    Prop<TextStyle>? headStyle,
    Prop<TextStyle>? bodyStyle,
    Prop<TextAlign>? headAlignment,
    Prop<EdgeInsets>? padding,
    Prop<TableBorder>? border,
    Prop<TableColumnWidth>? columnWidth,
    Prop<EdgeInsets>? cellPadding,
    Prop<BoxDecoration>? cellDecoration,
    Prop<TableCellVerticalAlignment>? verticalAlignment,
    required super.variants,
    required super.animation,
    required super.modifier,
  })  : $headStyle = headStyle,
        $bodyStyle = bodyStyle,
        $headAlignment = headAlignment,
        $padding = padding,
        $border = border,
        $columnWidth = columnWidth,
        $cellPadding = cellPadding,
        $cellDecoration = cellDecoration,
        $verticalAlignment = verticalAlignment;

  MarkdownTableStyle({
    TextStyle? headStyle,
    TextStyle? bodyStyle,
    TextAlign? headAlignment,
    EdgeInsets? padding,
    TableBorder? border,
    TableColumnWidth? columnWidth,
    EdgeInsets? cellPadding,
    BoxDecoration? cellDecoration,
    TableCellVerticalAlignment? verticalAlignment,
    AnimationConfig? animation,
    List<VariantStyle<MarkdownTableSpec>>? variants,
    WidgetModifierConfig? modifier,
  }) : this.create(
          headStyle: Prop.maybe(headStyle),
          bodyStyle: Prop.maybe(bodyStyle),
          headAlignment: Prop.maybe(headAlignment),
          padding: Prop.maybe(padding),
          border: Prop.maybe(border),
          columnWidth: Prop.maybe(columnWidth),
          cellPadding: Prop.maybe(cellPadding),
          cellDecoration: Prop.maybe(cellDecoration),
          verticalAlignment: Prop.maybe(verticalAlignment),
          animation: animation,
          variants: variants,
          modifier: modifier,
        );

  /// Applies variants to this style (required by VariantStyleMixin)
  @override
  MarkdownTableStyle variants(List<VariantStyle<MarkdownTableSpec>> value) {
    return merge(MarkdownTableStyle(variants: value));
  }

  /// Applies animation configuration (required by AnimationStyleMixin)
  @override
  MarkdownTableStyle animate(AnimationConfig value) {
    return merge(MarkdownTableStyle(animation: value));
  }

  /// Applies widget modifier (required by WidgetModifierStyleMixin)
  @override
  MarkdownTableStyle wrap(WidgetModifierConfig value) {
    return merge(MarkdownTableStyle(modifier: value));
  }

  @override
  StyleSpec<MarkdownTableSpec> resolve(BuildContext context) {
    return StyleSpec(
      spec: MarkdownTableSpec(
        headStyle: MixOps.resolve(context, $headStyle),
        bodyStyle: MixOps.resolve(context, $bodyStyle),
        headAlignment: MixOps.resolve(context, $headAlignment),
        padding: MixOps.resolve(context, $padding),
        border: MixOps.resolve(context, $border),
        columnWidth: MixOps.resolve(context, $columnWidth),
        cellPadding: MixOps.resolve(context, $cellPadding),
        cellDecoration: MixOps.resolve(context, $cellDecoration),
        verticalAlignment: MixOps.resolve(context, $verticalAlignment),
      ),
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  MarkdownTableStyle merge(MarkdownTableStyle? other) {
    if (other == null) return this;

    return MarkdownTableStyle.create(
      headStyle: MixOps.merge($headStyle, other.$headStyle),
      bodyStyle: MixOps.merge($bodyStyle, other.$bodyStyle),
      headAlignment: MixOps.merge($headAlignment, other.$headAlignment),
      padding: MixOps.merge($padding, other.$padding),
      border: MixOps.merge($border, other.$border),
      columnWidth: MixOps.merge($columnWidth, other.$columnWidth),
      cellPadding: MixOps.merge($cellPadding, other.$cellPadding),
      cellDecoration: MixOps.merge($cellDecoration, other.$cellDecoration),
      verticalAlignment:
          MixOps.merge($verticalAlignment, other.$verticalAlignment),
      animation: MixOps.mergeAnimation($animation, other.$animation),
      variants: MixOps.mergeVariants($variants, other.$variants),
      modifier: MixOps.mergeModifier($modifier, other.$modifier),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('headStyle', $headStyle))
      ..add(DiagnosticsProperty('bodyStyle', $bodyStyle))
      ..add(DiagnosticsProperty('headAlignment', $headAlignment))
      ..add(DiagnosticsProperty('padding', $padding))
      ..add(DiagnosticsProperty('border', $border))
      ..add(DiagnosticsProperty('columnWidth', $columnWidth))
      ..add(DiagnosticsProperty('cellPadding', $cellPadding))
      ..add(DiagnosticsProperty('cellDecoration', $cellDecoration))
      ..add(DiagnosticsProperty('verticalAlignment', $verticalAlignment));
  }

  @override
  List<Object?> get props => [
        $headStyle,
        $bodyStyle,
        $headAlignment,
        $padding,
        $border,
        $columnWidth,
        $cellPadding,
        $cellDecoration,
        $verticalAlignment,
        $animation,
        $variants,
        $modifier,
      ];
}
