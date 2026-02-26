import 'package:superdeck_ai/core/navigation/app_navigator_key.dart';
import 'package:superdeck_ai/core/tools/deck_tools_service.dart';

final deckToolsService = DeckToolsService(
  contextProvider: () => appNavigatorKey.currentContext,
);
