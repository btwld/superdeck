import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

final _superdeckCliPackageName = RegExp(
  r'^\s*name:\s*superdeck_cli\s*$',
  multiLine: true,
);

/// Resolves the filesystem path to the `tool/setup_assets/` directory bundled
/// with the `superdeck_cli` package.
///
/// Uses the running CLI isolate's package resolution instead of the target
/// app's current working directory, so `superdeck setup` works before the app
/// adds `superdeck_cli` as a dependency.
///
/// Falls back to searching from [Directory.current] when the Isolate API is
/// unavailable (e.g. in `flutter test` VM contexts).
String resolveSetupAssetsRoot() {
  // Primary path: standard synchronous isolate-based resolution.
  try {
    final packageLibUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:superdeck_cli/'),
    );
    if (packageLibUri != null && packageLibUri.scheme == 'file') {
      final assetsDir = Directory.fromUri(
        packageLibUri.resolve('../tool/setup_assets/'),
      );
      if (assetsDir.existsSync()) {
        return path.normalize(assetsDir.path);
      }
    }
  } on UnsupportedError {
    // Some VM modes (e.g. flutter test) do not support resolvePackageUriSync.
    // Fall through to the directory search below.
  }

  // Fallback: walk up from Directory.current looking for the superdeck_cli
  // package root.  This works in test environments where the working directory
  // is the package root and the source tree is present (e.g. melos-managed
  // monorepo development with flutter test).
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final pubspecFile = File(path.join(dir.path, 'pubspec.yaml'));
    if (pubspecFile.existsSync() && _isSuperdeckCliPubspec(pubspecFile)) {
      final assetsDir =
          Directory(path.join(dir.path, 'tool', 'setup_assets'));
      if (assetsDir.existsSync()) {
        return path.normalize(assetsDir.path);
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  throw const FileSystemException(
    'Cannot resolve setup assets: superdeck_cli must be run from a '
    'pub-based package install (`dart pub global activate superdeck_cli` '
    'or a project dev dependency).',
  );
}

bool _isSuperdeckCliPubspec(File pubspecFile) {
  try {
    return _superdeckCliPackageName.hasMatch(pubspecFile.readAsStringSync());
  } on FileSystemException {
    return false;
  }
}
