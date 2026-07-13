import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'src/layout_showcase/layout_showcase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SignalsObserver.instance = null;
  await SuperDeckApp.initialize();

  runApp(const LayoutShowcaseApp());
}
