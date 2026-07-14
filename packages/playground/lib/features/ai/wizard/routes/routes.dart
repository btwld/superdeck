import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../quick_agent/presentation/pages/generation_lab_page.dart';
import '../presentation/wizard_page.dart';

/// Standalone Wizard playground route.
List<RouteBase> wizardRoutes() => [
  GoRoute(path: '/', builder: (context, state) => const WizardPage()),
  if (kDebugMode)
    GoRoute(
      path: '/debug/generation',
      builder: (context, state) => const GenerationLabPage(),
    ),
];
