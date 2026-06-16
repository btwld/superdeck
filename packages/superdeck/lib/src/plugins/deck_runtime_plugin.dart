import 'package:superdeck_core/superdeck_core.dart';

import 'deck_action.dart';

/// Base class for plugins that contribute commands to the SuperDeck app shell.
///
/// Runtime plugins run inside the Flutter app. They register [DeckAction]s that
/// can open UI, inspect active deck state, or perform app-shell commands.
abstract base class DeckRuntimePlugin extends DeckPlugin {
  /// Creates a runtime plugin.
  const DeckRuntimePlugin();

  /// Actions contributed to the SuperDeck shell.
  ///
  /// The app resolves this list during build. Keep this getter cheap and store
  /// plugin configuration as fields on the plugin object.
  List<DeckAction> get actions;
}
