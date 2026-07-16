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
  final RemixButtonStyle? style;
  final SdButtonVariant variant;

  HeroButtonVariant get _heroVariant => switch (variant) {
    SdButtonVariant.primary => HeroButtonVariant.primary,
    SdButtonVariant.outline => HeroButtonVariant.outline,
    SdButtonVariant.ghost => HeroButtonVariant.ghost,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      enabled: enabled && !loading,
      child: HeroButton(
        label: label,
        onPressed: onPressed,
        iconLeft: icon,
        enabled: enabled,
        loading: loading,
        variant: _heroVariant,
        style: style,
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
  final RemixIconButtonStyle? style;

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
