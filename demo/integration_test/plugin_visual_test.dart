import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:superdeck/src/deck/loaders/file_deck_loader.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_mermaid/superdeck_mermaid.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('plugin visual coverage', () {
    setUpAll(TestApp.initialize);

    testWidgets('Mermaid build plugin renders in the deck runtime', (
      tester,
    ) async {
      _setReviewViewport(tester);
      final fixtureRoot =
          'build/integration_fixtures/plugin_visual/'
          'mermaid_${DateTime.now().microsecondsSinceEpoch}';
      final fixtureDir = Directory(fixtureRoot);
      await fixtureDir.create(recursive: true);

      final workspace = DeckWorkspace(
        projectDir: Directory.current.path,
        slidesPath: '$fixtureRoot/slides.md',
        outputDir: '$fixtureRoot/.superdeck',
      );

      final builder = DeckBuilder(
        workspace: workspace,
        store: DeckBuildStore(workspace: workspace),
        plugins: [MermaidBuildPlugin(generator: _FakeMermaidGenerator())],
      );
      FileDeckLoader? loader;
      addTearDown(() async {
        await tester.unmountTestApp();
        await loader?.dispose();
        await builder.dispose();
        if (await fixtureDir.exists()) {
          await fixtureDir.delete(recursive: true);
        }
      });

      await workspace.slidesFile.writeAsString('''
# Plugin Diagram

```mermaid
graph TD
  Markdown[slides.md] --> Plugin[MermaidBuildPlugin]
  Plugin --> Asset[PNG asset]
  Asset --> Runtime[SuperDeck runtime]
```
''');
      await builder.build();
      final generatedImage = await _singleGeneratedMermaidImage(workspace);
      await _expectPngDimensions(generatedImage, width: 640, height: 360);
      await _expectPngHasTransparency(generatedImage);

      final fileLoader = FileDeckLoader(workspace: workspace);
      loader = fileLoader;

      final controller = await tester.pumpTestAppWithLoader(
        fileLoader,
        workspace: workspace,
      );

      expect(controller.presentation.totalSlides.value, 1);
      assertPresentationHealthy(tester, controller);

      final outputDir = await captureCurrentViewForReview(
        tester,
        suiteName: 'plugin_visual',
        scenarioName: 'mermaid runtime',
      );
      await assertReviewScreenshots(outputDir: outputDir, expectedCount: 1);
    });

    testWidgets('PDF action opens export dialog for screenshot review', (
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
        actions: pdfActions(
          pdfSaver: (pdf) {
            saverCalled = true;
            final pdfBytes = Uint8List.fromList(pdf);
            exportedPdf = pdfBytes;
            _writePdfExportArtifactIfRequested(pdfBytes);
            return releaseSave.future;
          },
        ),
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

Multi-page export review for the plugin action flow.
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

class _FakeMermaidGenerator extends MermaidGenerator {
  @override
  Future<Uint8List> render(String syntax) async {
    return _diagramPngBytes();
  }

  @override
  Future<void> dispose() async {}
}

Future<File> _singleGeneratedMermaidImage(DeckWorkspace workspace) async {
  final mermaidDir = Directory('${workspace.outputDir}/mermaid');
  final images = await mermaidDir
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.png'))
      .cast<File>()
      .toList();

  expect(images, hasLength(1));

  return images.single;
}

Future<void> _expectPngDimensions(
  File file, {
  required int width,
  required int height,
}) async {
  final codec = await ui.instantiateImageCodec(await file.readAsBytes());
  final frame = await codec.getNextFrame();
  final image = frame.image;

  try {
    expect(image.width, width);
    expect(image.height, height);
  } finally {
    image.dispose();
    codec.dispose();
  }
}

Future<void> _expectPngHasTransparency(File file) async {
  final codec = await ui.instantiateImageCodec(await file.readAsBytes());
  final frame = await codec.getNextFrame();
  final image = frame.image;

  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);

    final pixels = bytes!.buffer.asUint8List();
    final hasTransparentPixel = Iterable<int>.generate(
      pixels.length ~/ 4,
    ).any((pixel) => pixels[pixel * 4 + 3] < 255);

    expect(hasTransparentPixel, isTrue);
  } finally {
    image.dispose();
    codec.dispose();
  }
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

Future<Uint8List> _diagramPngBytes() async {
  const width = 640.0;
  const height = 360.0;
  const strokeWidth = 2.0;
  const arrowHeadLength = 12.0;
  const arrowHeadRise = 8.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

  final nodePaint = Paint()..color = const Color(0xffececff);
  final strokePaint = Paint()
    ..color = const Color(0xff9370db)
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth;
  final arrowPaint = Paint()
    ..color = const Color(0xff333333)
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;

  void drawNode(Rect rect, String label) {
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        nodePaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        strokePaint,
      );

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xff333333),
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 28);

    painter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - painter.width) / 2,
        rect.top + (rect.height - painter.height) / 2,
      ),
    );
  }

  void drawArrow(Offset start, Offset end) {
    canvas.drawLine(start, end, arrowPaint);
    final head = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - arrowHeadLength, end.dy - arrowHeadRise)
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - arrowHeadLength, end.dy + arrowHeadRise);
    canvas.drawPath(head, arrowPaint);
  }

  drawNode(const Rect.fromLTWH(40, 130, 160, 92), 'slides.md');
  drawNode(const Rect.fromLTWH(240, 130, 160, 92), 'Mermaid\nplugin');
  drawNode(const Rect.fromLTWH(440, 130, 160, 92), 'PNG asset');
  drawArrow(const Offset(200, 176), const Offset(240, 176));
  drawArrow(const Offset(400, 176), const Offset(440, 176));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();

  return byteData!.buffer.asUint8List();
}
