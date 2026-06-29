import 'package:flutter/material.dart';
import '../chat_conversation_profile.dart';
import 'widgets/conversation_screen_shell.dart';
import 'widgets/empty_state.dart';
import '../../core/ai/services/ai_conversation_viewmodel.dart';
import '../../core/ui/ui.dart';
import '../../core/viewmodel_scope.dart';
import '../../remix/view/remix_screen.dart';

/// Main chat screen for the wizard-based presentation builder.
///
/// Provides a two-panel interface with GenUI surfaces on the left
/// and chat messages on the right.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelScope<AiConversationViewModel>(
      create: () => AiConversationViewModel(profile: chatConversationProfile()),
      child: const _ChatScreenScaffold(),
    );
  }
}

class _ChatScreenScaffold extends StatelessWidget {
  const _ChatScreenScaffold();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AiConversationViewModel>();
    return ConversationScreenShell(
      viewModel: viewModel,
      emptyStateBuilder: (onSuggestionTap) =>
          EmptyState(onSuggestionTap: onSuggestionTap),
      headerActionsBuilder: (context, viewModel) => _headerActions(context),
    );
  }

  List<Widget> _headerActions(BuildContext context) {
    return [
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
            MaterialPageRoute<void>(builder: (_) => const RemixScreen()),
          );
        },
      ),
    ];
  }
}
