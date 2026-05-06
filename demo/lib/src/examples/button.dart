import 'package:flutter/material.dart';
import 'package:remix/remix.dart';

class ButtonExample extends StatelessWidget {
  const ButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          RemixButton(onPressed: () {}, label: 'Solid', style: solidStyle),
          RemixButton(onPressed: () {}, label: 'Outline', style: outlineStyle),
        ],
      ),
    );
  }

  RemixButtonStyle get baseStyle => RemixButtonStyle()
      .labelColor(Colors.white)
      .paddingAll(10)
      .labelFontWeight(FontWeight.w500)
      .minWidth(100)
      .mainAxisAlignment(MainAxisAlignment.center)
      .labelLetterSpacing(0.3)
      .borderRadiusAll(Radius.circular(6))
      .scale(1)
      .onDisabled(
        RemixButtonStyle()
            .color(Colors.grey.shade200)
            .labelColor(Colors.grey.shade500),
      )
      .onHovered(RemixButtonStyle().scale(0.95))
      .onPressed(
        RemixButtonStyle().scale(0.9).animate(AnimationConfig.easeOut(100.ms)),
      )
      .animate(AnimationConfig.easeOut(200.ms));

  RemixButtonStyle get solidStyle =>
      baseStyle.color(Colors.blueAccent.shade700);

  RemixButtonStyle get outlineStyle => baseStyle
      .borderAll(color: Colors.blueAccent.shade700.withValues(alpha: 0.7))
      .color(Colors.blueAccent.shade100.withValues(alpha: 0.15))
      .labelColor(Colors.blueAccent.shade700);
}
