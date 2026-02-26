import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck_ai/chat/view/widgets/chat_bubble.dart';
import 'package:superdeck_ai/chat/view/widgets/chat_genui_panels.dart';
import 'package:superdeck_ai/chat/view/widgets/chat_input.dart';
import 'package:superdeck_ai/chat/view/widgets/chat_scaffold.dart';
import 'package:superdeck_ai/chat/view/widgets/empty_state.dart';
import 'package:superdeck_ai/chat/view/widgets/model_select.dart';
import 'package:superdeck_ai/chat/chat_viewmodel.dart';
import 'package:superdeck_ai/core/viewmodel_scope.dart';
import 'package:superdeck_ai/core/router.dart';
import 'package:superdeck_ai/core/ai/wizard_context.dart';
import 'package:superdeck_ai/core/ui/ui.dart';
import 'package:superdeck_ai/presentation/presentation_viewmodel.dart';

/// Main chat screen for the wizard-based presentation builder.
///
/// Provides a two-panel interface with GenUI surfaces on the left
/// and chat messages on the right. Manages the [ChatViewModel] lifecycle.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelScope<ChatViewModel>(
      create: () => ChatViewModel(),
      child: const _ChatScreenScaffold(),
    );
  }
}

class _ChatScreenScaffold extends StatefulWidget {
  const _ChatScreenScaffold();

  @override
  State<_ChatScreenScaffold> createState() => _ChatScreenScaffoldState();
}

class _ChatScreenScaffoldState extends State<_ChatScreenScaffold> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit(String value) {
    final viewModel = context.read<ChatViewModel>();
    viewModel.sendMessage(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ChatViewModel>();

    return Watch((context) {
      final showChat = viewModel.showChat.value;
      final isThinking = viewModel.isThinking.value;

      // Single input widget, positioned based on showChat
      final inputWidget = ChatInput(
        controller: _controller,
        enabled: !isThinking,
        onSubmitted: _handleSubmit,
      );

      return _buildScaffold(
        context: context,
        viewModel: viewModel,
        inputWidget: inputWidget,
        showChat: showChat,
      );
    });
  }

  Widget _buildScaffold({
    required BuildContext context,
    required ChatViewModel viewModel,
    required Widget inputWidget,
    required bool showChat,
  }) {
    return ChatScaffold(
      showChat: showChat,
      appBar: _buildHeader(
        context: context,
        viewModel: viewModel,
        showChat: showChat,
      ),
      leadingWidget: _AiSurfaces(inputWidget: showChat ? null : inputWidget),
      trailingWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _ChatBody(
          inputWidget: showChat ? inputWidget : null,
          onSuggestionTap: _handleSubmit,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader({
    required BuildContext context,
    required ChatViewModel viewModel,
    required bool showChat,
  }) {
    return SdHeader(
      leading: Row(
        spacing: 16,
        children: [
          Watch((context) {
            final hasConversationStarted =
                viewModel.hasConversationStarted.value;
            return ModelsSelect(
              enabled: !hasConversationStarted,
              selectedValue: viewModel.model.value,
              onChanged: (value) {
                viewModel.model.set(value);
              },
            );
          }),
        ],
      ),
      trailing: _buildHeaderActions(
        context: context,
        viewModel: viewModel,
        showChat: showChat,
      ),
    );
  }

  Widget _buildHeaderActions({
    required BuildContext context,
    required ChatViewModel viewModel,
    required bool showChat,
  }) {
    return Row(
      spacing: 8,
      children: [
        SdIconButton(
          icon: Icons.refresh,
          semanticLabel: 'Regenerate presentation',
          onPressed: () {
            final presentationVM = context.read<PresentationViewModel>();
            presentationVM.generate(
              context: const WizardContext(),
              callback: (context, onProgress) =>
                  viewModel.regenerateFromLastPrompt(onProgress),
            );
            context.go(Routes.presentationCreating);
          },
        ),
        SdIconButton(
          icon: Icons.slideshow,
          semanticLabel: 'View presentation',
          onPressed: () {
            context.go(Routes.presentation);
          },
        ),
        Watch((context) {
          final debugMode = viewModel.debugMode.value;
          return Row(
            spacing: 8,
            children: [
              GestureDetector(
                onTap: () => viewModel.debugMode.set(!debugMode),
                child: SdCaption(
                  'Show logs',
                  style: TextStyler().color(FortalTokens.gray11()).fontSize(13),
                ),
              ),
              SdSwitch(
                selected: debugMode,
                semanticLabel: 'Show debug logs',
                onChanged: (value) {
                  viewModel.debugMode.set(value);
                },
              ),
            ],
          );
        }),
        SdIconButton(
          icon: showChat ? Icons.chat : Icons.chat_outlined,
          semanticLabel: showChat ? 'Hide chat panel' : 'Show chat panel',
          onPressed: () {
            viewModel.showChat.set(!showChat);
          },
        ),
        SdButton(
          label: 'Restart',
          icon: Icons.replay_rounded,
          semanticLabel: 'Restart conversation',
          onPressed: () {
            viewModel.restartConversation();
          },
        ),
      ],
    );
  }
}

class _AiSurfaces extends StatelessWidget {
  const _AiSurfaces({this.inputWidget});

  /// Optional input widget to display at bottom when chat panel is hidden.
  final Widget? inputWidget;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ChatViewModel>();
    final surfaceIds = viewModel.surfaceIds.watch(context);
    final isThinking = viewModel.isThinking.watch(context);

    final flex = FlexBoxStyler()
        .spacing(16)
        .column()
        .mainAxisSize(MainAxisSize.min)
        .marginAll(24);

    // Build surfaces widget if conversation exists
    Widget? surfacesWidget;
    if (viewModel.host case final host?) {
      if (surfaceIds.isNotEmpty) {
        surfacesWidget = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: SdTokens.motionMedium,
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: AnimatedOpacity(
                duration: SdTokens.motionFast,
                opacity: isThinking ? 0.5 : 1.0,
                child: WizardLoadingState(
                  isLoading: isThinking,
                  child: flex(
                    key: ValueKey(surfaceIds.last),
                    children: surfaceIds.map((e) {
                      return IgnorePointer(
                        key: ValueKey('ignore_$e'),
                        ignoring: isThinking,
                        child: GenUiSurface(
                          key: ValueKey('surface_$e'),
                          host: host,
                          surfaceId: e,
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

    // When no input widget provided, just show surfaces
    if (inputWidget == null) {
      return surfacesWidget ?? const SizedBox.shrink();
    }

    // When input widget provided (chat hidden), show full layout with input at bottom
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TypingBubble(),
                    const GenUiMessageBubble(),
                    ?surfacesWidget,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(width: 500, child: inputWidget),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({this.inputWidget, this.onSuggestionTap});

  /// Optional input widget to display at bottom when chat panel is visible.
  final Widget? inputWidget;

  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ChatViewModel>();

    return Column(
      children: [
        Expanded(child: _MessageList(onSuggestionTap: onSuggestionTap)),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Watch((context) {
                final isThinking = viewModel.isThinking.value;
                return isThinking
                    ? const LoadingResponse()
                    : const SizedBox.shrink();
              }),
              ?inputWidget,
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({this.onSuggestionTap});

  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ChatViewModel>();

    final messages = viewModel.messages.watch(context);
    final reversedMessages = messages.reversed.toList();

    if (messages.isEmpty) {
      return EmptyState(onSuggestionTap: onSuggestionTap);
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
