import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'bootstrap/genui_bootstrap.dart';
import 'chat/view/chat_screen.dart';
import 'presentation/view/creating_presentation_screen.dart';
import 'utils/deck_style_service.dart';
import 'utils/style_builder.dart';

const _kCanRunProcess =
    kDebugMode && !kIsWeb && !bool.fromEnvironment('FLUTTER_TEST');

const _kDefaultPresentationConfig = _kCanRunProcess
    ? DeckConfig.local()
    : DeckConfig.bundle();

class _DefaultPresentationDeck extends StatelessWidget {
  const _DefaultPresentationDeck();

  @override
  Widget build(BuildContext context) {
    return SuperDeckProvider(
      config: _kDefaultPresentationConfig,
      builder: (context, deck) {
        return Watch((context) {
          final style = DeckStyleService.style.value;
          final theme = buildDeckThemeFromStyle(style);
          return SuperDeckApp(deck: deck, theme: theme);
        });
      },
    );
  }
}

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
          const _DefaultPresentationDeck();
      return GenUiBootstrapScope(child: child);
    },
  ),
];
