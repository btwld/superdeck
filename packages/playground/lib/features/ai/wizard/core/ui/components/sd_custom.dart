import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

import 'sd_tokens.dart';
import 'sd_typography.dart';

/// Non-interactive panel/container with standard surface styling.
///
/// Use for static content containers. For selectable cards with hover
/// states, use [SdCard] instead.
class SdPanel extends StatelessWidget {
  const SdPanel({super.key, required this.child, this.style});

  final Widget child;
  final BoxStyler? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = BoxStyler()
        .borderRadiusAll(Radius.circular(SdTokens.cardRadius))
        .color($surfaceSecondary())
        .borderAll(color: $border())
        .paddingAll(SdTokens.cardPadding);
    return Box(style: defaultStyle.merge(style), child: child);
  }
}

/// Selectable card with hover and selection states.
///
/// Use for interactive cards that can be selected. For static containers,
/// use [SdPanel] instead.
class SdCard extends StatelessWidget {
  const SdCard({
    super.key,
    required this.isSelected,
    required this.child,
    this.style,
  });

  final bool isSelected;
  final Widget child;
  final FlexBoxStyler? style;

  @override
  Widget build(BuildContext context) {
    // Base style with selection-aware colors
    final bgColor = isSelected ? $accentSoft() : $surfaceSecondary();
    final borderColor = isSelected ? $accent() : $border();
    final hoverColor = isSelected ? $accentSoftHover() : $surfaceTertiary();

    // Use column so child gets width constraints (enables text wrapping)
    final defaultStyle = FlexBoxStyler()
        .column()
        .borderRadiusAll(Radius.circular(SdTokens.cardRadius))
        .color(bgColor)
        .borderAll(color: borderColor)
        .paddingAll(SdTokens.cardPadding)
        .onHovered(FlexBoxStyler().color(hoverColor))
        .animate(AnimationConfig.ease(SdTokens.motionFast));

    return defaultStyle.merge(style)(children: [child]);
  }
}

/// Color circle widget for palette display.
class SdColorCircle extends StatelessWidget {
  const SdColorCircle({
    super.key,
    required this.color,
    this.interactive = false,
    this.style,
  });

  final Color color;
  final bool interactive;
  final BoxStyler? style;

  @override
  Widget build(BuildContext context) {
    var defaultStyle = BoxStyler()
        .size(20, 20)
        .color(color)
        .shapeCircle(
          side: BorderSideMix.color(
            color,
          ).width(3).strokeAlign(BorderSide.strokeAlignCenter),
        )
        .shadowOnly(
          color: $surfaceSecondary(),
          blurRadius: 0,
          offset: Offset.zero,
          spreadRadius: 4,
        );

    if (interactive) {
      defaultStyle = defaultStyle
          .onHovered(BoxStyler().shadowOnly(color: $surfaceTertiary()))
          .animate(AnimationConfig.ease(SdTokens.motionFast));
    }

    return defaultStyle.merge(style).call();
  }
}

/// Section header for wizard steps.
class SdSectionHeader extends StatelessWidget {
  const SdSectionHeader({
    super.key,
    required this.heading,
    this.subheading,
    this.style,
  });

  final String heading;
  final String? subheading;
  final FlexBoxStyler? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = FlexBoxStyler()
        .column()
        .crossAxisAlignment(CrossAxisAlignment.start)
        .spacing(8)
        .marginBottom(16);

    return defaultStyle.merge(style)(
      children: [
        SdTitle(heading, style: TextStyler().fontWeight(FontWeight.w600)),
        if (subheading != null && subheading!.isNotEmpty)
          SdCaption(subheading!),
      ],
    );
  }
}
