/// Simple Box Example
///
/// This example demonstrates the basic usage of the Box widget with Mix styling.
/// Shows how to apply color, dimensions, and border radius to create a simple
/// styled container.
///
/// Key concepts:
/// - Using BoxStyle() to create box styles
/// - Setting color, width, and height properties
/// - Applying border radius with BorderRadiusMix

library;

import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    final boxStyle = BoxStyler()
        .color(Colors.cyan)
        .size(100, 100)
        .borderRounded(10)
        .scale(1)
        .onHovered(BoxStyler().color(Colors.blue).scale(1.1))
        .onPressed(BoxStyler().color(Colors.purple).scale(0.9))
        .animate(AnimationConfig.easeOut(200.ms));

    return Box(style: boxStyle);
  }
}
