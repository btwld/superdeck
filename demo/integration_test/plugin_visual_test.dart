import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('plugin visual coverage', () {
    setUpAll(TestApp.initialize);

    testWidgets('built-in Mermaid renderer paints in the deck runtime', (
      tester,
    ) async {
      _setReviewViewport(tester);
      final controller = await tester.pumpTestAppWithSlides([
        makeSlide('mermaid-runtime', '''
# Runtime Diagram

```mermaid
graph TD
  Draft[Draft slides] --> Review{Ready?}
  Review -->|Yes| Present[Present]
  Review -->|No| Draft
```
'''),
      ]);

      expect(controller.presentation.totalSlides.value, 1);
      assertPresentationHealthy(tester, controller);

      final outputDir = await captureCurrentViewForReview(
        tester,
        suiteName: 'plugin_visual',
        scenarioName: 'mermaid runtime',
      );
      await assertReviewScreenshots(outputDir: outputDir, expectedCount: 1);
    });

    testWidgets('PDF plugin opens export dialog for screenshot review', (
      tester,
    ) async {
      _setReviewViewport(tester);
      final releaseSave = Completer<bool>();
      Uint8List? exportedPdf;
      var saverCalled = false;
      addTearDown(() {
        if (!releaseSave.isCompleted) {
          releaseSave.complete(false);
        }
      });

      final slides = _pdfReviewSlides();
      final controller = await tester.pumpTestAppWithSlides(
        slides,
        plugins: [
          PdfPlugin(
            options: PdfExportOptions(
              pdfSaver: (pdf) {
                saverCalled = true;
                exportedPdf = pdf;
                _writePdfExportArtifactIfRequested(pdf);
                return releaseSave.future;
              },
            ),
          ),
        ],
      );

      await tester.tapByLabel('Open menu');
      await tester.pumpUntil(
        () => controller.presentation.isMenuOpen.value,
        debugLabel: 'plugin menu to open',
        onTimeout: () => describeDeckControllerState(controller),
      );
      expect(controller.presentation.totalSlides.value, slides.length);

      await tester.tapByLabel('Export PDF');
      await tester.pumpUntil(
        () => saverCalled && find.text('Building PDF...').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 20),
        debugLabel: 'PDF export dialog building state',
      );

      final outputDir = await captureCurrentViewForReview(
        tester,
        suiteName: 'plugin_visual',
        scenarioName: 'pdf export dialog',
      );
      await assertReviewScreenshots(outputDir: outputDir, expectedCount: 1);
      await _writePdfExportForReview(
        outputDir,
        exportedPdf,
        expectedPages: slides.length,
      );

      releaseSave.complete(true);
      await tester.pumpUntil(
        () => find.text('Building PDF...').evaluate().isEmpty,
        timeout: const Duration(seconds: 10),
        debugLabel: 'PDF export dialog to close',
      );
      assertPresentationHealthy(tester, controller);
    });
  });
}

List<Slide> _pdfReviewSlides() {
  return [
    makeSlide('pdf-plugin-cover', '''
# PDF Plugin Visual Test

Multi-page export review for the plugin export flow.
'''),
    makeSlide('pdf-plugin-markdown', '''
# Markdown Export Coverage

- Headings and list content
- Inline **emphasis** and `code`
- Runtime slide chrome and footer rendering
'''),
    Slide(
      key: 'pdf-plugin-layout',
      sections: [
        SectionBlock([
          ContentBlock(
            '## Left Column\n\nThe PDF export captures slide layout.',
          ),
          ContentBlock('## Right Column\n\nEach slide should become one page.'),
        ]),
        SectionBlock([ContentBlock('Final page in the generated review PDF.')]),
      ],
    ),
  ];
}

void _setReviewViewport(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1280, 720)
    ..devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

Future<void> _writePdfExportForReview(
  Directory? outputDir,
  Uint8List? pdf, {
  required int expectedPages,
}) async {
  expect(pdf, isNotNull);
  expect(pdf!.length, greaterThan(1000));
  expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  _expectPdfPageCount(pdf, expectedPages);

  if (outputDir == null) return;

  await File('${outputDir.path}/export.pdf').writeAsBytes(pdf, flush: true);
}

void _expectPdfPageCount(Uint8List pdf, int expectedPages) {
  final source = latin1.decode(pdf, allowInvalid: true);
  final pages = RegExp(
    r'/Type\s*/Pages\b.*?/Count\s+(\d+)',
    dotAll: true,
  ).firstMatch(source);

  expect(pages, isNotNull);
  expect(int.parse(pages!.group(1)!), expectedPages);
}

void _writePdfExportArtifactIfRequested(Uint8List pdf) {
  final outputPath = Platform.environment['SUPERDECK_PDF_EXPORT_PATH'];
  if (outputPath == null || outputPath.trim().isEmpty) return;

  final file = File(outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(pdf, flush: true);
}
