import 'package:go_router/go_router.dart';

import '../presentation/saved_decks_page.dart';

/// Decks already saved to the SuperDeck folder.
List<RouteBase> libraryRoutes() => [
  GoRoute(path: '/decks', builder: (context, state) => const SavedDecksPage()),
];
