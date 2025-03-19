import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:window_manager/window_manager.dart';

import 'helpers/constants.dart';
import 'helpers/syntax_highlighter.dart';

Future<void> initializeDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    SyntaxHighlight.initialize(),
    initLocalStorage(),
    _initializeWindowManager(),
  ]);
}

Future<void> _initializeWindowManager() async {
  if (kIsWeb) return;

  // Must add this line.
  await windowManager.ensureInitialized();

  // final titleBarHeight = await windowManager.getTitleBarHeight();

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
