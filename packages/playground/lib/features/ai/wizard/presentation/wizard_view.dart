import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../chat/chat_conversation_profile.dart';
import '../chat/view/widgets/chat_input.dart';
import '../chat/view/widgets/chat_genui_panels.dart';
import '../chat/view/widgets/empty_state.dart';
import '../core/ai/services/ai_conversation_viewmodel.dart';
import '../core/viewmodel_scope.dart';

/// Single-column conversational wizard, hosted inside the editor's customization
/// sidebar.
///
/// Owns an [AiConversationViewModel] (via [ViewModelScope]) driving the GenUI
/// catalog: the model asks one question at a time, each rendered as a catalog
/// surface. The terminal summary card routes generation through
/// `GenerateDeckCommand`, which loads the resulting markdown into the editor.
class WizardView extends StatelessWidget {
  const WizardView({super.key});

  @override
  Widget build(BuildContext context) {
    // The wizard's chat/catalog UI is built on hero_ui tokens, which the
    // surrounding app already registers via HeroTheme — no extra scope needed.
    return ViewModelScope<AiConversationViewModel>(
      create: () => AiConversationViewModel(profile: chatConversationProfile()),
      child: const _WizardBody(),
    );
  }
}

class _WizardBody extends StatefulWidget {
  const _WizardBody();

  @override
  State<_WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends State<_WizardBody> {
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

  void _submit(String value) {
    if (value.trim().isEmpty) return;
    unawaited(context.read<AiConversationViewModel>().sendMessage(value));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AiConversationViewModel>();

    return Watch((context) {
      final started = viewModel.hasConversationStarted.value;
      final messages = viewModel.messages.value;
      final isThinking = viewModel.isThinking.value;

      final input = ChatInput(
        controller: _controller,
        focusNode: _focusNode,
        enabled: !isThinking,
        onSubmitted: _submit,
      );

      // Before the first message: show the empty state with the topic prompt.
      // It centers when it fits and scrolls when the sidebar is too short.
      if (!started && messages.isEmpty) {
        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: EmptyState(onSuggestionTap: _submit),
                  ),
                ),
              ),
            ),
            input,
          ],
        );
      }

      // Conversation in progress: render the current surface + input inline.
      return AiSurfacesPanel(
        controller: viewModel.controller,
        surfaceIds: viewModel.surfaceIds,
        isThinking: viewModel.isThinking,
        messages: viewModel.messages,
        inputWidget: input,
      );
    });
  }
}
