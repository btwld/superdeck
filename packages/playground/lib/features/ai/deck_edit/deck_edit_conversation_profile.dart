import '../core/ai/catalog/catalog.dart';
import '../core/ai/services/ai_conversation_profile.dart';
import '../core/tools/deck_tools_adapter.dart';

AiConversationProfile deckEditConversationProfile({
  required DeckToolsAdapter toolsAdapter,
}) {
  return AiConversationProfile(
    catalog: chatCatalog,
    promptName: 'deck_edit_system',
    promptLoadErrorMessage:
        'Unable to load deck edit prompts. Please restart the app.',
    tools: toolsAdapter.tools,
  );
}
