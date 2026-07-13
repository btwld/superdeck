import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

part 'markdown_checkbox.g.dart';

/// Specification for markdown checkbox styling properties.
///
/// Defines styling for checkbox elements including text style and icon.
@MixableSpec()
@immutable
final class MarkdownCheckboxSpec with _$MarkdownCheckboxSpec {
  @override
  final TextStyle? textStyle;

  @override
  final StyleSpec<IconSpec>? icon;

  const MarkdownCheckboxSpec({this.textStyle, this.icon});
}

@Deprecated('Use MarkdownCheckboxStyler instead.')
typedef MarkdownCheckboxStyle = MarkdownCheckboxStyler;
