import 'package:flutter/widgets.dart';

class RenderConfig {
  final double pixelRatio;
  final BuildContext context;
  final Size? targetSize;
  final int minimumRenderPasses;

  const RenderConfig({
    required this.pixelRatio,
    required this.context,
    this.targetSize,
    this.minimumRenderPasses = 0,
  });
}
