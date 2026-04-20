import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF export integration (full deck)', () {
    testWidgets('exports a multi-slide deck to PDF bytes', (tester) async {
      final slides = _createExportSlides();
      Uint8List? savedPdf;
      final controller = _createController(
        slides,
        pdfSaver: (pdf) async {
          savedPdf = pdf;
          return true;
        },
      );
      addTearDown(controller.dispose);

      await _pumpExportHarness(tester, controller);

      final error = await _runExportAndPump(tester, controller);

      expect(error, isNull);
      expect(controller.exportStatus.value, PdfExportStatus.complete);
      expect(controller.exportError.value, isNull);

      final pdf = savedPdf;
      expect(pdf, isNotNull);
      expect(pdf, isNotEmpty);
      expect(_hasPdfSignature(pdf!), isTrue);
      expect(_countPdfPageObjects(pdf), slides.length);
    });

    testWidgets('emits capturing -> building -> complete status transitions', (
      tester,
    ) async {
      final slides = _createExportSlides();
      final controller = _createController(
        slides,
        pdfSaver: (pdf) async => true,
      );
      addTearDown(controller.dispose);

      await _pumpExportHarness(tester, controller);

      final statusExpectation = expectLater(
        controller.exportStatus.toStream(),
        emitsThrough(PdfExportStatus.complete),
      );

      final error = await _runExportAndPump(tester, controller);

      expect(error, isNull);
      await statusExpectation;
    });
  });
}

List<SlideConfiguration> _createExportSlides() {
  final slides = [
    SlideFixtures.singleColumn(
      content: '''
# Plain Markdown

This slide keeps regular markdown content together.
''',
    ),
    SlideFixtures.twoColumnEqual(
      left: '''
## Left Column

Author text in the first column.
''',
      right: '''
## Right Column

Author text in the second column.
''',
    ),
    SlideFixtures.withAlignment(ContentAlignment.center),
  ];

  return [
    for (final (index, slide) in slides.indexed)
      SlideTestHarness.createConfiguration(
        slide,
        slideIndex: index,
        isStaticRendering: true,
        parts: const SlideParts(
          background: ColoredBox(color: Color(0xFF090909)),
        ),
      ),
  ];
}

PdfController _createController(
  List<SlideConfiguration> slides, {
  required PdfSaver pdfSaver,
}) {
  return PdfController(
    slides: slides,
    slideCaptureService: SlideCaptureService(),
    waitDuration: Duration.zero,
    pdfSaver: pdfSaver,
  );
}

Future<void> _pumpExportHarness(
  WidgetTester tester,
  PdfController controller,
) async {
  tester.view.physicalSize = superDeckSlideSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_buildExportHarness(controller));
  await tester.pumpAndSettle();
}

Widget _buildExportHarness(PdfController controller) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: SizedBox.fromSize(
        size: superDeckSlideSize,
        child: PageView(
          controller: controller.pageController,
          children: [
            for (final configuration in controller.slides)
              RepaintBoundary(
                key: controller.getSlideKey(configuration),
                child: SlideRenderView(configuration),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<Object?> _runExportAndPump(
  WidgetTester tester,
  PdfController controller,
) async {
  return tester.runAsync<Object?>(() async {
    Object? error;
    var completed = false;

    final completion = controller
        .export()
        .then<void>(
          (_) {},
          onError: (Object caught, StackTrace stackTrace) {
            error = caught;
          },
        )
        .whenComplete(() {
          completed = true;
        });

    for (var i = 0; i < 200 && !completed; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(completed, isTrue, reason: 'export() did not complete in time');
    await completion;
    return error;
  });
}

bool _hasPdfSignature(Uint8List pdf) {
  const signature = [0x25, 0x50, 0x44, 0x46, 0x2D];
  if (pdf.length < signature.length) return false;

  for (var i = 0; i < signature.length; i++) {
    if (pdf[i] != signature[i]) return false;
  }

  return true;
}

int _countPdfPageObjects(Uint8List pdf) {
  final contents = latin1.decode(pdf, allowInvalid: true);
  return RegExp(r'/Type\s*/Page\b').allMatches(contents).length;
}
