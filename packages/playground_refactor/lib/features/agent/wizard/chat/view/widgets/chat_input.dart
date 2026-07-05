import 'package:flutter/material.dart';
import 'package:remix/remix.dart';
import '../../../core/ui/ui.dart';

/// Shared chat input widget used by both sidebar and inline views.
///
/// Provides consistent behavior: disabled while thinking, unified hint text,
/// and proper TextInputAction.send for enter-to-submit.
class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  const ChatInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.enabled,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final trailingStyle = TextStyler()
        .color(FortalTokens.gray7())
        .fontSize(14)
        .fontWeight(FontWeight.w600);

    return SdTextField(
      hintText: 'Type a message...',
      trailing: trailingStyle('Press Enter'),
      textInputAction: TextInputAction.send,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      semanticLabel: 'Chat message input',
      onSubmitted: enabled ? onSubmitted : null,
    );
  }
}
