import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_deploy/src/web/index_html_template.dart';
import 'package:test/test.dart';

void main() {
  late Directory webDir;
  Logger quiet() => Logger(level: Level.quiet);

  setUp(() async {
    webDir = await Directory.systemTemp.createTemp('deploy_index_test_');
  });
  tearDown(() => webDir.delete(recursive: true));

  String indexPath() => p.join(webDir.path, 'index.html');
  String backupPath() => p.join(webDir.path, 'index.html.bak');

  test('backs up and restores an existing index.html exactly', () async {
    File(indexPath()).writeAsStringSync('<html>original</html>');

    final backup = await installLoadingIndexHtml(webDir.path, logger: quiet());
    expect(File(indexPath()).readAsStringSync(), customIndexHtml);
    expect(File(backupPath()).existsSync(), isTrue);

    await restoreIndexHtml(backup, logger: quiet());
    expect(File(indexPath()).readAsStringSync(), '<html>original</html>');
    expect(File(backupPath()).existsSync(), isFalse);
  });

  test('removes the template when there was no original to restore', () async {
    expect(File(indexPath()).existsSync(), isFalse);

    final backup = await installLoadingIndexHtml(webDir.path, logger: quiet());
    expect(File(indexPath()).readAsStringSync(), customIndexHtml);

    await restoreIndexHtml(backup, logger: quiet());
    // Working tree is left exactly as found: no stray index.html.
    expect(File(indexPath()).existsSync(), isFalse);
  });

  test('self-heals a stale backup from an interrupted run', () async {
    // Prior run died after swapping: index.html is the template, and the real
    // original survives only in the .bak.
    File(indexPath()).writeAsStringSync(customIndexHtml);
    File(backupPath()).writeAsStringSync('<html>real original</html>');

    final backup = await installLoadingIndexHtml(webDir.path, logger: quiet());
    await restoreIndexHtml(backup, logger: quiet());

    // The genuine original is recovered, not the template.
    expect(File(indexPath()).readAsStringSync(), '<html>real original</html>');
    expect(File(backupPath()).existsSync(), isFalse);
  });

  test('dry-run makes no changes', () async {
    File(indexPath()).writeAsStringSync('<html>original</html>');

    final backup = await installLoadingIndexHtml(
      webDir.path,
      logger: quiet(),
      dryRun: true,
    );
    expect(backup, isNull);
    expect(File(indexPath()).readAsStringSync(), '<html>original</html>');
    expect(File(backupPath()).existsSync(), isFalse);
  });
}
