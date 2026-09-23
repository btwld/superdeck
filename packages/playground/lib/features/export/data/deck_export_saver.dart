import 'package:file_saver/file_saver.dart';

import '../domain/deck_export.dart';

/// Writes an export somewhere the reader chooses.
///
/// Completes with `false` when the reader cancels.
typedef DeckExportSaver = Future<bool> Function(DeckExport export);

/// Saves [export] as a zip through the platform's save dialog.
Future<bool> saveDeckExportAsZip(DeckExport export) async {
  final path = await FileSaver.instance.saveAs(
    name: export.name,
    bytes: export.toZip(),
    fileExtension: 'zip',
    mimeType: MimeType.zip,
  );

  return path != null;
}
