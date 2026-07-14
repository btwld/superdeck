import '../../../../core/domain/design/presentation_theme_catalog.dart';
import '../core/ai/catalog/catalog.dart';
import '../core/ai/services/ai_conversation_profile.dart';

AiConversationProfile chatConversationProfile({
  PresentationThemeCatalog? themeCatalog,
}) {
  final themes = themeCatalog ?? PresentationThemeCatalog.withDefaults();

  return AiConversationProfile(
    catalog: chatCatalogFor(themes),
    promptName: 'wizard_system',
    promptLoadErrorMessage:
        'Unable to load conversation prompts. Please restart the app.',
    themeCatalog: themes,
  );
}
