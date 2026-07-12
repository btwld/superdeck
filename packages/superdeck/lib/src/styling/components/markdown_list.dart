import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

part 'markdown_list.g.dart';

/// Specification for markdown list styling properties.
///
/// Defines styling for ordered and unordered lists including bullet and text styles.
@MixableSpec()
@immutable
final class MarkdownListSpec with _$MarkdownListSpec {
  @override
  final StyleSpec<TextSpec>? bullet;

  @override
  final StyleSpec<TextSpec>? text;

  @override
  final WrapAlignment? orderedAlignment;

  @override
  final WrapAlignment? unorderedAlignment;

  const MarkdownListSpec({
    this.bullet,
    this.text,
    this.orderedAlignment,
    this.unorderedAlignment,
  });
}

/// Legacy alias for [MarkdownListStyler] (the pre-codegen class name).
typedef MarkdownListStyle = MarkdownListStyler;
