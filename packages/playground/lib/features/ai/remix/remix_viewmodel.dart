import 'package:flutter/foundation.dart';
import 'package:playground/features/ai/core/ai/catalog/remix_catalog.dart';
import 'package:playground/features/ai/core/ai/services/genui_conversation_viewmodel.dart';

// Re-export message types for consumers of RemixViewModel.
export 'package:playground/features/ai/chat/chat_message.dart';

class RemixViewModel extends GenUiConversationViewModel {
  RemixViewModel({@visibleForTesting super.conversationBuilder})
    : super(
        catalog: remixCatalog,
        promptName: 'remix_system',
        promptLoadErrorMessage:
            'Unable to load Remix prompts. Please restart the app.',
      );
}
