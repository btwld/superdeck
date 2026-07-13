import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:mix_annotations/mix_annotations.dart';

import 'markdown_alert_type.dart';

part 'markdown_alert.g.dart';

/// Specification for markdown alert container with all alert types.
///
/// Defines styling for different alert types: note, tip, important, warning, and caution.
@MixableSpec()
@immutable
final class MarkdownAlertSpec with _$MarkdownAlertSpec {
  @override
  final StyleSpec<MarkdownAlertTypeSpec> note;
  @override
  final StyleSpec<MarkdownAlertTypeSpec> tip;
  @override
  final StyleSpec<MarkdownAlertTypeSpec> important;
  @override
  final StyleSpec<MarkdownAlertTypeSpec> warning;
  @override
  final StyleSpec<MarkdownAlertTypeSpec> caution;

  const MarkdownAlertSpec({
    StyleSpec<MarkdownAlertTypeSpec>? note,
    StyleSpec<MarkdownAlertTypeSpec>? tip,
    StyleSpec<MarkdownAlertTypeSpec>? important,
    StyleSpec<MarkdownAlertTypeSpec>? warning,
    StyleSpec<MarkdownAlertTypeSpec>? caution,
  }) : note = note ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
       tip = tip ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
       important = important ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
       warning = warning ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
       caution = caution ?? const StyleSpec(spec: MarkdownAlertTypeSpec());
}
