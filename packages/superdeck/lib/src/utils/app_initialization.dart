import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';
import 'syntax_highlighter.dart';

Future<void> initializeDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([SyntaxHighlight.initialize(), _initializeWindowManager()]);
}

Future<void> _initializeWindowManager() async {
  if (kIsWeb || kIsTest) return;

  await windowManager.ensureInitialized();

  final newSize = Size(kResolution.width, kResolution.height);

  final windowOptions = WindowOptions(
    size: newSize,
    backgroundColor: Colors.black,
    skipTaskbar: false,
    minimumSize: newSize,
    windowButtonVisibility: true,
    title: 'Superdeck',
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await windowManager.setAspectRatio(kAspectRatio);
}
