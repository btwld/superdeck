import 'package:flutter/material.dart';
import 'package:superdeck/superdeck.dart';

import '../examples/mix/animation.dart' as mix_animation;
import '../examples/mix/box_with_variants.dart' as mix_variants;
import '../examples/mix/simple_box.dart' as mix_simple_box;
import '../examples/select.dart' as naked_select;
import '../examples/button.dart' as remix_button;

/// Auto-registered demo widgets for Superdeck presentations.
///
/// This map contains all demo widgets from the examples folder.
///
/// Usage in slides.md:
/// ```markdown
/// @mix-simple-box
///
/// @naked-select
///
/// @remix-button
/// ```
///
/// Note: The QR code widget is now a built-in widget available as @qrcode
Map<String, WidgetDefinition> get demoWidgets => {
      // Mix examples - wrapped in simple widget definitions
      'mix-simple-box': _SimpleWidgetDefinition(
        (context, args) => _DemoWrapper(
          child: Transform.scale(scale: 3.0, child: mix_simple_box.Example()),
        ),
      ),
      'mix-variants': _SimpleWidgetDefinition(
        (context, args) => _DemoWrapper(
          child: Transform.scale(scale: 3.0, child: mix_variants.Example()),
        ),
      ),
      'mix-animation': _SimpleWidgetDefinition(
        (context, args) => _DemoWrapper(
          child: Transform.scale(
            scale: 3.0,
            child: mix_animation.SwitchAnimation(),
          ),
        ),
      ),

      // Naked UI examples
      'naked-select': _SimpleWidgetDefinition(
        (context, args) => _DemoWrapper(
          child: Transform.scale(
            scale: 2.0,
            child: naked_select.SimpleSelectExample(),
          ),
        ),
      ),

      // Remix examples
      'remix-button': _SimpleWidgetDefinition(
        (context, args) => _DemoWrapper(
          child: Transform.scale(scale: 1.2, child: remix_button.ButtonExample()),
        ),
      ),
    };

/// Simple widget definition for widgets without schemas.
///
/// Used for demo widgets that don't need argument validation.
/// Uses raw `Map<String, Object?>` as the argument type (no parsing).
class _SimpleWidgetDefinition extends WidgetDefinition<Map<String, Object?>> {
  final Widget Function(BuildContext context, Map<String, Object?> args)
      _builder;

  const _SimpleWidgetDefinition(this._builder);

  @override
  Map<String, Object?> parse(Map<String, Object?> args) {
    // No validation - just pass through
    return args;
  }

  @override
  Widget build(BuildContext context, Map<String, Object?> args) {
    return _builder(context, args);
  }
}

/// Wrapper widget that constrains demo widgets to their intrinsic size.
///
/// This ensures demos stay compact and centered within their column,
/// rather than expanding to fill all available space.
class _DemoWrapper extends StatelessWidget {
  final Widget child;

  const _DemoWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IntrinsicWidth(child: IntrinsicHeight(child: child)),
    );
  }
}
