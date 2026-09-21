import 'package:go_router/go_router.dart';

import '../presentation/wizard_page.dart';

/// The Wizard is the playground's authoring flow and its entry route.
List<RouteBase> wizardRoutes() => [
  GoRoute(path: '/', builder: (context, state) => const WizardPage()),
];
