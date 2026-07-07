import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/presentation_page.dart';

const _transitionDuration = Duration(milliseconds: 250);

/// The presentation feature's routes. `/present/:index` is pushed on top of the
/// editor (which stays mounted beneath it), so the deck globals at the app root
/// remain available to the SuperDeck shell rendered here.
///
/// The route fades in and out via a [CustomTransitionPage] rather than the
/// platform's default push transition. The `:index` path parameter seeds present
/// mode on the slide the author was editing.
List<RouteBase> presentationRoutes() => [
  GoRoute(
    path: '/present/:index',
    pageBuilder: (context, state) {
      final initialIndex =
          int.tryParse(state.pathParameters['index'] ?? '') ?? 0;
      return CustomTransitionPage(
        key: state.pageKey,
        transitionDuration: _transitionDuration,
        reverseTransitionDuration: _transitionDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: PresentationPage(initialIndex: initialIndex),
      );
    },
  ),
];
