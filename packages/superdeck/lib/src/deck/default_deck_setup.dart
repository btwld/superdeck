import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

import '../utils/constants.dart';
import 'loaders/bundled_deck_loader.dart';
import 'loaders/file_deck_loader.dart';

Directory? Function(Directory start)? _debugFindRootOverride;

@visibleForTesting
void debugSetDefaultDeckSetupFindRootOverride(
  Directory? Function(Directory start)? findRoot,
) {
  _debugFindRootOverride = findRoot;
}

/// Resolves the default [DeckLoader] and [DeckWorkspace] for `SuperDeckApp`
/// when no explicit `deckLoader` is provided.
///
/// - `canRunProcess == false` (release/profile/web/test): [BundledDeckLoader].
/// - Explicit [workspace]: trusted as-is; [FileDeckLoader] on debug IO.
/// - Otherwise walk up from [Directory.current] to the nearest ancestor with
///   `pubspec.yaml`: found -> [FileDeckLoader] rooted there; not found (for
///   example, a directly-launched debug app with an unrelated cwd) ->
///   [BundledDeckLoader].
///
/// The fallback keys only on "no project root discoverable", never on missing
/// `.superdeck/` output. [FileDeckLoader] keeps its recoverable wait so
/// `flutter run` can start before `superdeck build --watch`.
({DeckLoader loader, DeckWorkspace workspace}) resolveDeckSetup({
  DeckWorkspace? workspace,
  bool canRunProcess = kCanRunProcess,
  Directory? Function(Directory start) findRoot = findProjectRoot,
}) {
  if (!canRunProcess) {
    final resolvedWorkspace = workspace ?? DeckWorkspace();

    return (
      loader: BundledDeckLoader(workspace: resolvedWorkspace),
      workspace: resolvedWorkspace,
    );
  }

  if (workspace != null) {
    return (loader: FileDeckLoader(workspace: workspace), workspace: workspace);
  }

  final root = (_debugFindRootOverride ?? findRoot)(Directory.current);
  if (root == null) {
    final resolvedWorkspace = DeckWorkspace();
    assert(() {
      debugPrint(
        '[SuperDeck] No project root found from '
        '"${Directory.current.path}"; falling back to bundled assets.',
      );

      return true;
    }());

    return (
      loader: BundledDeckLoader(workspace: resolvedWorkspace),
      workspace: resolvedWorkspace,
    );
  }

  final resolvedWorkspace = DeckWorkspace(projectDir: root.path);
  assert(() {
    debugPrint(
      '[SuperDeck] Project root found at "${root.path}"; using file loader.',
    );

    return true;
  }());

  return (
    loader: FileDeckLoader(workspace: resolvedWorkspace),
    workspace: resolvedWorkspace,
  );
}

@visibleForTesting
Directory? findProjectRoot(Directory start) {
  var dir = start.absolute;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir;
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}
