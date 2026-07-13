import 'package:dart_mappable/dart_mappable.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/components/slide.dart';

part 'slide_template.mapper.dart';

/// A reusable slide template that bundles chrome (header, footer, background)
/// with an isolated style system.
///
/// Templates act like Keynote master slides — providing consistent visual
/// framing across slides without manually applying styles/parts to each slide.
@MappableClass()
final class SlideTemplate with SlideTemplateMappable {
  /// Chrome parts (header, footer, background) for this template.
  final SlideParts parts;

  /// Base style applied to all slides using this template.
  final SlideStyler? baseStyle;

  /// Named style variants available within this template.
  final Map<String, SlideStyler> styles;

  const SlideTemplate({
    this.parts = const SlideParts(),
    this.baseStyle,
    this.styles = const <String, SlideStyler>{},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideTemplate &&
          runtimeType == other.runtimeType &&
          parts == other.parts &&
          baseStyle == other.baseStyle &&
          styles == other.styles;

  @override
  int get hashCode => Object.hash(parts, baseStyle, styles);
}
