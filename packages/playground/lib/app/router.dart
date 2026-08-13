import 'package:go_router/go_router.dart';

import '../features/ai/deck_editor/data/deck_slide_reader.dart';
import '../features/ai/deck_editor/presentation/deck_edit_session_controller.dart';
import '../features/ai/deck_editor/routes/routes.dart';
import '../features/ai/wizard/routes/routes.dart';
import '../features/editor/routes/routes.dart';
import '../features/presentation/routes/routes.dart';

/// The app's [GoRouter], composing each feature's routes.
GoRouter createRouter({
  String initialLocation = '/',
  DeckEditConversationFactory? deckEditConversationFactory,
  SlideCaptureCallback? deckEditCapture,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ...wizardRoutes(),
      ...editorRoutes(),
      ...deckEditorRoutes(
        conversationFactory: deckEditConversationFactory,
        capture: deckEditCapture,
      ),
      ...presentationRoutes(),
    ],
  );
}
