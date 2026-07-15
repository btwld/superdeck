import '../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../core/domain/design/presentation_theme_catalog.dart';
import '../core/ai/catalog/catalog.dart';
import '../core/ai/services/ai_conversation_profile.dart';

AiConversationProfile chatConversationProfile({
  PresentationImageStyleCatalog? imageStyleCatalog,
  PresentationThemeCatalog? themeCatalog,
}) {
  final imageStyles =
      imageStyleCatalog ?? PresentationImageStyleCatalog.withDefaults();
  final themes = themeCatalog ?? PresentationThemeCatalog.withDefaults();

  return AiConversationProfile(
    catalog: chatCatalogFor(themes, imageStyleCatalog: imageStyles),
    promptName: 'wizard_system',
    promptLoadErrorMessage:
        'Unable to load conversation prompts. Please restart the app.',
    imageStyleCatalog: imageStyles,
    themeCatalog: themes,
  );
}
