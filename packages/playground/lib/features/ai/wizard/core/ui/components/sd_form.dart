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
  final RemixCheckboxStyle? style;

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

/// Pre-styled switch.
class SdSwitch extends StatelessWidget {
  const SdSwitch({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  });

  final bool selected;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  /// Semantic label for accessibility.
  final String? semanticLabel;
  final RemixSwitchStyle? style;

  @override
  Widget build(BuildContext context) {
    return HeroSwitch(
      selected: selected,
      onChanged: onChanged,
      enabled: enabled,
      semanticLabel: semanticLabel,
      style: style,
    );
  }
}

/// Pre-styled slider.
class SdSlider extends StatelessWidget {
  const SdSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.enabled = true,
    this.snapDivisions,
    this.semanticLabel,
    this.style,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final bool enabled;
  final int? snapDivisions;

  /// Semantic label for accessibility.
  final String? semanticLabel;
  final RemixSliderStyle? style;

  @override
  Widget build(BuildContext context) {
    return HeroSlider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      enabled: enabled,
      snapDivisions: snapDivisions,
      showOutput: false,
      semanticLabel: semanticLabel,
      style: style,
    );
  }
}

/// Pre-styled radio button.
///
/// Must be used within an [SdRadioGroup].
class SdRadio<T> extends StatelessWidget {
  const SdRadio({super.key, required this.value, this.enabled = true, this.style});

  final T value;
  final bool enabled;
  final RemixRadioStyle? style;

  @override
  Widget build(BuildContext context) {
    return HeroRadio<T>(value: value, enabled: enabled, style: style);
  }
}

/// Radio group that manages selection state for [SdRadio] children.
class SdRadioGroup<T> extends StatelessWidget {
  const SdRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HeroRadioGroup<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }
}

/// Pre-styled select dropdown.
class SdSelect<T> extends StatelessWidget {
  const SdSelect({
    super.key,
    required this.items,
    this.placeholder = 'Select...',
    this.icon,
    this.selectedValue,
    this.onChanged,
    this.enabled = true,
    this.style,
  });

  final List<SdSelectItem<T>> items;
  final String placeholder;
  final IconData? icon;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final RemixSelectStyle? style;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: HeroSelect<T>(
        placeholder: placeholder,
        icon: icon,
        items: items.map((item) => item._toHeroSelectItem()).toList(),
        selectedValue: selectedValue,
        onChanged: onChanged,
        enabled: enabled,
        style: style,
      ),
    );
  }
}

/// Pre-styled select item for use with [SdSelect].
class SdSelectItem<T> {
  const SdSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;

  HeroSelectItem<T> _toHeroSelectItem() {
    return HeroSelectItem<T>(value: value, label: label, enabled: enabled);
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
  final RemixTextFieldStyle? style;

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
