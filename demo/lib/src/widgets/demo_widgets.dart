import 'package:flutter/material.dart';
import 'package:superdeck/superdeck.dart';

import '../examples/mix/animation.dart' as mix_animation;
import '../examples/mix/box_with_variants.dart' as mix_variants;
import '../examples/mix/simple_box.dart' as mix_simple_box;
import '../examples/select.dart' as naked_select;
import '../examples/button.dart' as remix_button;

/// Auto-registered demo widgets for Superdeck presentations.
///
/// This map contains all demo widgets from the examples folder,
/// wrapped appropriately for display within slides.
///
/// Usage in slides.md:
/// ```markdown
/// @mix-simple-box
///
/// @naked-select
///
/// @remix-button
/// ```
Map<String, WidgetBlockBuilder> get demoWidgets => {
      // Mix examples
      'mix-simple-box': (args) => _DemoWrapper(
            child: Transform.scale(
              scale: 3.0,
              child: mix_simple_box.Example(),
            ),
          ),
      'mix-variants': (args) => _DemoWrapper(
            child: Transform.scale(
              scale: 3.0,
              child: mix_variants.Example(),
            ),
          ),
      'mix-animation': (args) => _DemoWrapper(
            child: Transform.scale(
              scale: 3.0,
              child: mix_animation.SwitchAnimation(),
            ),
          ),

      // Naked UI examples
      'naked-select': (args) => _DemoWrapper(
            child: Transform.scale(
              scale: 2.0,
              child: naked_select.SimpleSelectExample(),
            ),
          ),

      // Remix examples
      'remix-button': (args) => _DemoWrapper(
            child: Transform.scale(
              scale: 1.2,
              child: remix_button.ButtonExample(),
            ),
          ),
    };

/// Wrapper widget that constrains demo widgets to their intrinsic size.
///
/// This ensures demos stay compact and centered within their column,
/// rather than expanding to fill all available space.
class _DemoWrapper extends StatelessWidget {
  final Widget child;

  const _DemoWrapper({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: child,
        ),
      ),
    );
  }
}
