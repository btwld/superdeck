import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

/// Spinner sizes, mapped to concrete pixel diameters.
enum SdSpinnerSize { size1, size2, size3 }

/// Surface badge style built on hero_ui tokens.
RemixBadgeStyle _sdBadgeStyle() {
  return RemixBadgeStyle(
    container: BoxStyler()
        .paddingX(8.0)
        .paddingY(3.0)
        .borderRadiusAll(const Radius.circular(6.0)),
    text: TextStyler(style: $labelSmall.mix()),
  ).backgroundColor($surfaceSecondary()).foregroundColor($foreground());
}

/// Surface (accent-soft) callout style built on hero_ui tokens.
RemixCalloutStyle _sdCalloutStyle() {
  return RemixCalloutStyle(
    container: FlexBoxStyler(
      direction: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.center,
    ).paddingY(12.0).paddingX(16.0).spacing(8.0),
    text: TextStyler(style: $paragraphSmall.mix()),
    icon: IconStyler(size: 20.0),
  )
      .backgroundColor($accentSoft())
      .borderRadiusAll(const Radius.circular(8.0))
      .borderAll(color: $border(), width: 1.0)
      .textColor($foreground())
      .iconColor($accent());
}

/// Accent spinner style built on hero_ui tokens.
RemixSpinnerStyle _sdSpinnerStyle(SdSpinnerSize size) {
  final (double px, double stroke) = switch (size) {
    SdSpinnerSize.size1 => (16.0, 1.5),
    SdSpinnerSize.size2 => (20.0, 2.0),
    SdSpinnerSize.size3 => (24.0, 2.5),
  };
  return RemixSpinnerStyle(
    size: px,
    strokeWidth: stroke,
    indicatorColor: $accent(),
    duration: const Duration(milliseconds: 800),
  );
}

/// Pre-styled spinner.
class SdSpinner extends StatelessWidget {
  const SdSpinner({super.key, this.size = SdSpinnerSize.size3});

  final SdSpinnerSize size;

  @override
  Widget build(BuildContext context) {
    return RemixSpinner(style: _sdSpinnerStyle(size));
  }
}

/// Pre-styled badge for chips, tags, and labels.
///
/// Usage: `SdBadge(label: 'New')`
class SdBadge extends StatelessWidget {
  const SdBadge({super.key, required this.label, this.style});

  final String label;
  final RemixBadgeStyle? style;

  @override
  Widget build(BuildContext context) {
    return RemixBadge(label: label, style: _sdBadgeStyle().merge(style));
  }
}

/// Pre-styled divider line.
///
/// Usage: `SdDivider()`
class SdDivider extends StatelessWidget {
  const SdDivider({super.key, this.label, this.style});

  final String? label;
  final BoxStyler? style;

  @override
  Widget build(BuildContext context) {
    return HeroDivider(label: label, style: style);
  }
}

/// Pre-styled callout for status messages and alerts.
///
/// Usage: `SdCallout(text: 'Information message')`
class SdCallout extends StatelessWidget {
  const SdCallout({super.key, this.text, this.icon, this.child, this.style});

  final String? text;
  final IconData? icon;
  final Widget? child;
  final RemixCalloutStyle? style;

  @override
  Widget build(BuildContext context) {
    return RemixCallout(
      text: text,
      icon: icon,
      style: _sdCalloutStyle().merge(style),
      child: child,
    );
  }
}
