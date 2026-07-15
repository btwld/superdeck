import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:genui/genui.dart' as genui;

import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../../../core/domain/design/presentation_image_style_catalog.dart';

final class AiConversationProfile {
  final genui.Catalog catalog;
  final String promptName;
  final String promptLoadErrorMessage;
  final PresentationImageStyleCatalog imageStyleCatalog;
  final PresentationThemeCatalog themeCatalog;
  final List<dartantic.Tool> tools;

  AiConversationProfile({
    required this.catalog,
    required this.promptName,
    required this.promptLoadErrorMessage,
    required this.imageStyleCatalog,
    required this.themeCatalog,
    Iterable<dartantic.Tool> tools = const [],
  }) : tools = List<dartantic.Tool>.unmodifiable(tools);
}
