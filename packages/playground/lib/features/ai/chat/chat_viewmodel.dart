import 'package:flutter/foundation.dart';
import '../core/ai/catalog/catalog.dart';
import '../core/ai/services/genui_conversation_viewmodel.dart';

// Re-export message types for consumers of ChatViewModel.
export 'chat_message.dart';

class ChatViewModel extends GenUiConversationViewModel {
  ChatViewModel({@visibleForTesting super.agentClientFactory})
    : super(
        catalog: chatCatalog,
        promptName: 'wizard_system',
        promptLoadErrorMessage:
            'Unable to load conversation prompts. Please restart the app.',
      );
}
