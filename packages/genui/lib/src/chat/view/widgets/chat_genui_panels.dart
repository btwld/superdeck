import 'package:flutter/material.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';
import '../../chat_message.dart';
import '../../chat_viewmodel.dart';
import './typing_indicator.dart';
import '../../../viewmodel_scope.dart';
import '../../../ui/components/sd_components.dart';

/// Shared bubble border radius for iOS-style chat bubbles.
const _bubbleBorderRadius = BorderRadius.only(
  topLeft: Radius.circular(20),
  topRight: Radius.circular(20),
  bottomRight: Radius.circular(20),
  bottomLeft: Radius.circular(6),
);

/// Typing indicator bubble - shows only when AI is thinking.
class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ChatViewModel>();
    final isThinking = viewModel.isThinking.watch(context);

    if (!isThinking) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 48, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: FortalTokens.gray1.resolve(context),
            borderRadius: _bubbleBorderRadius,
            boxShadow: [
              BoxShadow(
                color: FortalTokens.gray12
                    .resolve(context)
                    .withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const TypingIndicator(),
        ),
      ),
    );
  }
}

/// Message bubble - shows the last AI message (hidden when thinking).
class GenUiMessageBubble extends StatelessWidget {
  const GenUiMessageBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ChatViewModel>();
    final messages = viewModel.messages.watch(context);
    final isThinking = viewModel.isThinking.watch(context);

    final lastAiMessage = messages.reversed
        .whereType<SuperdeckAiMessage>()
        .firstOrNull;

    if (isThinking || lastAiMessage == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 48, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _bubbleBorderRadius,
            boxShadow: [
              BoxShadow(
                color: FortalTokens.gray12
                    .resolve(context)
                    .withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SdBody(
            lastAiMessage.text,
            style: TextStyler()
                .color(Colors.black87)
                .style(TextStyleMix(fontSize: 18, height: 1.4)),
          ),
        ),
      ),
    );
  }
}

class LoadingResponse extends StatelessWidget {
  const LoadingResponse({super.key});

  @override
  Widget build(BuildContext context) {
    final text = TextStyler()
        .color(FortalTokens.gray10())
        .style(FortalTokens.text1.mix());

    final row = FlexBoxStyler().spacing(6);

    return row(
      children: [
        SdSpinner(size: FortalSpinnerSize.size1),
        text('Thinking...'),
      ],
    );
  }
}
