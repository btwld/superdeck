import 'package:go_router/go_router.dart';

import '../features/editor/routes/routes.dart';
import '../features/presentation/routes/routes.dart';

/// The app's [GoRouter], composing each feature's routes.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ...editorRoutes(),
      ...presentationRoutes(),
    ],
  );
}
