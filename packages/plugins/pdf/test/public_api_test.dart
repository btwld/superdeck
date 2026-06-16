import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';

void main() {
  group('superdeck_pdf public api', () {
    test('exports the supported PDF surface', () {
      expect(PdfPlugin, isNotNull);
      expect(PdfExportOptions, isNotNull);
      expect(PdfSaver, isNotNull);
    });
  });
}
