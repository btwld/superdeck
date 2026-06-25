import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Returns the base directory for SuperDeck storage on native platforms.
Future<String> resolveBaseDir() async {
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return '.superdeck';
  }

  try {
    final appSupportDir = await getApplicationSupportDirectory();
    return p.join(appSupportDir.path, '.superdeck');
  } catch (_) {
    return '.superdeck';
  }
}
