import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// Specification for markdown blockquote styling properties.
///
/// Defines styling for blockquotes including text style, padding,
/// decoration, and alignment.
final class MarkdownBlockquoteSpec extends Spec<MarkdownBlockquoteSpec>
    with Diagnosticable {
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final WrapAlignment? alignment;

  const MarkdownBlockquoteSpec({
    this.textStyle,
    this.padding,
    this.decoration,
    this.alignment,
  });

  @override
  MarkdownBlockquoteSpec copyWith({
    TextStyle? textStyle,
    EdgeInsets? padding,
    BoxDecoration? decoration,
    WrapAlignment? alignment,
  }) {
    return MarkdownBlockquoteSpec(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      decoration: decoration ?? this.decoration,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  MarkdownBlockquoteSpec lerp(MarkdownBlockquoteSpec? other, double t) {
    if (other == null) return this;

    return MarkdownBlockquoteSpec(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      padding: EdgeInsets.lerp(padding, other.padding, t),
      decoration: BoxDecoration.lerp(decoration, other.decoration, t),
      alignment: t < 0.5 ? alignment : other.alignment,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('textStyle', textStyle))
      ..add(DiagnosticsProperty('padding', padding))
      ..add(DiagnosticsProperty('decoration', decoration))
      ..add(EnumProperty('alignment', alignment));
  }

  @override
  List<Object?> get props => [textStyle, padding, decoration, alignment];
}
