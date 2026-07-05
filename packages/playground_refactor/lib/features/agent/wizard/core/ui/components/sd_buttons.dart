import 'package:flutter/material.dart';
import 'package:remix/remix.dart';

/// Pre-styled solid button.
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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;
  final bool loading;

  /// Semantic label for accessibility. Defaults to [label] if not provided.
  final String? semanticLabel;
  final RemixButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final finalStyle = FortalButtonStyle.solid().merge(style);
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      enabled: enabled && !loading,
      child: RemixButton(
        label: label,
        onPressed: onPressed,
        leadingIcon: icon,
        enabled: enabled,
        loading: loading,
        style: finalStyle,
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
    final finalStyle = FortalIconButtonStyle.surface().merge(style);
    return RemixIconButton(
      icon: icon,
      onPressed: onPressed,
      loading: loading,
      semanticLabel: semanticLabel,
      style: finalStyle,
    );
  }
}
