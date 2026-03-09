import 'package:flutter/foundation.dart';

import '../presentation/deck_extension.dart';
import '../utils/app_initialization.dart';

/// Initializes SuperDeck dependencies and extensions.
///
/// Call this once before [runApp]:
/// ```dart
/// await initializeSuperDeck(extensions: [MyExtension()]);
/// runApp(
///   SuperDeckProvider(
///     config: DeckConfig.local(watch: true),
///     child: SuperDeckApp(theme: theme),
///   ),
/// );
/// ```
Future<void> initializeSuperDeck({
  List<DeckExtension> extensions = const <DeckExtension>[],
}) async {
  await initializeDependencies();
  for (final extension in extensions) {
    try {
      await extension.initialize();
    } catch (error, stackTrace) {
      debugPrint(
        'DeckExtension "${extension.name}" failed to initialize: '
        '$error\n$stackTrace',
      );
    }
  }
}
