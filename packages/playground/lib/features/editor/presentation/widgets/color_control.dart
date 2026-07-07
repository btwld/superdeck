import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

import '../../../../core/utils/color_utils.dart';
import 'committed_text_field.dart';
import 'labels.dart';

/// Reusable color control used across the customization sidebar.
///
/// Renders an editable `#RRGGBB` hex field with a live color-dot preview.
/// Colors are opaque-only; any alpha typed into the field is dropped on commit.
///
/// The control is prop-driven — [color] is the source of truth and [onChanged]
/// reports edits. Invalid hex input reverts to the last valid [color].
class ColorControl extends StatelessWidget {
  const ColorControl({
    super.key,
    required this.color,
    required this.onChanged,
    this.label,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final String? label;

  /// Parses hex text into an opaque color, or null to reject. Any alpha is
  /// dropped — the control is opaque-only.
  static Color? _parseOpaque(String text) {
    final result = parseHexColor(text.trim());
    if (!result.isValid) return null;
    return result.color.withValues(alpha: 1);
  }

  @override
  Widget build(BuildContext context) {
    return ColumnBox(
      style: FlexBoxStyler().spacing(8).crossAxisAlignment(.stretch),
      children: [
        if (label != null) ControlLabel(label!),
        CommittedTextField<Color>(
          value: color,
          format: colorToHex,
          parse: _parseOpaque,
          onChanged: onChanged,
          style: RemixTextFieldStyle().backgroundColor($surfaceSecondary()),
          leading: _ColorDot(color: color),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
            LengthLimitingTextInputFormatter(7),
            _UpperCaseFormatter(),
          ],
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler()
          .width(18)
          .height(18)
          .color(color)
          .borderRounded(999)
          .borderAll(color: $border(), width: 1),
    );
  }
}

/// Uppercases hex input so the field reads like the mockup (`#0485F7`).
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
