import '../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../wizard/core/ai/services/ai_conversation_profile.dart';
import 'deck_edit_catalog.dart';
import 'deck_tools_adapter.dart';

AiConversationProfile deckEditConversationProfile(DeckToolsAdapter adapter) {
  return AiConversationProfile(
    catalog: deckEditCatalog,
    promptName: 'deck_edit_system',
    promptLoadErrorMessage:
        'Unable to load deck editing prompts. Please restart the app.',
    // Required by the shared profile for the wizard's style steps. The
    // deck-edit catalog has no style surface, but the session injects the
    // theme catalog into the system prompt, which suits the updateStyle tool.
    imageStyleCatalog: PresentationImageStyleCatalog.withDefaults(),
    themeCatalog: PresentationThemeCatalog.withDefaults(),
    tools: adapter.tools,
  );
}
