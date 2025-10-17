import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// Specification for markdown checkbox styling properties.
///
/// Defines styling for checkbox elements including text style and icon.
final class MarkdownCheckboxSpec extends Spec<MarkdownCheckboxSpec>
    with Diagnosticable {
  final TextStyle? textStyle;
  final StyleSpec<IconSpec>? icon;

  const MarkdownCheckboxSpec({
    this.textStyle,
    this.icon,
  });

  @override
  MarkdownCheckboxSpec copyWith({
    TextStyle? textStyle,
    StyleSpec<IconSpec>? icon,
  }) {
    return MarkdownCheckboxSpec(
      textStyle: textStyle ?? this.textStyle,
      icon: icon ?? this.icon,
    );
  }

  @override
  MarkdownCheckboxSpec lerp(MarkdownCheckboxSpec? other, double t) {
    if (other == null) return this;

    return MarkdownCheckboxSpec(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      icon: MixOps.lerp(icon, other.icon, t),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('textStyle', textStyle))
      ..add(DiagnosticsProperty('icon', icon));
  }

  @override
  List<Object?> get props => [textStyle, icon];
}
