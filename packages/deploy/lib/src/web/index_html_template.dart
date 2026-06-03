import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// A custom `index.html` that shows a loading indicator until Flutter renders
/// its first frame.
///
/// Uses the modern `flutter_bootstrap.js` entrypoint. The `$FLUTTER_BASE_HREF`
/// token is substituted by `flutter build web --base-href`.
const String customIndexHtml = r'''
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A SuperDeck presentation.">

  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="SuperDeck">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>SuperDeck</title>
  <link rel="manifest" href="manifest.json">

  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    }

    #superdeck-loading {
      position: fixed;
      inset: 0;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      z-index: 9999;
    }

    .spinner {
      width: 40px;
      height: 40px;
      margin-bottom: 20px;
      border: 3px solid #f3f3f3;
      border-top: 3px solid #3498db;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    .loading-text {
      color: #666;
      font-size: 16px;
    }
  </style>
</head>
<body>
  <div id="superdeck-loading">
    <div class="spinner"></div>
    <div class="loading-text">Loading presentation...</div>
  </div>

  <script>
    window.addEventListener('flutter-first-frame', function () {
      var loader = document.getElementById('superdeck-loading');
      if (loader) loader.remove();
    });
  </script>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
''';

/// A handle describing how to undo an [installLoadingIndexHtml] swap.
class IndexHtmlBackup {
  /// The `index.html` that was overwritten with the template.
  final String indexPath;

  /// The saved original, or `null` when no `index.html` existed beforehand
  /// (in which case the written template should be deleted on restore).
  final String? backupPath;

  const IndexHtmlBackup({required this.indexPath, this.backupPath});
}

/// Installs [customIndexHtml] into `<webDir>/index.html`, backing up any
/// existing file.
///
/// Returns a handle to pass to [restoreIndexHtml], or `null` in [dryRun] mode.
Future<IndexHtmlBackup?> installLoadingIndexHtml(
  String webDir, {
  required Logger logger,
  bool dryRun = false,
}) async {
  if (dryRun) {
    logger.info('Would replace index.html with the SuperDeck loading template');

    return null;
  }

  final indexHtmlPath = p.join(webDir, 'index.html');
  final backupPath = p.join(webDir, 'index.html.bak');
  final indexFile = File(indexHtmlPath);
  final backupFile = File(backupPath);

  // Self-heal from a previously interrupted run: a leftover backup means the
  // current index.html is our template, not the user's file. Restore it first
  // so we never copy the template over the genuine original below.
  if (backupFile.existsSync()) {
    backupFile.copySync(indexHtmlPath);
    logger.detail('Recovered index.html from a previous run\'s backup');
  }

  String? savedBackup;
  if (indexFile.existsSync()) {
    await indexFile.copy(backupPath);
    savedBackup = backupPath;
    logger.detail('Created backup of original index.html');
  }

  await File(indexHtmlPath).writeAsString(customIndexHtml);
  logger.info('Installed custom index.html with loading indicator');

  return IndexHtmlBackup(indexPath: indexHtmlPath, backupPath: savedBackup);
}

/// Undoes an [installLoadingIndexHtml] swap. Restores the original when one was
/// backed up, otherwise removes the template that was written. Safe to call
/// with `null`.
Future<void> restoreIndexHtml(
  IndexHtmlBackup? backup, {
  required Logger logger,
}) async {
  if (backup == null) return;

  try {
    final backupPath = backup.backupPath;
    if (backupPath != null && File(backupPath).existsSync()) {
      final backupFile = File(backupPath);
      await backupFile.copy(backup.indexPath);
      await backupFile.delete();
      logger.detail('Restored original index.html from backup');

      return;
    }

    // No original existed: remove the template we wrote so the working tree is
    // left exactly as we found it.
    final indexFile = File(backup.indexPath);
    if (indexFile.existsSync()) {
      await indexFile.delete();
      logger.detail('Removed temporary index.html (no original to restore)');
    }
  } catch (e) {
    logger.warn('Failed to restore index.html: $e');
  }
}
