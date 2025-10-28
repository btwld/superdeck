import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:remix/remix.dart';

class SDButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;

  const SDButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return RemixButton(
      onPressed: onPressed,
      style: _style,
      label: label,
      icon: icon,
    );
  }

  RemixButtonStyle get _style => RemixButtonStyle()
      .paddingAll(10)
      .iconSize(21)
      .labelFontWeight(FontWeight.w500)
      .labelFontSize(16)
      .shapeCircle()
      .scale(1)
      .shadowOnly(color: Colors.white.withValues(alpha: 0.001))
      .onHovered(
        RemixButtonStyle().shadowOnly(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      )
      .onPressed(
        RemixButtonStyle().shadowOnly(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      )
      .animate(AnimationConfig.ease(150.ms));
}
