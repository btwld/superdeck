import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/runner.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('CLI workflow integration', () {
    test('setup then build produces complete artifact chain', () async {
      final projectDir = await _createProject();
      await _inProject(projectDir, () async {
        final runner = SuperDeckRunner();
        expect(await runner.run(['setup']), ExitCode.success.code);
        await _expectSetup(projectDir);
        expect(await runner.run(['build']), ExitCode.success.code);
        await _expectBuild(projectDir);
      });
    });

    test('setup is idempotent when re-run after build', () async {
      final projectDir = await _createProject();
      await _inProject(projectDir, () async {
        final runner = SuperDeckRunner();
        expect(await runner.run(['setup']), ExitCode.success.code);
        expect(await runner.run(['build']), ExitCode.success.code);
        expect(await runner.run(['setup']), ExitCode.success.code);

        final pubspec = await _read(projectDir, 'pubspec.yaml');
        final entitlements = await _read(
          projectDir,
          'macos/Runner/DebugProfile.entitlements',
        );
        expect(_count(pubspec, '.superdeck/'), 1);
        expect(
          _count(
            entitlements,
            'com.apple.security.files.user-selected.read-write',
          ),
          1,
        );
      });
    });
  });
}

Future<Directory> _createProject() async {
  final dir = await createTempDirAsync();
  createTestPubspec(dir);
  final runnerDir = Directory(path.join(dir.path, 'macos', 'Runner'));
  await runnerDir.create(recursive: true);
  for (final name in ['DebugProfile.entitlements', 'Release.entitlements']) {
    await File(path.join(runnerDir.path, name)).writeAsString(_entitlements);
  }
  await File(path.join(dir.path, 'slides.md')).writeAsString(_slides);
  return dir;
}

Future<void> _expectSetup(Directory dir) async {
  expect(await _read(dir, 'pubspec.yaml'), contains('.superdeck/'));
  expect(Directory(path.join(dir.path, '.superdeck')).existsSync(), isTrue);
  expect(
    await _read(dir, 'macos/Runner/DebugProfile.entitlements'),
    allOf(
      contains('com.apple.security.files.user-selected.read-write'),
      contains('com.apple.security.files.downloads.read-write'),
      contains('<false/>'),
    ),
  );
}

Future<void> _expectBuild(Directory dir) async {
  final workspace = DeckWorkspace(projectDir: dir.path);
  expect([
    workspace.superdeckDir.existsSync(),
    workspace.deckJson.existsSync(),
    workspace.buildStatusJson.existsSync(),
  ], everyElement(isTrue));
  final deck = jsonDecode(await workspace.deckJson.readAsString()) as List;
  final status =
      jsonDecode(await workspace.buildStatusJson.readAsString()) as Map;
  expect(deck, hasLength(2));
  expect(status['status'], 'success');
  expect(status['slideCount'], 2);
  expect(await _read(dir, 'pubspec.yaml'), contains('.superdeck/'));
}

Future<T> _inProject<T>(Directory dir, Future<T> Function() body) async {
  final previousDir = Directory.current;
  Directory.current = dir;
  try {
    return await body();
  } finally {
    Directory.current = previousDir;
  }
}

Future<String> _read(Directory dir, String relativePath) =>
    File(path.join(dir.path, relativePath)).readAsString();

int _count(String contents, String pattern) =>
    RegExp(RegExp.escape(pattern)).allMatches(contents).length;

const _entitlements =
    '<plist version="1.0"><dict><key>com.apple.security.app-sandbox</key>'
    '<true/></dict></plist>';
const _slides =
    '---\ntitle: Cover\n---\n# SuperDeck Workflow\n\n'
    'A complete CLI build.\n\n---\ntitle: Layout\n---\n@section\n@block\n\n'
    '## Agenda\n\n- Setup\n- Build\n- Load\n';
