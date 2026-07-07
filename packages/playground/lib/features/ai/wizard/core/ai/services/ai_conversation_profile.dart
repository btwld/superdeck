import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:genui/genui.dart' as genui;

final class AiConversationProfile {
  AiConversationProfile({
    required this.catalog,
    required this.promptName,
    required this.promptLoadErrorMessage,
    Iterable<dartantic.Tool> tools = const [],
  }) : tools = List<dartantic.Tool>.unmodifiable(tools);

  final genui.Catalog catalog;
  final String promptName;
  final String promptLoadErrorMessage;
  final List<dartantic.Tool> tools;
}
