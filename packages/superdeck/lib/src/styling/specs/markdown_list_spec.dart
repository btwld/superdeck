import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// Specification for markdown list styling properties.
///
/// Defines styling for ordered and unordered lists including bullet and text styles.
final class MarkdownListSpec extends Spec<MarkdownListSpec>
    with Diagnosticable {
  final StyleSpec<TextSpec>? bullet;
  final StyleSpec<TextSpec>? text;
  final WrapAlignment? orderedAlignment;
  final WrapAlignment? unorderedAlignment;

  const MarkdownListSpec({
    this.bullet,
    this.text,
    this.orderedAlignment,
    this.unorderedAlignment,
  });

  @override
  MarkdownListSpec copyWith({
    StyleSpec<TextSpec>? bullet,
    StyleSpec<TextSpec>? text,
    WrapAlignment? orderedAlignment,
    WrapAlignment? unorderedAlignment,
  }) {
    return MarkdownListSpec(
      bullet: bullet ?? this.bullet,
      text: text ?? this.text,
      orderedAlignment: orderedAlignment ?? this.orderedAlignment,
      unorderedAlignment: unorderedAlignment ?? this.unorderedAlignment,
    );
  }

  @override
  MarkdownListSpec lerp(MarkdownListSpec? other, double t) {
    if (other == null) return this;

    return MarkdownListSpec(
      bullet: MixOps.lerp(bullet, other.bullet, t),
      text: MixOps.lerp(text, other.text, t),
      orderedAlignment: t < 0.5 ? orderedAlignment : other.orderedAlignment,
      unorderedAlignment: t < 0.5
          ? unorderedAlignment
          : other.unorderedAlignment,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('bullet', bullet))
      ..add(DiagnosticsProperty('text', text))
      ..add(EnumProperty('orderedAlignment', orderedAlignment))
      ..add(EnumProperty('unorderedAlignment', unorderedAlignment));
  }

  @override
  List<Object?> get props => [
    bullet,
    text,
    orderedAlignment,
    unorderedAlignment,
  ];
}
