import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/editor/routes/routes.dart';

/// The app's [GoRouter], composing each feature's routes.
///
/// `/present` is a temporary placeholder — the presentation feature is the next
/// slice and will replace it with `presentationRoutes()`.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ...editorRoutes(),
      GoRoute(
        path: '/present',
        builder: (context, state) => const _PresentationPlaceholder(),
      ),
    ],
  );
}

class _PresentationPlaceholder extends StatelessWidget {
  const _PresentationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: const Center(child: Text('Presentation — coming next')),
    );
  }
}
