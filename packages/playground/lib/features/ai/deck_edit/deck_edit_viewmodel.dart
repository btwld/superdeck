import 'package:flutter/foundation.dart';

import '../core/ai/catalog/catalog.dart';
import '../core/ai/services/genui_conversation_viewmodel.dart';
import '../core/tools/deck_tools_adapter.dart';

class DeckEditViewModel extends GenUiConversationViewModel {
  DeckEditViewModel({
    required DeckToolsAdapter toolsAdapter,
    @visibleForTesting super.conversationBuilder,
  }) : super(
         catalog: chatCatalog,
         promptName: 'deck_edit_system',
         promptLoadErrorMessage:
             'Unable to load deck edit prompts. Please restart the app.',
         additionalTools: toolsAdapter.tools,
       );
}
