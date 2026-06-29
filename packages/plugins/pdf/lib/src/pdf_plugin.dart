import 'package:flutter/material.dart' show Icons;
import 'package:superdeck/superdeck.dart';

import 'pdf_export_options.dart';
import 'pdf_export_screen.dart';

/// Runtime plugin that adds PDF export support to the SuperDeck app shell.
///
/// Register this with [SuperDeckApp.plugins] to add an Export PDF action.
final class PdfPlugin extends DeckRuntimePlugin {
  /// Creates a PDF export plugin.
  const PdfPlugin({this.options = const PdfExportOptions()});

  /// PDF export configuration used by the action this plugin registers.
  final PdfExportOptions options;

  @override
  String get id => 'superdeck.pdf';

  @override
  List<DeckAction> get actions {
    return [
      DeckAction(
        id: 'superdeck.pdf.export',
        label: 'Export PDF',
        icon: Icons.picture_as_pdf,
        onPressed: (context, deck) =>
            PdfExportDialogScreen.show(context, options: options),
      ),
    ];
  }
}
