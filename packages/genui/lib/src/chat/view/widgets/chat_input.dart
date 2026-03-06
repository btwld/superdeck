import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remix/remix.dart';
import '../../../ui/components/sd_components.dart';

/// Shared chat input widget used by both sidebar and inline views.
///
/// Provides consistent behavior: disabled while thinking, unified hint text,
/// and proper TextInputAction.send for enter-to-submit.
/// Uses Focus.onKeyEvent for explicit Enter key handling on web.
class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  const ChatInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!enabled) return KeyEventResult.ignored;
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        onSubmitted(text);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final trailingStyle = TextStyler()
        .color(FortalTokens.gray7())
        .fontSize(14)
        .fontWeight(FontWeight.w600);

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: SdTextField(
        hintText: 'Type a message...',
        trailing: trailingStyle('Press Enter'),
        textInputAction: TextInputAction.send,
        controller: controller,
        enabled: enabled,
        semanticLabel: 'Chat message input',
        onSubmitted: enabled ? onSubmitted : null,
      ),
    );
  }
}
