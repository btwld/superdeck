import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

/// Resolves the filesystem path to the `tool/setup_assets/` directory bundled
/// with the `superdeck_cli` package.
///
/// Uses the running CLI isolate's package resolution instead of the target
/// app's current working directory, so `superdeck setup` works before the app
/// adds `superdeck_cli` as a dependency.
String resolveSetupAssetsRoot() {
  final packageLibUri = Isolate.resolvePackageUriSync(
    Uri.parse('package:superdeck_cli/'),
  );
  if (packageLibUri == null || packageLibUri.scheme != 'file') {
    throw FileSystemException(
      'Cannot resolve setup assets: superdeck_cli must be run from a '
      'pub-based package install (`dart pub global activate superdeck_cli` '
      'or a project dev dependency).',
      packageLibUri?.toString(),
    );
  }

  final assetsDir = Directory.fromUri(
    packageLibUri.resolve('../tool/setup_assets/'),
  );
  if (!assetsDir.existsSync()) {
    throw FileSystemException(
      'Cannot resolve setup assets: bundled setup assets were not found.',
      path.normalize(assetsDir.path),
    );
  }

  return path.normalize(assetsDir.path);
}
