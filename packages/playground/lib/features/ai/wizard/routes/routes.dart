import 'package:go_router/go_router.dart';

import '../presentation/wizard_page.dart';

/// Standalone Wizard playground route.
List<RouteBase> wizardRoutes() => [
  GoRoute(path: '/', builder: (context, state) => const WizardPage()),
];
