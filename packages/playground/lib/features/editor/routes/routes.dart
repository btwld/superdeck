import 'package:go_router/go_router.dart';

import '../presentation/pages/editor_bootstrap.dart';

/// The editor feature's routes, scoped at the route level; the deck globals live
/// at the app root. The editor route stays mounted beneath a pushed `/present`,
/// so these scoped objects survive the round-trip.
///
/// [EditorBootstrap] owns the file-backed deck: it awaits the last-opened file,
/// then provides the editor's scoped objects seeded with its content —
/// `DeckDocumentStore` (the Markdown authority), `DeckFileSession` (binding +
/// auto-save), `EditorStore` (nav state), `TextEditorController` (the
/// super_editor adapter), and `GenerateDeckCommand` (AI generation).
List<RouteBase> editorRoutes() => [
  GoRoute(path: '/', builder: (context, state) => const EditorBootstrap()),
];
