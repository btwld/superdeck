import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/data/data_sources/memory_deck_loader.dart';
import '../domain/stores/editor_store.dart';
import '../presentation/pages/editor_page.dart';

/// The editor feature's routes. The editor-scoped `EditorStore` is provided here
/// at the route level; the deck globals live at the app root. The editor route
/// stays mounted beneath a pushed `/present`, so this scoped store survives the
/// round-trip.
List<RouteBase> editorRoutes() => [
  GoRoute(
    path: '/',
    builder: (context, state) => ChangeNotifierProvider(
      create: (ctx) => EditorStore(ctx.read<MemoryDeckLoader>()),
      child: const EditorPage(),
    ),
  ),
];
