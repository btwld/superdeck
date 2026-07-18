import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

/// Shared chat input widget used by both sidebar and inline views.
///
/// Provides consistent behavior: disabled while thinking, unified hint text,
/// and proper TextInputAction.send for enter-to-submit.
class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.autofocus = false,
    required this.enabled,
    required this.onSubmitted,
    this.hintText = 'Type a message...',
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  final String hintText;

  @override
  Widget build(BuildContext context) {
    final trailingStyle = TextStyler()
        .color($fieldPlaceholder())
        .fontSize(14)
        .fontWeight(FontWeight.w600);

    return HeroTextField(
      style: RemixTextFieldStyler()
          .padding(.horizontal(16).vertical(14))
          .backgroundColor($surfaceSecondary())
          .border(.color($border()))
          .borderRadiusAll(const .circular(14)),
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      textInputAction: TextInputAction.send,
      enabled: enabled,
      autofocus: autofocus,
      onSubmitted: enabled ? onSubmitted : null,
      trailing: trailingStyle('Press Enter'),
      semanticLabel: 'Chat message input',
    );
  }
}
