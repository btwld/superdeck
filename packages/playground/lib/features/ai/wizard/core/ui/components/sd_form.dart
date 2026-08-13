import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

/// Pre-styled checkbox.
class SdCheckbox extends StatelessWidget {
  const SdCheckbox({
    super.key,
    required this.selected,
    this.onChanged,
    this.enabled = true,
    this.tristate = false,
    this.semanticLabel,
    this.style,
  });

  final bool? selected;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;
  final bool tristate;

  /// Semantic label for accessibility.
  final String? semanticLabel;
  final RemixCheckboxStyler? style;

  @override
  Widget build(BuildContext context) {
    return HeroCheckbox(
      selected: selected,
      onChanged: onChanged,
      enabled: enabled,
      tristate: tristate,
      semanticLabel: semanticLabel,
      style: style,
    );
  }
}

/// Pre-styled text field.
class SdTextField extends StatelessWidget {
  const SdTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.label,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.semanticLabel,
    this.style,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? label;
  final Widget? leading;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;

  /// Semantic label for accessibility (screen readers, browser automation).
  final String? semanticLabel;
  final RemixTextFieldStyler? style;

  @override
  Widget build(BuildContext context) {
    final field = HeroTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      label: label,
      leading: leading,
      trailing: trailing,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: obscureText,
      style: style,
    );

    // Use label-only semantics — do NOT set textField: true here because
    // HeroTextField already creates its own text-field semantic node.
    // Duplicating it produces two <input> elements in the DOM on Flutter Web,
    // which breaks focus routing and prevents typing.
    final effectiveLabel = semanticLabel ?? label ?? hintText;
    if (effectiveLabel != null) {
      return Semantics(label: effectiveLabel, enabled: enabled, child: field);
    }
    return field;
  }
}
