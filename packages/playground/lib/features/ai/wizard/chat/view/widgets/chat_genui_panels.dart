import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';
import '../../../presentation/view/loading.dart';
import '../../chat_message.dart';
import 'chat_bubble.dart';
import '../../../core/ui/ui.dart';

/// Shared bubble border radius for iOS-style chat bubbles.
const _bubbleBorderRadius = BorderRadius.only(
  topLeft: .circular(20),
  topRight: .circular(20),
  bottomRight: .circular(20),
  bottomLeft: .circular(6),
);

/// Typing indicator bubble - shows only when AI is thinking.
class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key, required this.isThinking});

  final ReadonlySignal<bool> isThinking;

  @override
  Widget build(BuildContext context) {
    final thinking = isThinking.watch(context);

    if (!thinking) return const SizedBox.shrink();

    return RowBox(
      style: FlexBoxStyler().spacing(8).padding(.bottom(12)),
      children: [
        SizedBox(
          width: 25,
          height: 25,
          child: IsometricLoading(color: $muted.resolve(context)),
        ),
        StyledText(
          'Thinking...',
          style: TextStyler()
              .color($muted.resolve(context))
              .style($labelSmall.mix()),
        ),
      ],
    );
  }
}

/// Message bubble - shows the last AI message (hidden when thinking).
class GenUiMessageBubble extends StatelessWidget {
  const GenUiMessageBubble({
    super.key,
    required this.isThinking,
    required this.messages,
  });

  final ReadonlySignal<bool> isThinking;
  final ReadonlySignal<List<SuperdeckChatMessage>> messages;

  BoxStyler get _bubbleStyle => BoxStyler()
      .color($background())
      .borderRadius(BorderRadiusMix.value(_bubbleBorderRadius))
      .paddingX(24)
      .paddingY(16)
      .maxWidth(600)
      .marginOnly(left: 48, bottom: 16)
      .wrap(.align(alignment: .centerLeft));

  @override
  Widget build(BuildContext context) {
    final currentMessages = messages.watch(context);
    final thinking = isThinking.watch(context);

    final lastAiMessage = currentMessages.reversed
        .whereType<SuperdeckAiMessage>()
        .firstOrNull;

    if (thinking || lastAiMessage == null) {
      return const SizedBox.shrink();
    }

    return _bubbleStyle(
      child: SdBody(
        lastAiMessage.text,
        style: TextStyler().color($foreground()).style($paragraphMedium.mix()),
      ),
    );
  }
}

/// Shared surfaces panel used by AI conversation screens.
class AiSurfacesPanel extends StatelessWidget {
  const AiSurfacesPanel({
    super.key,
    required this.controller,
    required this.surfaceIds,
    required this.isThinking,
    required this.messages,
    this.inputWidget,
  });

  final SurfaceController? controller;
  final ReadonlySignal<List<String>> surfaceIds;
  final ReadonlySignal<bool> isThinking;
  final ReadonlySignal<List<SuperdeckChatMessage>> messages;

  /// Optional input widget to display at bottom when chat panel is hidden.
  final Widget? inputWidget;

  @override
  Widget build(BuildContext context) {
    final ids = surfaceIds.watch(context);
    final thinking = isThinking.watch(context);

    final flex = FlexBoxStyler()
        .spacing(16)
        .column()
        .mainAxisSize(MainAxisSize.min)
        .marginAll(24);

    Widget? surfacesWidget;
    if (controller case final resolvedController?) {
      if (ids.isNotEmpty) {
        surfacesWidget = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: SdTokens.motionMedium,
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: AnimatedOpacity(
                duration: SdTokens.motionFast,
                opacity: thinking ? 0.5 : 1.0,
                child: WizardLoadingState(
                  isLoading: thinking,
                  child: flex(
                    key: ValueKey(ids.last),
                    children: ids.map((surfaceId) {
                      return IgnorePointer(
                        key: ValueKey('ignore_$surfaceId'),
                        ignoring: thinking,
                        child: Surface(
                          key: ValueKey('surface_$surfaceId'),
                          surfaceContext: resolvedController.contextFor(
                            surfaceId,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    if (inputWidget == null) {
      return surfacesWidget ?? const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GenUiMessageBubble(
                    isThinking: isThinking,
                    messages: messages,
                  ),
                  if (surfacesWidget != null) surfacesWidget,
                ],
              ),
            ),
          ),
        ),
        TypingBubble(isThinking: isThinking),
        inputWidget ?? const SizedBox.shrink(),
      ],
    );
  }
}

/// Shared chat body panel used by AI conversation screens.
class ChatBodyPanel extends StatelessWidget {
  const ChatBodyPanel({
    super.key,
    required this.messages,
    required this.isThinking,
    required this.emptyState,
    this.inputWidget,
  });

  final ReadonlySignal<List<SuperdeckChatMessage>> messages;
  final ReadonlySignal<bool> isThinking;
  final Widget emptyState;

  /// Optional input widget to display at bottom when chat panel is visible.
  final Widget? inputWidget;

  @override
  Widget build(BuildContext context) {
    final thinking = isThinking.watch(context);

    return Column(
      children: [
        Expanded(
          child: MessageList(messages: messages, emptyState: emptyState),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              if (thinking) const LoadingResponse(),
              if (inputWidget != null) inputWidget!,
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared message list used by AI conversation body panels.
class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.messages,
    required this.emptyState,
  });

  final ReadonlySignal<List<SuperdeckChatMessage>> messages;
  final Widget emptyState;

  @override
  Widget build(BuildContext context) {
    final currentMessages = messages.watch(context);
    final reversedMessages = currentMessages.reversed.toList();

    if (currentMessages.isEmpty) {
      return emptyState;
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: reversedMessages.length * 2,
      itemBuilder: (context, index) {
        if (index.isEven) {
          return const SizedBox(height: 16);
        }

        final message = reversedMessages[index ~/ 2];

        switch (message) {
          case SuperdeckUserMessage():
            return TextBubble(text: message.text, type: .user);
          case SuperdeckAiMessage():
            return TextBubble(text: message.text, type: .ai);
          case SuperdeckDebugMessage():
            return TextBubble(text: message.text, type: .debug);
          case SuperdeckJsonDebugMessage():
            return TextBubble(text: message.text, type: .debug);
        }
      },
    );
  }
}

class LoadingResponse extends StatelessWidget {
  const LoadingResponse({super.key});

  @override
  Widget build(BuildContext context) {
    final text = TextStyler().color($muted()).style($labelXSmall.mix());

    final row = FlexBoxStyler().spacing(6);

    return row(
      children: [
        SdSpinner(size: SdSpinnerSize.size1),
        text('Thinking...'),
      ],
    );
  }
}
