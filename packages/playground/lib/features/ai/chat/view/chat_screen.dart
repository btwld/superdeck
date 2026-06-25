import 'package:flutter/material.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';
import 'package:playground/features/ai/chat/chat_viewmodel.dart';
import 'package:playground/features/ai/chat/view/widgets/chat_genui_panels.dart';
import 'package:playground/features/ai/chat/view/widgets/chat_input.dart';
import 'package:playground/features/ai/chat/view/widgets/chat_scaffold.dart';
import 'package:playground/features/ai/chat/view/widgets/empty_state.dart';
import 'package:playground/features/ai/chat/view/widgets/model_select.dart';
import 'package:playground/features/ai/core/ui/ui.dart';
import 'package:playground/features/ai/core/viewmodel_scope.dart';
import 'package:playground/features/ai/remix/view/remix_screen.dart';

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
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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

      final inputWidget = ChatInput(
        controller: _controller,
        focusNode: _focusNode,
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
      leadingWidget: AiSurfacesPanel(
        host: viewModel.host,
        surfaceIds: viewModel.surfaceIds,
        isThinking: viewModel.isThinking,
        messages: viewModel.messages,
        inputWidget: showChat ? null : inputWidget,
      ),
      trailingWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ChatBodyPanel(
          messages: viewModel.messages,
          isThinking: viewModel.isThinking,
          emptyState: EmptyState(onSuggestionTap: _handleSubmit),
          inputWidget: showChat ? inputWidget : null,
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
            // Not wired to a prompt since we don't have a stored prompt here.
            // Show a simple message or no-op; the wizard handles generation.
          },
        ),
        SdIconButton(
          icon: Icons.slideshow,
          semanticLabel: 'View presentation',
          onPressed: () {
            Navigator.of(context).pushNamed('/present');
          },
        ),
        SdIconButton(
          icon: Icons.palette_outlined,
          semanticLabel: 'Open remix builder',
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const RemixScreen(),
              ),
            );
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
