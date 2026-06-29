import '../core/ai/catalog/remix_catalog.dart';
import '../core/ai/services/ai_conversation_profile.dart';

AiConversationProfile remixConversationProfile() {
  return AiConversationProfile(
    catalog: remixCatalog,
    promptName: 'remix_system',
    promptLoadErrorMessage:
        'Unable to load Remix prompts. Please restart the app.',
  );
}
