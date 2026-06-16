import 'package:flutter/material.dart' show Icons;
import 'package:superdeck/superdeck.dart';

import 'pdf_controller.dart';
import 'pdf_export_screen.dart';

/// Returns the deck actions contributed by the PDF package.
///
/// Pass [pdfSaver] to override how the generated PDF bytes are persisted.
List<DeckAction> pdfActions({PdfSaver? pdfSaver}) {
  return [pdfExportAction(pdfSaver: pdfSaver)];
}

/// Creates the deck action that opens the PDF export flow.
///
/// The returned action uses the stable ID `superdeck.pdf.export`.
DeckAction pdfExportAction({PdfSaver? pdfSaver}) {
  return DeckAction(
    id: 'superdeck.pdf.export',
    label: 'Export PDF',
    icon: Icons.picture_as_pdf,
    onPressed: (context, deck) =>
        PdfExportDialogScreen.show(context, pdfSaver: pdfSaver),
  );
}
