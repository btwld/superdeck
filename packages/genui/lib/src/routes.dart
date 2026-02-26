import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'chat/view/chat_screen.dart';
import 'presentation/view/creating_presentation_screen.dart';
import 'presentation/view/presentation_deck_host.dart';
import 'bootstrap/genui_bootstrap.dart';
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
///
/// Optional builders let hosts override the default screens while preserving
/// GenUI bootstrap initialization.
List<RouteBase> genUiRoutes({
  Widget Function(BuildContext context, GoRouterState state)? chatBuilder,
  Widget Function(BuildContext context, GoRouterState state)? creatingBuilder,
  Widget Function(BuildContext context, GoRouterState state)?
  presentationBuilder,
}) => [
  GoRoute(
    path: GenUiRoutes.chat,
    builder: (context, state) {
      final child = chatBuilder?.call(context, state) ?? const ChatScreen();
      return GenUiBootstrapScope(child: child);
    },
  ),
  GoRoute(
    path: GenUiRoutes.presentationCreating,
    builder: (context, state) {
      final child =
          creatingBuilder?.call(context, state) ??
          const CreatingPresentationScreen();
      return GenUiBootstrapScope(child: child);
    },
  ),
  GoRoute(
    path: GenUiRoutes.presentation,
    builder: (context, state) {
      _applyStyleFromExtra(state.extra);

      final child =
          presentationBuilder?.call(context, state) ??
          const PresentationDeckHost();
      return GenUiBootstrapScope(child: child);
    },
  ),
];
