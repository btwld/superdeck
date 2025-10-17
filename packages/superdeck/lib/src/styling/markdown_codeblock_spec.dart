import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// Specification for markdown code block styling properties.
///
/// Defines styling for code blocks including text style, container, and alignment.
final class MarkdownCodeblockSpec extends Spec<MarkdownCodeblockSpec>
    with Diagnosticable {
  final TextStyle? textStyle;
  final StyleSpec<BoxSpec>? container;
  final WrapAlignment? alignment;

  const MarkdownCodeblockSpec({
    this.textStyle,
    this.container,
    this.alignment,
  });

  @override
  MarkdownCodeblockSpec copyWith({
    TextStyle? textStyle,
    StyleSpec<BoxSpec>? container,
    WrapAlignment? alignment,
  }) {
    return MarkdownCodeblockSpec(
      textStyle: textStyle ?? this.textStyle,
      container: container ?? this.container,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  MarkdownCodeblockSpec lerp(MarkdownCodeblockSpec? other, double t) {
    if (other == null) return this;

    return MarkdownCodeblockSpec(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      container: MixOps.lerp(container, other.container, t),
      alignment: t < 0.5 ? alignment : other.alignment,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('textStyle', textStyle))
      ..add(DiagnosticsProperty('container', container))
      ..add(EnumProperty('alignment', alignment));
  }

  @override
  List<Object?> get props => [textStyle, container, alignment];
}
