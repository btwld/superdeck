import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

import '../domain/stores/presentation_store.dart';
import '../presentation/pages/presentation_page.dart';

const _transitionDuration = Duration(milliseconds: 250);

/// The presentation feature's routes. `/present` is pushed on top of the editor
/// (which stays mounted beneath it), so the deck globals at the app root remain
/// available here.
///
/// The route fades in and out via a [CustomTransitionPage] rather than the
/// platform's default push transition.
///
/// The scoped [PresentationStore] is provided at the route and seeded from the
/// editor's active slide, passed through `GoRouterState.extra`, so present mode
/// opens on the slide the author was editing.
List<RouteBase> presentationRoutes() => [
  GoRoute(
    path: '/present',
    pageBuilder: (context, state) {
      final initialIndex = state.extra is int ? state.extra as int : 0;
      return CustomTransitionPage(
        key: state.pageKey,
        transitionDuration: _transitionDuration,
        reverseTransitionDuration: _transitionDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: ChangeNotifierProvider(
          create: (ctx) => PresentationStore(
            ctx.read<DeckController>(),
            initialIndex: initialIndex,
          ),
          child: const PresentationPage(),
        ),
      );
    },
  ),
];
