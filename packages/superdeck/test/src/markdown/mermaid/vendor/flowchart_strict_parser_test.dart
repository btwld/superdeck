import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Path (relative to the `superdeck` package root) of the vendored parser.
const _vendorFilePath =
    'lib/src/markdown/mermaid/vendor/flowchart_strict_parser.dart';

/// Path (relative to the `superdeck` package root) of the workspace lockfile
/// that pins the resolved `mermaid_core` version.
const _workspaceLockfilePath = '../../pubspec.lock';

final _headerVersionPattern = RegExp(r'Vendored from mermaid_core ([\d.]+),');

final _lockfileVersionPattern = RegExp(
  r'\n  mermaid_core:[\s\S]*?\n    version: "([\d.]+)"',
);

void main() {
  test(
    'vendored flowchart parser header matches the resolved mermaid_core version',
    () {
      final headerVersion = _headerVersionPattern
          .firstMatch(File(_vendorFilePath).readAsStringSync())
          ?.group(1);
      expect(
        headerVersion,
        isNotNull,
        reason:
            'Could not find a "Vendored from mermaid_core X.Y.Z" header '
            'comment in $_vendorFilePath.',
      );

      final resolvedVersion = _lockfileVersionPattern
          .firstMatch(File(_workspaceLockfilePath).readAsStringSync())
          ?.group(1);
      expect(
        resolvedVersion,
        isNotNull,
        reason:
            'Could not find a resolved mermaid_core version in '
            '$_workspaceLockfilePath.',
      );

      expect(
        headerVersion,
        resolvedVersion,
        reason:
            'The workspace resolves mermaid_core $resolvedVersion but '
            '$_vendorFilePath was forked from mermaid_core $headerVersion. '
            'Re-sync the fork against the resolved version and update the '
            'header comment.',
      );
    },
  );
}
