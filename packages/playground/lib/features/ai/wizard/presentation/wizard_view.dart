import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as prov show Provider;

import '../chat/view/widgets/chat_input.dart';
import '../chat/view/widgets/chat_genui_panels.dart';
import '../chat/view/widgets/empty_state.dart';
import '../core/ai/services/ai_conversation_viewmodel.dart';
import '../core/ai/services/prompt_builder.dart';
import '../core/viewmodel_scope.dart';
import 'wizard_generation_controller.dart';
import 'wizard_selection_review.dart';

/// Single-column conversational Wizard hosted by its standalone playground page.
///
/// Renders the GenUI Wizard supplied by the nearest application-owned
/// [ViewModelScope]. The application takes over for review, planning, and
/// composition while preserving the accepted setup choices.
class WizardView extends StatelessWidget {
  const WizardView({super.key});

  @override
  Widget build(BuildContext context) => const _WizardBody();
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
    unawaited(
      ViewModelScope.of<AiConversationViewModel>(context).sendMessage(value),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModelScope.of<AiConversationViewModel>(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final surfaceController = viewModel.controller;
        final started = surfaceController != null;
        final isThinking = viewModel.isThinking.value;

        if (viewModel.wizardState.isReviewReady) {
          return WizardSelectionReview(
            wizardContext: viewModel.wizardState.context,
            themeCatalog: viewModel.themeCatalog,
            onStartOver: viewModel.restartConversation,
            onCreateOutline: () {
              final request = buildPromptFromWizardContext(
                viewModel.wizardState.context,
              );
              unawaited(
                prov.Provider.of<WizardGenerationController>(
                  context,
                  listen: false,
                ).createOutline(request),
              );
            },
          );
        }

        final input = ChatInput(
          controller: _controller,
          focusNode: _focusNode,
          enabled: !isThinking,
          hintText: !started
              ? 'Describe your presentation topic…'
              : 'Add a detail or ask for a change…',
          onSubmitted: _submit,
        );

        // Before the first message: show the empty state with the topic prompt.
        // It centers when it fits and scrolls when the sidebar is too short.
        if (!started) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: EmptyState(input: input),
              ),
            ),
          );
        }

        // Conversation in progress: render the current surface + input inline.
        return AiSurfacesPanel(
          controller: surfaceController,
          surfaceIds: viewModel.surfaceIds.value,
          isThinking: isThinking,
          errorMessage: viewModel.errorMessage,
          inputWidget: input,
        );
      },
    );
  }
}
