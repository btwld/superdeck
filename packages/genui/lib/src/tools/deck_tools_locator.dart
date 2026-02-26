import '../navigation/app_navigator_key.dart';
import './deck_tools_service.dart';

final deckToolsService = DeckToolsService(
  contextProvider: () => appNavigatorKey.currentContext,
);
