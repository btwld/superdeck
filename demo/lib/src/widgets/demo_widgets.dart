import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

import '../examples/mix/animation.dart' as mix_animation;
import '../examples/mix/box_with_variants.dart' as mix_variants;
import '../examples/mix/simple_box.dart' as mix_simple_box;
import '../examples/select.dart' as naked_select;
import '../examples/button.dart' as remix_button;
import 'ack_metric_card.dart';
import 'shader_showcase.dart';

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
///
/// @ack-metric-card {
///   label: Activation
///   value: "72%"
/// }
/// ```
///
/// The QR code widget is now a built-in widget available as `@qrcode`.
Map<String, WidgetFactory> get demoWidgets => {
  'mix-simple-box': (_) => _DemoWrapper(
    child: Transform.scale(scale: 3.0, child: mix_simple_box.Example()),
  ),
  'mix-variants': (_) => _DemoWrapper(
    child: Transform.scale(scale: 3.0, child: mix_variants.Example()),
  ),
  'mix-animation': (_) => _DemoWrapper(
    child: Transform.scale(scale: 3.0, child: mix_animation.SwitchAnimation()),
  ),
  'naked-select': (_) => _DemoWrapper(
    child: Transform.scale(
      scale: 2.0,
      child: naked_select.SimpleSelectExample(),
    ),
  ),
  'remix-button': (_) => _DemoWrapper(
    child: Transform.scale(scale: 1.2, child: remix_button.ButtonExample()),
  ),
  'ack-metric-card': AckMetricCard.new,
  'shader-showcase': ShaderShowcase.fromArgs,
};

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
