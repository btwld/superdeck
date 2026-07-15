import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';
import '../../../presentation/view/loading.dart';
import '../../chat_message.dart';
import 'chat_bubble.dart';
import '../../../core/ui/ui.dart';

/// Typing indicator - shows only when AI is thinking.
class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key, required this.isThinking});

  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    if (!isThinking) return const SizedBox.shrink();

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

/// Shared surfaces panel used by AI conversation screens.
class AiSurfacesPanel extends StatelessWidget {
  const AiSurfacesPanel({
    super.key,
    required this.controller,
    required this.surfaceIds,
    required this.isThinking,
    this.errorMessage,
    this.inputWidget,
  });

  final SurfaceController? controller;
  final List<String> surfaceIds;
  final bool isThinking;
  final String? errorMessage;

  /// Optional input widget to display at bottom when chat panel is hidden.
  final Widget? inputWidget;

  @override
  Widget build(BuildContext context) {
    final ids = surfaceIds;
    final thinking = isThinking;

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
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
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

    final errorWidget = errorMessage == null
        ? null
        : Padding(
            padding: const EdgeInsets.all(24),
            child: SdCallout(
              text: errorMessage,
              icon: LucideIcons.triangleAlert,
            ),
          );

    if (inputWidget == null) {
      return surfacesWidget ?? errorWidget ?? const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [?surfacesWidget, ?errorWidget],
                ),
              ),
            ),
          ),
          TypingBubble(isThinking: thinking),
          inputWidget ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Shared chat body panel used by AI conversation screens.
class ChatBodyPanel extends SignalWidget {
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
    final thinking = isThinking.value;

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
            children: [if (thinking) const LoadingResponse(), ?inputWidget],
          ),
        ),
      ],
    );
  }
}

/// Shared message list used by AI conversation body panels.
class MessageList extends SignalWidget {
  const MessageList({
    super.key,
    required this.messages,
    required this.emptyState,
  });

  final ReadonlySignal<List<SuperdeckChatMessage>> messages;
  final Widget emptyState;

  @override
  Widget build(BuildContext context) {
    final currentMessages = messages.value;
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
