import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:superdeck_cli/runner.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('CLI publish workflow', () {
    test('publish creates a commit on target branch without push', () async {
      final projectDir = await _createPublishableProject();

      expect(await _publish(projectDir), ExitCode.success.code);

      await _git(projectDir, [
        'show-ref',
        '--verify',
        'refs/heads/$_targetBranch',
      ]);
      expect(
        await _gitLines(projectDir, [
          'ls-tree',
          '-r',
          '--name-only',
          _targetBranch,
        ]),
        unorderedEquals(<String>[
          '.nojekyll',
          'assets/.superdeck/superdeck.json',
          'flutter_bootstrap.js',
          'index.html',
          'main.dart.js',
        ]),
      );
      await _expectCleanWorkingTree(projectDir);
      await _expectNoPublishWorktree(projectDir);
    });

    test('publish is a successful no-op when nothing changed', () async {
      final projectDir = await _createPublishableProject();

      expect(await _publish(projectDir), ExitCode.success.code);
      final firstCommit = await _git(projectDir, ['rev-parse', _targetBranch]);

      expect(await _publish(projectDir), ExitCode.success.code);
      expect(
        await _git(projectDir, ['rev-parse', _targetBranch]),
        firstCommit,
      );
      await _expectCleanWorkingTree(projectDir);
      await _expectNoPublishWorktree(projectDir);
    });
  });
}

Future<Directory> _createPublishableProject() async {
  final dir = await _createProject();

  await _inProject(dir, () async {
    final runner = SuperDeckRunner();
    expect(await runner.run(['setup']), ExitCode.success.code);
    expect(await runner.run(['build']), ExitCode.success.code);
  });
  await _createBuiltWebOutput(dir);
  await _initGitRepository(dir);

  return dir;
}

Future<Directory> _createProject() async {
  final dir = await createTempDirAsync();
  createTestPubspec(dir);
  await File(
    path.join(createWebDirectory(dir).path, 'index.html'),
  ).writeAsString(_indexHtml);

  final runnerDir = Directory(path.join(dir.path, 'macos', 'Runner'));
  await runnerDir.create(recursive: true);
  for (final name in ['DebugProfile.entitlements', 'Release.entitlements']) {
    await File(path.join(runnerDir.path, name)).writeAsString(_entitlements);
  }
  await File(path.join(dir.path, 'slides.md')).writeAsString(_slides);

  return dir;
}

Future<void> _createBuiltWebOutput(Directory dir) async {
  final buildDir = Directory(path.join(dir.path, 'build', 'web'));
  await buildDir.create(recursive: true);
  await File(path.join(buildDir.path, 'index.html')).writeAsString(_indexHtml);
  await File(
    path.join(buildDir.path, 'flutter_bootstrap.js'),
  ).writeAsString('// fake Flutter bootstrap for publish integration test\n');
  await File(
    path.join(buildDir.path, 'main.dart.js'),
  ).writeAsString('// fake compiled Flutter web bundle\n');

  final superdeckAssets = Directory(
    path.join(buildDir.path, 'assets', '.superdeck'),
  );
  await superdeckAssets.create(recursive: true);
  await File(path.join(dir.path, '.superdeck', 'superdeck.json')).copy(
    path.join(superdeckAssets.path, 'superdeck.json'),
  );
}

Future<void> _initGitRepository(Directory dir) async {
  await _git(dir, ['init']);
  await _git(dir, ['symbolic-ref', 'HEAD', 'refs/heads/main']);
  await _git(dir, ['config', 'user.email', 'test@example.com']);
  await _git(dir, ['config', 'user.name', 'SuperDeck Test']);
  await _git(dir, ['add', '.']);
  await _git(dir, ['commit', '-m', 'Initial test project']);
  await _expectCleanWorkingTree(dir);
}

Future<int> _publish(Directory dir) async => _inProject(
  dir,
  () => SuperDeckRunner().run([
    'publish',
    '--no-push',
    '--no-build',
    '--branch',
    _targetBranch,
  ]),
);

Future<void> _expectCleanWorkingTree(Directory dir) async {
  expect(await _git(dir, ['status', '--porcelain']), isEmpty);
}

Future<void> _expectNoPublishWorktree(Directory dir) async {
  expect(
    await _git(dir, ['worktree', 'list', '--porcelain']),
    isNot(contains('superdeck_publish_')),
  );
}

Future<List<String>> _gitLines(Directory dir, List<String> args) async {
  final output = await _git(dir, args);
  return output.split('\n').where((line) => line.isNotEmpty).toList();
}

Future<String> _git(Directory dir, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: dir.path);
  if (result.exitCode != 0) {
    fail(
      'git ${args.join(' ')} failed with exit code ${result.exitCode}: '
      '${result.stderr}',
    );
  }

  return result.stdout.toString().trim();
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

const _targetBranch = 'gh-pages-test';
const _indexHtml =
    '<!DOCTYPE html><html><head><base href="\$FLUTTER_BASE_HREF"></head>'
    '<body><script src="flutter_bootstrap.js" async></script></body></html>';
const _entitlements =
    '<plist version="1.0"><dict><key>com.apple.security.app-sandbox</key>'
    '<true/></dict></plist>';
const _slides = '---\ntitle: Cover\n---\n# SuperDeck Publish\n\n'
    'A publish workflow test.\n\n---\ntitle: Layout\n---\n@section\n@block\n\n'
    '## Agenda\n\n- Setup\n- Build\n- Publish\n';
