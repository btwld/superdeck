import 'package:flutter/material.dart' show Icons;
import 'package:superdeck/superdeck.dart';

import 'pdf_controller.dart';
import 'pdf_export_screen.dart';

List<DeckAction> pdfActions({PdfSaver? pdfSaver}) {
  return [pdfExportAction(pdfSaver: pdfSaver)];
}

DeckAction pdfExportAction({PdfSaver? pdfSaver}) {
  return DeckAction(
    id: 'superdeck.pdf.export',
    label: 'Export PDF',
    icon: Icons.picture_as_pdf,
    onPressed: (context, deck) {
      PdfExportDialogScreen.show(context, pdfSaver: pdfSaver);
    },
  );
}
