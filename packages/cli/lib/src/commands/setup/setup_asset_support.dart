import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

/// Resolves the filesystem path to the `tool/setup_assets/` directory bundled
/// with the `superdeck_cli` package.
///
/// Uses `package_config.json` to locate the package root, which works in both
/// normal execution and the Flutter test runner.
Future<String> resolveSetupAssetsRoot([Directory? from]) async {
  final config = await findPackageConfig(from ?? Directory.current);
  if (config == null) {
    throw StateError(
      'Cannot resolve setup assets: .dart_tool/package_config.json not found. '
      'Run `dart pub get` first.',
    );
  }

  final package = config.packages.where((p) => p.name == 'superdeck_cli');
  if (package.isEmpty) {
    throw StateError(
      'Cannot resolve setup assets: superdeck_cli not found in package config.',
    );
  }

  return path.join(package.first.root.toFilePath(), 'tool', 'setup_assets');
}
