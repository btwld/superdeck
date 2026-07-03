import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

import '../../../../core/utils/color_utils.dart';
import 'labels.dart';

/// Reusable color control used across the customization sidebar.
///
/// Renders an editable `#RRGGBB` hex field with a live color-dot preview.
/// Colors are opaque-only; any alpha typed into the field is dropped on commit.
///
/// The control is prop-driven — [color] is the source of truth and [onChanged]
/// reports edits. Invalid hex input reverts to the last valid [color].
class ColorControl extends StatefulWidget {
  const ColorControl({
    super.key,
    required this.color,
    required this.onChanged,
    this.label,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final String? label;

  @override
  State<ColorControl> createState() => _ColorControlState();
}

class _ColorControlState extends State<ColorControl> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: colorToHex(widget.color));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(ColorControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pull external color changes (swatch tap, reset) into the field, unless the
    // user is mid-edit.
    if (widget.color != oldWidget.color && !_focusNode.hasFocus) {
      _controller.text = colorToHex(widget.color);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  /// Parses the field and either reports the color or rewrites the field with
  /// the last known good value.
  void _commit() {
    final result = parseHexColor(_controller.text.trim());
    if (!result.isValid) {
      _controller.text = colorToHex(widget.color);
      return;
    }
    // Force opaque — the control is opaque-only.
    final opaque = result.color.withValues(alpha: 1);
    _controller.text = colorToHex(opaque);
    if (opaque != widget.color) widget.onChanged(opaque);
  }

  @override
  Widget build(BuildContext context) {
    return ColumnBox(
      style: FlexBoxStyler().spacing(8).crossAxisAlignment(.stretch),
      children: [
        if (widget.label != null) ControlLabel(widget.label!),
        HeroTextField(
          fullWidth: true,
          controller: _controller,
          focusNode: _focusNode,
          style: RemixTextFieldStyle().backgroundColor($surfaceSecondary()),
          leading: _ColorDot(color: widget.color),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
            LengthLimitingTextInputFormatter(7),
            _UpperCaseFormatter(),
          ],
          onSubmitted: (_) => _commit(),
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
