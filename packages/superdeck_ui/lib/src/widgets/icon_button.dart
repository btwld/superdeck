import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:remix/remix.dart';

class SDIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const SDIconButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RemixIconButton(icon: icon, onPressed: onPressed, style: _style);
  }

  RemixIconButtonStyle get _style => RemixIconButtonStyle()
      .paddingAll(10)
      .iconSize(21)
      .shapeCircle()
      .scale(1)
      .shadowOnly(color: Colors.white.withValues(alpha: 0.001))
      .onHovered(
        RemixIconButtonStyle().shadowOnly(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      )
      .onPressed(
        RemixIconButtonStyle().shadowOnly(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      )
      .animate(AnimationConfig.ease(150.ms));
}
