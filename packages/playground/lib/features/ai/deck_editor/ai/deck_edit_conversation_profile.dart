import '../../wizard/core/ai/services/ai_conversation_profile.dart';
import 'deck_edit_catalog.dart';
import 'deck_tools_adapter.dart';

AiConversationProfile deckEditConversationProfile(DeckToolsAdapter adapter) {
  return AiConversationProfile(
    catalog: deckEditCatalog,
    promptName: 'deck_edit_system',
    promptLoadErrorMessage:
        'Unable to load deck editing prompts. Please restart the app.',
    tools: adapter.tools,
  );
}
