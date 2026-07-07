import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

import '../utils/constants.dart';

/// Default workspace for the auto-selected dev loader.
///
/// Walks up from the current directory to the nearest ancestor containing
/// `pubspec.yaml`; falls back to the plain cwd workspace when none is found or
/// the current runtime cannot access the local filesystem.
DeckWorkspace resolveDefaultWorkspace() {
  if (!kCanRunProcess) return DeckWorkspace();

  final root = findProjectRoot(Directory.current);
  return root == null ? DeckWorkspace() : DeckWorkspace(projectDir: root.path);
}

@visibleForTesting
Directory? findProjectRoot(Directory start) {
  var dir = start.absolute;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;

    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}
