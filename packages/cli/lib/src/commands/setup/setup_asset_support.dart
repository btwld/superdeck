import 'dart:isolate';

import 'package:path/path.dart' as path;

Future<String> resolveSetupAssetsRoot() async {
  final packageUri = (await Isolate.resolvePackageUri(
    Uri.parse('package:superdeck_cli/runner.dart'),
  ))!;

  final libPath = path.dirname(packageUri.toFilePath());
  return path.join(path.dirname(libPath), 'tool', 'setup_assets');
}
