import 'package:flutter/foundation.dart';
import '../core/ai/catalog/catalog.dart';
import '../core/ai/services/genui_conversation_viewmodel.dart';

// Re-export message types for consumers of ChatViewModel.
export 'chat_message.dart';

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
