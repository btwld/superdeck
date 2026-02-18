import 'package:superdeck_core/superdeck_core.dart';

DeckConfiguration resolveConfiguration(DeckConfiguration? override) {
  // Web runtimes do not read local YAML files.
  // Runtime deck configuration is loaded from bundled deck JSON.
  return override ?? DeckConfiguration();
}
