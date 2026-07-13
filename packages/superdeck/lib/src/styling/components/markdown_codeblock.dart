import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

part 'markdown_codeblock.g.dart';

/// Specification for markdown code block styling properties.
///
/// Defines styling for code blocks including text style, container, and alignment.
@MixableSpec()
@immutable
final class MarkdownCodeblockSpec with _$MarkdownCodeblockSpec {
  @override
  final TextStyle? textStyle;

  @override
  final StyleSpec<BoxSpec>? container;

  @override
  final WrapAlignment? alignment;

  const MarkdownCodeblockSpec({this.textStyle, this.container, this.alignment});
}

@Deprecated('Use MarkdownCodeblockStyler instead.')
typedef MarkdownCodeblockStyle = MarkdownCodeblockStyler;
