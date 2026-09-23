import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

import '../domain/deck_export.dart';

/// Writes an export somewhere the reader chooses.
///
/// Completes with `false` when the reader cancels.
typedef DeckExportSaver = Future<bool> Function(DeckExport export);

Uint8List _encodeZip(DeckExport export) => export.toZip();

/// Saves [export] as a zip through the platform's save dialog.
///
/// The zip is encoded off the UI isolate, since compressing generated
/// artwork can take long enough to drop frames.
Future<bool> saveDeckExportAsZip(DeckExport export) async {
  final path = await FileSaver.instance.saveAs(
    name: export.name,
    bytes: await compute(_encodeZip, export),
    fileExtension: 'zip',
    mimeType: MimeType.zip,
  );

  return path != null;
}
