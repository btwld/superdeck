import 'package:flutter/widgets.dart';

/// Simple configuration object for widget-to-image rendering
/// Reduces parameter passing and improves readability (KISS principle)
class RenderConfig {
  final double pixelRatio;
  final BuildContext context;
  final Size? targetSize;

  const RenderConfig({
    required this.pixelRatio,
    required this.context,
    this.targetSize,
  });

  /// Creates a copy with optional parameter overrides
  RenderConfig copyWith({
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) {
    return RenderConfig(
      pixelRatio: pixelRatio ?? this.pixelRatio,
      context: context ?? this.context,
      targetSize: targetSize ?? this.targetSize,
    );
  }
}
