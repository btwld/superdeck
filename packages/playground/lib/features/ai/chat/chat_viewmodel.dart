import 'package:flutter/foundation.dart';
import 'package:playground/features/ai/core/ai/catalog/catalog.dart';
import 'package:playground/features/ai/core/ai/services/genui_conversation_viewmodel.dart';

// Re-export message types for consumers of ChatViewModel.
export 'package:playground/features/ai/chat/chat_message.dart';

class ChatViewModel extends GenUiConversationViewModel {
  /// Creates a ChatViewModel with optional dependency injection for testing.
  ///
  /// [conversationBuilder] - Builder for creating conversations. Defaults to
  /// [GenUiConversation.new] which creates real GenUI conversations.
  ChatViewModel({@visibleForTesting super.conversationBuilder})
    : super(
        catalog: chatCatalog,
        promptName: 'wizard_system',
        promptLoadErrorMessage:
            'Unable to load conversation prompts. Please restart the app.',
      );
}
