import 'package:go_router/go_router.dart';

import 'package:superdeck_ai/chat/view/chat_screen.dart';
import 'package:superdeck_ai/core/navigation/app_navigator_key.dart';
import 'package:superdeck_ai/core/utils/deck_style_service.dart';
import 'package:superdeck_ai/presentation/view/creating_presentation_screen.dart';
import 'package:superdeck_ai/presentation/view/presentation_deck_host.dart';

void _applyStyleFromExtra(Object? extra) {
  if (extra case {'style': final rawStyle}) {
    final parsedStyle = DeckStyleService.setStyleFromJson(rawStyle);
    if (parsedStyle == null && rawStyle != null) {
      DeckStyleService.setStyle(null);
    }
  }
}

/// Route path constants for navigation.
abstract final class Routes {
  static const chat = '/chat';
  static const presentation = '/presentation';
  static const presentationCreating = '/presentation/creating';
}

final router = GoRouter(
  navigatorKey: appNavigatorKey,
  initialLocation: Routes.chat,
  routes: [
    ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          path: Routes.chat,
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: Routes.presentationCreating,
          builder: (context, state) => const CreatingPresentationScreen(),
        ),
        GoRoute(
          path: Routes.presentation,
          builder: (context, state) {
            _applyStyleFromExtra(state.extra);
            return const PresentationDeckHost();
          },
        ),
      ],
    ),
  ],
);
