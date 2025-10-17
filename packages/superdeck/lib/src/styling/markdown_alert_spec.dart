import 'package:flutter/foundation.dart';
import 'package:mix/mix.dart';

import 'markdown_alert_type_spec.dart';

/// Specification for markdown alert container with all alert types.
///
/// Defines styling for different alert types: note, tip, important, warning, and caution.
final class MarkdownAlertSpec extends Spec<MarkdownAlertSpec>
    with Diagnosticable {
  final StyleSpec<MarkdownAlertTypeSpec> note;
  final StyleSpec<MarkdownAlertTypeSpec> tip;
  final StyleSpec<MarkdownAlertTypeSpec> important;
  final StyleSpec<MarkdownAlertTypeSpec> warning;
  final StyleSpec<MarkdownAlertTypeSpec> caution;

  const MarkdownAlertSpec({
    StyleSpec<MarkdownAlertTypeSpec>? note,
    StyleSpec<MarkdownAlertTypeSpec>? tip,
    StyleSpec<MarkdownAlertTypeSpec>? important,
    StyleSpec<MarkdownAlertTypeSpec>? warning,
    StyleSpec<MarkdownAlertTypeSpec>? caution,
  })  : note = note ??
            const StyleSpec(spec: MarkdownAlertTypeSpec()),
        tip = tip ?? const StyleSpec(spec: MarkdownAlertTypeSpec()),
        important = important ??
            const StyleSpec(spec: MarkdownAlertTypeSpec()),
        warning = warning ??
            const StyleSpec(spec: MarkdownAlertTypeSpec()),
        caution = caution ??
            const StyleSpec(spec: MarkdownAlertTypeSpec());

  @override
  MarkdownAlertSpec copyWith({
    StyleSpec<MarkdownAlertTypeSpec>? note,
    StyleSpec<MarkdownAlertTypeSpec>? tip,
    StyleSpec<MarkdownAlertTypeSpec>? important,
    StyleSpec<MarkdownAlertTypeSpec>? warning,
    StyleSpec<MarkdownAlertTypeSpec>? caution,
  }) {
    return MarkdownAlertSpec(
      note: note ?? this.note,
      tip: tip ?? this.tip,
      important: important ?? this.important,
      warning: warning ?? this.warning,
      caution: caution ?? this.caution,
    );
  }

  @override
  MarkdownAlertSpec lerp(MarkdownAlertSpec? other, double t) {
    if (other == null) return this;

    return MarkdownAlertSpec(
      note: MixOps.lerp(note, other.note, t)!,
      tip: MixOps.lerp(tip, other.tip, t)!,
      important: MixOps.lerp(important, other.important, t)!,
      warning: MixOps.lerp(warning, other.warning, t)!,
      caution: MixOps.lerp(caution, other.caution, t)!,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('note', note))
      ..add(DiagnosticsProperty('tip', tip))
      ..add(DiagnosticsProperty('important', important))
      ..add(DiagnosticsProperty('warning', warning))
      ..add(DiagnosticsProperty('caution', caution));
  }

  @override
  List<Object?> get props => [note, tip, important, warning, caution];
}
