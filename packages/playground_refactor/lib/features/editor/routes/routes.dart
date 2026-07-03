import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

import '../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../core/domain/stores/deck_customization_store.dart';
import '../../../core/domain/stores/deck_store.dart';
import '../domain/stores/editor_store.dart';
import '../domain/stores/thumbnail_store.dart';
import '../presentation/pages/editor_page.dart';

/// The editor feature's routes. Editor-scoped stores (`EditorStore`,
/// `ThumbnailStore`) are provided here at the route level; the deck globals live
/// at the app root. The editor route stays mounted beneath a pushed `/present`,
/// so these scoped stores survive the round-trip.
List<RouteBase> editorRoutes() => [
  GoRoute(
    path: '/',
    builder: (context, state) => MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => EditorStore(ctx.read<MemoryDeckLoader>()),
        ),
        // Must come after EditorStore — reads it for the active-slide trigger.
        ChangeNotifierProvider(
          create: (ctx) => ThumbnailStore(
            controller: ctx.read<DeckController>(),
            deckStore: ctx.read<DeckStore>(),
            editorStore: ctx.read<EditorStore>(),
            customization: ctx.read<DeckCustomizationStore>(),
          ),
        ),
      ],
      child: const EditorPage(),
    ),
  ),
];
