import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

part 'markdown_table.g.dart';

/// Specification for markdown table styling properties.
///
/// Defines styling for tables including head/body text styles, alignment,
/// borders, padding, and cell decorations.
@MixableSpec()
@immutable
final class MarkdownTableSpec with _$MarkdownTableSpec {
  @override
  final TextStyle? headStyle;
  @override
  final TextStyle? bodyStyle;
  @override
  final TextAlign? headAlignment;
  @override
  final EdgeInsets? padding;
  @override
  final TableBorder? border;
  @override
  final TableColumnWidth? columnWidth;
  @override
  final EdgeInsets? cellPadding;
  @override
  final BoxDecoration? cellDecoration;
  @override
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
}

@Deprecated('Use MarkdownTableStyler instead.')
typedef MarkdownTableStyle = MarkdownTableStyler;
