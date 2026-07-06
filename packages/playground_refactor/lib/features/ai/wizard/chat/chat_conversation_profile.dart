import '../core/ai/catalog/catalog.dart';
import '../core/ai/services/ai_conversation_profile.dart';

AiConversationProfile chatConversationProfile() {
  return AiConversationProfile(
    catalog: chatCatalog,
    promptName: 'wizard_system',
    promptLoadErrorMessage:
        'Unable to load conversation prompts. Please restart the app.',
  );
}
