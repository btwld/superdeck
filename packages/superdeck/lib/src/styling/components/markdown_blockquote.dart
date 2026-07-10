import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

part 'markdown_blockquote.g.dart';

/// Specification for markdown blockquote styling properties.
///
/// Defines styling for blockquotes including text style, padding,
/// decoration, and alignment.
@MixableSpec()
@immutable
final class MarkdownBlockquoteSpec with _$MarkdownBlockquoteSpec {
  @override
  final TextStyle? textStyle;
  @override
  final EdgeInsets? padding;
  @override
  final BoxDecoration? decoration;
  @override
  final WrapAlignment? alignment;

  const MarkdownBlockquoteSpec({
    this.textStyle,
    this.padding,
    this.decoration,
    this.alignment,
  });
}

/// Legacy alias for [MarkdownBlockquoteStyler] (the pre-codegen class name).
typedef MarkdownBlockquoteStyle = MarkdownBlockquoteStyler;
