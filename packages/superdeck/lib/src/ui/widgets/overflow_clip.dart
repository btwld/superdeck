import 'package:flutter/widgets.dart';

/// Clips overflow in a way that avoids layout assertions during size changes.
///
/// We intentionally use `Wrap` with `clipBehavior` for non-scrollable content
/// instead of `ClipRect` to avoid overflow assertions in transitional layouts
/// (for example, hero flights where size is interpolating).
class OverflowClip extends StatelessWidget {
  const OverflowClip({super.key, required this.child, this.scrollable = false});

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(child: child);
    }

    return Wrap(clipBehavior: Clip.hardEdge, children: [child]);
  }
}
