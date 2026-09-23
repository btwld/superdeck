import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

/// Spinner sizes, mapped to concrete pixel diameters.
enum SdSpinnerSize { size1, size2, size3 }

/// Surface (accent-soft) callout style built on hero_ui tokens.
RemixCalloutStyler _sdCalloutStyle() {
  return RemixCalloutStyler(
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
RemixSpinnerStyler _sdSpinnerStyle(SdSpinnerSize size) {
  final (double px, double stroke) = switch (size) {
    SdSpinnerSize.size1 => (16.0, 1.5),
    SdSpinnerSize.size2 => (20.0, 2.0),
    SdSpinnerSize.size3 => (24.0, 2.5),
  };

  return RemixSpinnerStyler(
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

/// Pre-styled callout for status messages and alerts.
///
/// Usage: `SdCallout(text: 'Information message')`
class SdCallout extends StatelessWidget {
  const SdCallout({super.key, this.text, this.icon, this.child, this.style});

  final String? text;
  final IconData? icon;
  final Widget? child;
  final RemixCalloutStyler? style;

  @override
  Widget build(BuildContext context) {
    if (text case final message? when child == null && style == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: $accentSoft.resolve(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: $border.resolve(context)),
        ),
        child: Row(
          spacing: 8,
          children: [
            if (icon case final icon?)
              Icon(icon, size: 20, color: $accent.resolve(context)),
            Expanded(
              child: TextStyler()
                  .style($paragraphSmall.mix())
                  .color($foreground())
                  .call(message),
            ),
          ],
        ),
      );
    }

    return RemixCallout(
      text: text,
      icon: icon,
      style: _sdCalloutStyle().merge(style),
      child: child,
    );
  }
}
