import 'package:flutter/foundation.dart' show mapEquals;

import '../styling/styling.dart';
import '../utils/collection_hashes.dart';
import 'slide_parts.dart';

/// A reusable slide template that bundles chrome (header, footer, background)
/// with an isolated style system.
///
/// Templates act like Keynote master slides — providing consistent visual
/// framing across slides without manually applying styles/parts to each slide.
final class SlideTemplate {
  /// Chrome parts (header, footer, background) for this template.
  final SlideParts parts;

  /// Base style applied to all slides using this template.
  final SlideStyle? baseStyle;

  /// Named style variants available within this template.
  final Map<String, SlideStyle> styles;

  const SlideTemplate({
    this.parts = const SlideParts(),
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
  });

  SlideTemplate copyWith({
    SlideParts? parts,
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
  }) {
    return SlideTemplate(
      parts: parts ?? this.parts,
      baseStyle: baseStyle ?? this.baseStyle,
      styles: styles ?? this.styles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideTemplate &&
          runtimeType == other.runtimeType &&
          parts == other.parts &&
          baseStyle == other.baseStyle &&
          mapEquals(styles, other.styles);

  @override
  int get hashCode => Object.hash(parts, baseStyle, unorderedMapHash(styles));
}
