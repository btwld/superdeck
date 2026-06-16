import 'dart:typed_data';

/// Persists generated PDF bytes.
///
/// Return `true` when the save succeeds and `false` when the user cancels or
/// chooses not to persist the file. Throw to mark the export as failed.
typedef PdfSaver = Future<bool> Function(Uint8List pdf);

/// Configuration for the PDF export runtime plugin.
final class PdfExportOptions {
  /// Creates PDF export configuration.
  const PdfExportOptions({this.pdfSaver, this.fileName = 'superdeck'});

  /// Optional saver for generated PDF bytes.
  ///
  /// When omitted, SuperDeck shows the platform save flow.
  final PdfSaver? pdfSaver;

  /// Default file name used by the platform save flow.
  ///
  /// The `.pdf` extension is added by the saver.
  final String fileName;
}
