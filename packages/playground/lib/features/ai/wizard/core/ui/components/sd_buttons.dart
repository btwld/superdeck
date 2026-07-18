import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

enum SdButtonVariant { primary, outline, ghost }

/// Application-owned button with a consistent Wizard action hierarchy.
class SdButton extends StatelessWidget {
  const SdButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
    this.loading = false,
    this.semanticLabel,
    this.style,
    this.variant = SdButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;
  final bool loading;

  /// Semantic label for accessibility. Defaults to [label] if not provided.
  final String? semanticLabel;
  final RemixButtonStyler? style;
  final SdButtonVariant variant;

  HeroButtonVariant get _heroVariant => switch (variant) {
    .primary => HeroButtonVariant.primary,
    .outline => .outline,
    .ghost => .ghost,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: enabled && !loading,
      button: true,
      label: semanticLabel ?? label,
      child: HeroButton(
        variant: _heroVariant,
        style: style,
        label: label,
        leadingIcon: icon,
        loading: loading,
        enabled: enabled,
        onPressed: onPressed,
      ),
    );
  }
}

/// Pre-styled surface icon button.
class SdIconButton extends StatelessWidget {
  const SdIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.semanticLabel,
    this.style,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final String? semanticLabel;
  final RemixIconButtonStyler? style;

  @override
  Widget build(BuildContext context) {
    final button = HeroIconButton(
      icon: icon,
      onPressed: onPressed,
      loading: loading,
      variant: HeroButtonVariant.secondary,
      style: style,
    );

    if (semanticLabel != null) {
      return Semantics(button: true, label: semanticLabel, child: button);
    }
    return button;
  }
}
