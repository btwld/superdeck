import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/data/data_sources/memory_deck_loader.dart';
import '../../agent/domain/commands/generate_deck_command.dart';
import '../domain/stores/editor_store.dart';
import '../presentation/pages/editor_page.dart';
import '../utils/text_editor_controller.dart';

/// The editor feature's routes, scoped at the route level; the deck globals live
/// at the app root. The editor route stays mounted beneath a pushed `/present`,
/// so these scoped objects survive the round-trip.
///
/// - `EditorStore` holds the shared nav state (active slide).
/// - `TextEditorController` owns the super_editor document; it's eager so it
///   seeds the live preview and registers its caret↔store sync before the view
///   mounts.
/// - `GenerateDeckCommand` drives the controller through the `MarkdownEditor`
///   port.
List<RouteBase> editorRoutes() => [
  GoRoute(
    path: '/',
    builder: (context, state) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EditorStore()),
        Provider<TextEditorController>(
          lazy: false,
          create: (ctx) => TextEditorController(
            editorStore: ctx.read<EditorStore>(),
            deckLoader: ctx.read<MemoryDeckLoader>(),
          ),
          dispose: (_, controller) => controller.dispose(),
        ),
        ListenableProvider<GenerateDeckCommand>(
          create: (ctx) => GenerateDeckCommand(
            editor: ctx.read<TextEditorController>(),
          ),
          dispose: (_, command) => command.dispose(),
        ),
      ],
      child: const EditorPage(),
    ),
  ),
];
