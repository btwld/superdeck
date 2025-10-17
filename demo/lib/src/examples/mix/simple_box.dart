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
// ignore_for_file: unused_local_variable

library;

import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Center(child: Example()));
  }
}

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    final boxStyle =
        BoxStyler().color(Colors.cyan).size(100, 100).borderRounded(10);

    return Box(style: boxStyle);
  }
}
