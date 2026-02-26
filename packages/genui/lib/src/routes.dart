import 'package:go_router/go_router.dart';

import 'chat/view/chat_screen.dart';
import 'presentation/view/creating_presentation_screen.dart';
import 'presentation/view/presentation_deck_host.dart';
import 'utils/deck_style_service.dart';

void _applyStyleFromExtra(Object? extra) {
  if (extra case {'style': final rawStyle}) {
    final parsedStyle = DeckStyleService.setStyleFromJson(rawStyle);
    if (parsedStyle == null && rawStyle != null) {
      DeckStyleService.setStyle(null);
    }
  }
}

/// Route path constants for the GenUI wizard navigation.
abstract final class GenUiRoutes {
  static const chat = '/chat';
  static const presentation = '/presentation';
  static const presentationCreating = '/presentation/creating';
}

/// Keep the old name as an alias for backward compatibility during migration.
typedef Routes = GenUiRoutes;

/// Returns the list of GoRoutes for the GenUI wizard.
///
/// Consumers integrate these into their own GoRouter configuration:
/// ```dart
/// final router = GoRouter(
///   routes: [
///     ...genUiRoutes(),
///   ],
/// );
/// ```
List<RouteBase> genUiRoutes() => [
  GoRoute(
    path: GenUiRoutes.chat,
    builder: (context, state) => const ChatScreen(),
  ),
  GoRoute(
    path: GenUiRoutes.presentationCreating,
    builder: (context, state) => const CreatingPresentationScreen(),
  ),
  GoRoute(
    path: GenUiRoutes.presentation,
    builder: (context, state) {
      _applyStyleFromExtra(state.extra);

      return const PresentationDeckHost();
    },
  ),
];
