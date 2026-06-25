import 'package:flutter/material.dart';
import 'package:remix/remix.dart';

/// Pre-styled Fortal spinner.
class SdSpinner extends StatelessWidget {
  const SdSpinner({super.key, this.size = FortalSpinnerSize.size3});

  final FortalSpinnerSize size;

  @override
  Widget build(BuildContext context) {
    return FortalSpinnerStyles.create(size: size).call();
  }
}

/// Pre-styled badge for chips, tags, and labels.
///
/// Usage: `SdBadge(label: 'New')`
/// Override: `SdBadge(label: 'New', style: FortalBadgeStyles.soft())`
class SdBadge extends StatelessWidget {
  const SdBadge({super.key, required this.label, this.style});

  final String label;
  final RemixBadgeStyle? style;

  @override
  Widget build(BuildContext context) {
    final finalStyle = FortalBadgeStyles.surface().merge(style);
    return RemixBadge(label: label, style: finalStyle);
  }
}

/// Pre-styled divider line.
///
/// Usage: `SdDivider()`
/// Override: `SdDivider(style: FortalDividerStyles.create(size: FortalDividerSize.size2))`
class SdDivider extends StatelessWidget {
  const SdDivider({super.key, this.style});

  final RemixDividerStyle? style;

  @override
  Widget build(BuildContext context) {
    final finalStyle = FortalDividerStyles.create().merge(style);
    return RemixDivider(style: finalStyle);
  }
}

/// Pre-styled callout for status messages and alerts.
///
/// Usage: `SdCallout(text: 'Information message')`
/// Override: `SdCallout(text: 'Warning', style: FortalCalloutStyles.soft())`
class SdCallout extends StatelessWidget {
  const SdCallout({super.key, this.text, this.icon, this.child, this.style});

  final String? text;
  final IconData? icon;
  final Widget? child;
  final RemixCalloutStyle? style;

  @override
  Widget build(BuildContext context) {
    final finalStyle = FortalCalloutStyles.surface().merge(style);
    return RemixCallout(
      text: text,
      icon: icon,
      style: finalStyle,
      child: child,
    );
  }
}
