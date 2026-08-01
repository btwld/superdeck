import 'package:go_router/go_router.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../editor/domain/stores/deck_document_store.dart';
import '../../../editor/domain/stores/editor_store.dart';
import '../presentation/deck_edit_screen.dart';
import '../presentation/deck_edit_session_controller.dart';
import '../data/deck_slide_reader.dart';

/// Live, non-restorable state required by the pushed AI editing route.
final class DeckEditRouteArgs {
  const DeckEditRouteArgs({
    required this.documentStore,
    required this.editorStore,
    required this.baselineMarkdown,
    required this.baselineCustomization,
    required this.baselineSlideIndex,
  });

  final DeckDocumentStore documentStore;
  final EditorStore editorStore;
  final String baselineMarkdown;
  final DeckCustomizationSnapshot baselineCustomization;
  final int baselineSlideIndex;
}

List<RouteBase> deckEditorRoutes({
  DeckEditConversationFactory? conversationFactory,
  SlideCaptureCallback? capture,
}) => [
  GoRoute(
    path: '/ai/edit',
    redirect: (context, state) => state.extra is DeckEditRouteArgs ? null : '/',
    builder: (context, state) {
      return DeckEditScreen(
        args: state.extra! as DeckEditRouteArgs,
        conversationFactory: conversationFactory,
        capture: capture,
      );
    },
  ),
];
