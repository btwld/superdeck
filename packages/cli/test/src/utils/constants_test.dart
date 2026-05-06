import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:superdeck_cli/src/utils/constants.dart';
import 'package:test/test.dart';

void main() {
  group('packageVersion', () {
    test('matches the CLI package version', () async {
      expect(await _readPubspecVersion(File('pubspec.yaml')), packageVersion);
    });

    test('matches the superdeck package version', () async {
      expect(
        await _readPubspecVersion(
          File(path.join('..', 'superdeck', 'pubspec.yaml')),
        ),
        packageVersion,
      );
    });
  });
}

Future<String> _readPubspecVersion(File pubspecFile) async {
  final contents = await pubspecFile.readAsString();
  final match = RegExp(
    r'^version:\s*(\S+)',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    fail('Missing version in ${pubspecFile.path}');
  }

  return match.group(1)!;
}
