import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:mix/mix.dart';

/// Specification for markdown table styling properties.
///
/// Defines styling for tables including head/body text styles, alignment,
/// borders, padding, and cell decorations.
final class MarkdownTableSpec extends Spec<MarkdownTableSpec>
    with Diagnosticable {
  final TextStyle? headStyle;
  final TextStyle? bodyStyle;
  final TextAlign? headAlignment;
  final EdgeInsets? padding;
  final TableBorder? border;
  final TableColumnWidth? columnWidth;
  final EdgeInsets? cellPadding;
  final BoxDecoration? cellDecoration;
  final TableCellVerticalAlignment? verticalAlignment;

  const MarkdownTableSpec({
    this.headStyle,
    this.bodyStyle,
    this.headAlignment,
    this.padding,
    this.border,
    this.columnWidth,
    this.cellPadding,
    this.cellDecoration,
    this.verticalAlignment,
  });

  @override
  MarkdownTableSpec copyWith({
    TextStyle? headStyle,
    TextStyle? bodyStyle,
    TextAlign? headAlignment,
    EdgeInsets? padding,
    TableBorder? border,
    TableColumnWidth? columnWidth,
    EdgeInsets? cellPadding,
    BoxDecoration? cellDecoration,
    TableCellVerticalAlignment? verticalAlignment,
  }) {
    return MarkdownTableSpec(
      headStyle: headStyle ?? this.headStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      headAlignment: headAlignment ?? this.headAlignment,
      padding: padding ?? this.padding,
      border: border ?? this.border,
      columnWidth: columnWidth ?? this.columnWidth,
      cellPadding: cellPadding ?? this.cellPadding,
      cellDecoration: cellDecoration ?? this.cellDecoration,
      verticalAlignment: verticalAlignment ?? this.verticalAlignment,
    );
  }

  @override
  MarkdownTableSpec lerp(MarkdownTableSpec? other, double t) {
    if (other == null) return this;

    return MarkdownTableSpec(
      headStyle: TextStyle.lerp(headStyle, other.headStyle, t),
      bodyStyle: TextStyle.lerp(bodyStyle, other.bodyStyle, t),
      headAlignment: t < 0.5 ? headAlignment : other.headAlignment,
      padding: EdgeInsets.lerp(padding, other.padding, t),
      border: t < 0.5 ? border : other.border,
      columnWidth: t < 0.5 ? columnWidth : other.columnWidth,
      cellPadding: EdgeInsets.lerp(cellPadding, other.cellPadding, t),
      cellDecoration: BoxDecoration.lerp(
        cellDecoration,
        other.cellDecoration,
        t,
      ),
      verticalAlignment: t < 0.5 ? verticalAlignment : other.verticalAlignment,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('headStyle', headStyle))
      ..add(DiagnosticsProperty('bodyStyle', bodyStyle))
      ..add(EnumProperty('headAlignment', headAlignment))
      ..add(DiagnosticsProperty('padding', padding))
      ..add(DiagnosticsProperty('border', border))
      ..add(DiagnosticsProperty('columnWidth', columnWidth))
      ..add(DiagnosticsProperty('cellPadding', cellPadding))
      ..add(DiagnosticsProperty('cellDecoration', cellDecoration))
      ..add(EnumProperty('verticalAlignment', verticalAlignment));
  }

  @override
  List<Object?> get props => [
    headStyle,
    bodyStyle,
    headAlignment,
    padding,
    border,
    columnWidth,
    cellPadding,
    cellDecoration,
    verticalAlignment,
  ];
}
