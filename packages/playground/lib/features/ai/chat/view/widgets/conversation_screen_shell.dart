import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/ai/services/ai_conversation_viewmodel.dart';
import '../../../core/ui/ui.dart';
import 'chat_genui_panels.dart';
import 'chat_input.dart';
import 'chat_scaffold.dart';
import 'model_select.dart';

typedef ConversationEmptyStateBuilder =
    Widget Function(ValueChanged<String> onSuggestionTap);

typedef ConversationHeaderActionsBuilder =
    List<Widget> Function(
      BuildContext context,
      AiConversationViewModel viewModel,
    );

class ConversationScreenShell extends StatefulWidget {
  const ConversationScreenShell({
    super.key,
    required this.viewModel,
    required this.emptyStateBuilder,
    this.headerActionsBuilder,
  });

  final AiConversationViewModel viewModel;
  final ConversationEmptyStateBuilder emptyStateBuilder;
  final ConversationHeaderActionsBuilder? headerActionsBuilder;

  @override
  State<ConversationScreenShell> createState() =>
      _ConversationScreenShellState();
}

class _ConversationScreenShellState extends State<ConversationScreenShell> {
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
    unawaited(widget.viewModel.sendMessage(value));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Watch((context) {
      final showChat = viewModel.showChat.value;
      final isThinking = viewModel.isThinking.value;

      final inputWidget = ChatInput(
        controller: _controller,
        focusNode: _focusNode,
        enabled: !isThinking,
        onSubmitted: _handleSubmit,
      );

      return ChatScaffold(
        showChat: showChat,
        appBar: _buildHeader(
          context: context,
          viewModel: viewModel,
          showChat: showChat,
        ),
        leadingWidget: AiSurfacesPanel(
          controller: viewModel.controller,
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
            emptyState: widget.emptyStateBuilder(_handleSubmit),
            inputWidget: showChat ? inputWidget : null,
          ),
        ),
      );
    });
  }

  PreferredSizeWidget _buildHeader({
    required BuildContext context,
    required AiConversationViewModel viewModel,
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
                viewModel.model.value = value;
              },
            );
          }),
        ],
      ),
      trailing: Row(
        spacing: 8,
        children: [
          ...?widget.headerActionsBuilder?.call(context, viewModel),
          Watch((context) {
            final debugMode = viewModel.debugMode.value;
            return Row(
              spacing: 8,
              children: [
                GestureDetector(
                  onTap: () => viewModel.debugMode.value = !debugMode,
                  child: SdCaption(
                    'Show logs',
                    style: TextStyler()
                        .color(FortalTokens.gray11())
                        .fontSize(13),
                  ),
                ),
                SdSwitch(
                  selected: debugMode,
                  semanticLabel: 'Show debug logs',
                  onChanged: (value) {
                    viewModel.debugMode.value = value;
                  },
                ),
              ],
            );
          }),
          SdIconButton(
            icon: showChat ? Icons.chat : Icons.chat_outlined,
            semanticLabel: showChat ? 'Hide chat panel' : 'Show chat panel',
            onPressed: () {
              viewModel.showChat.value = !showChat;
            },
          ),
          SdButton(
            label: 'Restart',
            icon: Icons.replay_rounded,
            semanticLabel: 'Restart conversation',
            onPressed: viewModel.restartConversation,
          ),
        ],
      ),
    );
  }
}
