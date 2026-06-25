import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/constants/paths.dart';

/// Builds the SuperDeck workspace that matches the app's runtime paths.
DeckWorkspace runtimeDeckWorkspace() {
  final superdeckDir = Paths.superdeckDir;
  if (p.isAbsolute(superdeckDir)) {
    return DeckWorkspace(
      projectDir: p.dirname(superdeckDir),
      outputDir: p.basename(superdeckDir),
    );
  }

  return DeckWorkspace(outputDir: superdeckDir);
}
