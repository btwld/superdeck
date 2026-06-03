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

/// Installs [customIndexHtml] into `<webDir>/index.html`, backing up any
/// existing file.
///
/// Returns the backup path (to pass to [restoreIndexHtml]) or `null` when there
/// was nothing to back up or in [dryRun] mode.
Future<String?> installLoadingIndexHtml(
  String webDir, {
  required Logger logger,
  bool dryRun = false,
}) async {
  if (dryRun) {
    logger.info('Would replace index.html with the SuperDeck loading template');

    return null;
  }

  final indexHtmlPath = p.join(webDir, 'index.html');
  String? backupPath;

  final indexFile = File(indexHtmlPath);
  if (indexFile.existsSync()) {
    backupPath = p.join(webDir, 'index.html.bak');
    await indexFile.copy(backupPath);
    logger.detail('Created backup of original index.html');
  }

  await File(indexHtmlPath).writeAsString(customIndexHtml);
  logger.info('Installed custom index.html with loading indicator');

  return backupPath;
}

/// Restores the original `index.html` from a backup created by
/// [installLoadingIndexHtml]. Safe to call with `null` or a missing backup.
Future<void> restoreIndexHtml(String? backupPath, {required Logger logger}) async {
  if (backupPath == null) return;

  final backupFile = File(backupPath);
  if (!backupFile.existsSync()) return;

  final indexHtmlPath = backupPath.replaceAll('.bak', '');
  try {
    await backupFile.copy(indexHtmlPath);
    await backupFile.delete();
    logger.detail('Restored original index.html from backup');
  } catch (e) {
    logger.warn('Failed to restore index.html backup: $e');
  }
}
