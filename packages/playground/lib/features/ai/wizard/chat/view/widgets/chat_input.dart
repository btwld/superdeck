import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

/// Shared chat input widget used by both sidebar and inline views.
///
/// Provides consistent behavior: disabled while thinking, unified hint text,
/// and proper TextInputAction.send for enter-to-submit.
class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmitted;
  final String hintText;

  const ChatInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.enabled,
    required this.onSubmitted,
    this.hintText = 'Type a message...',
  });

  @override
  Widget build(BuildContext context) {
    final trailingStyle = TextStyler()
        .color($fieldPlaceholder())
        .fontSize(14)
        .fontWeight(FontWeight.w600);

    return HeroTextField(
      hintText: hintText,
      trailing: trailingStyle('Press Enter'),
      textInputAction: TextInputAction.send,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      semanticLabel: 'Chat message input',
      style: RemixTextFieldStyle()
          .padding(.horizontal(16).vertical(14))
          .backgroundColor($surfaceSecondary())
          .border(.color($border()))
          .borderRadiusAll(const Radius.circular(14)),
      onSubmitted: enabled ? onSubmitted : null,
    );
  }
}
