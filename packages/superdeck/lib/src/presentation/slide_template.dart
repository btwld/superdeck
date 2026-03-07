import 'package:flutter/foundation.dart' show mapEquals;

import '../styling/styling.dart';
import '../utils/collection_hashes.dart';
import 'slide_frame.dart';

/// A reusable slide template that bundles chrome (header, footer, background)
/// with an isolated style system.
///
/// Templates act like Keynote master slides — providing consistent visual
/// framing across slides without manually applying styles/frame to each slide.
final class SlideTemplate {
  /// Slide frame (header, footer, background) for this template.
  final SlideFrame frame;

  /// Base style applied to all slides using this template.
  final SlideStyle? baseStyle;

  /// Named style variants available within this template.
  final Map<String, SlideStyle> styles;

  const SlideTemplate({
    this.frame = const SlideFrame(),
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
  });

  SlideTemplate copyWith({
    SlideFrame? frame,
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
  }) {
    return SlideTemplate(
      frame: frame ?? this.frame,
      baseStyle: baseStyle ?? this.baseStyle,
      styles: styles ?? this.styles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideTemplate &&
          runtimeType == other.runtimeType &&
          frame == other.frame &&
          baseStyle == other.baseStyle &&
          mapEquals(styles, other.styles);

  @override
  int get hashCode => Object.hash(frame, baseStyle, unorderedMapHash(styles));
}
