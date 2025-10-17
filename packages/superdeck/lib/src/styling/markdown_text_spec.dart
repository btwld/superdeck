import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// Specification for markdown text styling properties.
///
/// Defines styling for regular markdown text including text style,
/// padding, and alignment.
final class MarkdownTextSpec extends Spec<MarkdownTextSpec>
    with Diagnosticable {
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final WrapAlignment? alignment;

  const MarkdownTextSpec({
    this.textStyle,
    this.padding,
    this.alignment,
  });

  @override
  MarkdownTextSpec copyWith({
    TextStyle? textStyle,
    EdgeInsets? padding,
    WrapAlignment? alignment,
  }) {
    return MarkdownTextSpec(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  MarkdownTextSpec lerp(MarkdownTextSpec? other, double t) {
    if (other == null) return this;

    return MarkdownTextSpec(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      padding: EdgeInsets.lerp(padding, other.padding, t),
      alignment: t < 0.5 ? alignment : other.alignment,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('textStyle', textStyle))
      ..add(DiagnosticsProperty('padding', padding))
      ..add(EnumProperty('alignment', alignment));
  }

  @override
  List<Object?> get props => [textStyle, padding, alignment];
}
