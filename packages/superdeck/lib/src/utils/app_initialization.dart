import 'package:flutter/widgets.dart';

import 'syntax_highlighter.dart';

Future<void> initializeDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SyntaxHighlight.initialize();
}
