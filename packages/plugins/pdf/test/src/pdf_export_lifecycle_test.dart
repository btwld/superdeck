import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_pdf/src/pdf_controller.dart';
import 'package:superdeck_pdf/src/pdf_export_options.dart';
import 'package:superdeck_pdf/src/pdf_export_screen.dart';

import '../helpers/fake_slide_capture_service.dart';
import '../helpers/test_helpers.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfController lifecycle', () {
    test('export after disposal does not capture or write signals', () async {
      final capture = FakeSlideCaptureService(_png);
      final controller = PdfController(
        slides: createTestSlides(1),
        slideCaptureService: capture,
        waitDuration: Duration.zero,
      );
      controller.dispose();

      await controller.export();

      expect(capture.captureFromKeyCalls, 0);
    });

    testWidgets('an overlapping export does not reset the in-flight run', (
      tester,
    ) async {
      final capture = _GatedCapture(_png);
      final controller = PdfController(
        slides: createTestSlides(2),
        slideCaptureService: capture,
        waitDuration: Duration.zero,
        options: PdfExportOptions(pdfSaver: (_) async => true),
      );
      addTearDown(() {
        for (final gate in capture.gates) {
          if (!gate.isCompleted) gate.complete();
        }
        controller.dispose();
      });

      await tester.pumpWidget(_harness(controller));
      await tester.pump();
      final export = controller.export();
      await _until(tester, () => capture.gates.isNotEmpty);
      capture.gates.first.complete();
      await _until(
        tester,
        () =>
            controller.capturedImageCountForTesting == 1 &&
            capture.gates.length >= 2,
      );

      final status = controller.exportStatus.value;
      final retained = controller.capturedImageCountForTesting;
      await controller.export();

      expect(controller.exportStatus.value, status);
      expect(controller.capturedImageCountForTesting, retained);
      expect(status, PdfExportStatus.capturing);

      controller.cancel();
      capture.gates[1].complete();
      await _finish(tester, export);

      expect(controller.exportStatus.value, PdfExportStatus.idle);
      expect(controller.capturedImageCountForTesting, 0);
    });

    testWidgets('failure after a captured slide releases that image', (
      tester,
    ) async {
      final capture = _FailAfterFirst(_png);
      final controller = PdfController(
        slides: createTestSlides(2),
        slideCaptureService: capture,
        waitDuration: Duration.zero,
        options: PdfExportOptions(pdfSaver: (_) async => true),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller));
      await tester.pump();
      await _finish(tester, controller.export());

      expect(controller.exportStatus.value, PdfExportStatus.failed);
      expect(controller.capturedImageCountForTesting, 0);
      expect(capture.captureFromKeyCalls, greaterThan(1));
    });

    testWidgets('cancellation after a captured slide releases that image', (
      tester,
    ) async {
      final capture = _GatedCapture(_png);
      final controller = PdfController(
        slides: createTestSlides(2),
        slideCaptureService: capture,
        waitDuration: Duration.zero,
        options: PdfExportOptions(pdfSaver: (_) async => true),
      );
      addTearDown(() {
        for (final gate in capture.gates) {
          if (!gate.isCompleted) gate.complete();
        }
        controller.dispose();
      });

      await tester.pumpWidget(_harness(controller));
      await tester.pump();
      final export = controller.export();
      await _until(tester, () => capture.gates.isNotEmpty);
      capture.gates.first.complete();
      await _until(
        tester,
        () =>
            controller.capturedImageCountForTesting == 1 &&
            capture.gates.length >= 2,
      );

      controller.cancel();
      capture.gates[1].complete();
      await _finish(tester, export);

      expect(controller.exportStatus.value, PdfExportStatus.idle);
      expect(controller.capturedImageCountForTesting, 0);
    });

    testWidgets('disposal after a captured slide releases that image', (
      tester,
    ) async {
      final capture = _GatedCapture(_png);
      final controller = PdfController(
        slides: createTestSlides(2),
        slideCaptureService: capture,
        waitDuration: Duration.zero,
        options: PdfExportOptions(pdfSaver: (_) async => true),
      );
      addTearDown(() {
        for (final gate in capture.gates) {
          if (!gate.isCompleted) gate.complete();
        }
      });

      await tester.pumpWidget(_harness(controller));
      await tester.pump();
      final export = controller.export();
      await _until(tester, () => capture.gates.isNotEmpty);
      capture.gates.first.complete();
      await _until(
        tester,
        () =>
            controller.capturedImageCountForTesting == 1 &&
            capture.gates.length >= 2,
      );

      controller.dispose();
      expect(controller.capturedImageCountForTesting, 0);
      capture.gates[1].complete();
      await _finish(tester, export);

      expect(controller.capturedImageCountForTesting, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a later export can run after the previous one finishes', (
      tester,
    ) async {
      final capture = FakeSlideCaptureService(_png);
      final controller = PdfController(
        slides: createTestSlides(1),
        slideCaptureService: capture,
        waitDuration: Duration.zero,
        options: PdfExportOptions(pdfSaver: (_) async => true),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(controller));
      await tester.pump();
      await _finish(tester, controller.export());
      expect(controller.exportStatus.value, PdfExportStatus.complete);

      await _finish(tester, controller.export());

      expect(controller.exportStatus.value, PdfExportStatus.complete);
      expect(controller.capturedImageCountForTesting, 0);
      expect(capture.captureFromKeyCalls, 2);
    });
  });

  testWidgets(
    'a replaced export controller does not close the dialog from its own status',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view
        ..physicalSize = superDeckSlideSize
        ..devicePixelRatio = 1;

      final firstRelease = Completer<void>();
      final secondRelease = Completer<void>();
      final capture = _ScriptedCapture((call) async {
        if (call == 1) {
          await firstRelease.future;
          return _png;
        }
        await secondRelease.future;
        throw StateError('replacement export is still the one running');
      });
      addTearDown(() {
        if (!firstRelease.isCompleted) firstRelease.complete();
        if (!secondRelease.isCompleted) {
          secondRelease.complete();
        }
      });

      var closed = 0;
      Widget dialog(List<SlideConfiguration> slides) {
        return MaterialApp(
          home: PdfExportDialogScreen(
            slides: slides,
            slideCaptureService: capture,
            onClose: () => closed++,
            options: PdfExportOptions(pdfSaver: (_) async => true),
          ),
        );
      }

      await tester.pumpWidget(dialog(createTestSlides(1)));
      await _drive(tester, () => capture.calls >= 1);

      await tester.pumpWidget(dialog(createTestSlides(1)));
      await _drive(tester, () => capture.calls >= 2);

      firstRelease.complete();
      await _settle(tester);

      expect(closed, 0);
      expect(find.byType(PdfExportDialogScreen), findsOneWidget);

      secondRelease.complete();
      await _settle(tester);

      expect(closed, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _harness(PdfController controller) {
  return MaterialApp(
    home: Scaffold(
      body: PageView(
        controller: controller.pageController,
        children: [
          for (final slide in controller.slides)
            RepaintBoundary(
              key: controller.getSlideKey(slide),
              child: controller
                  .getSlideReadiness(slide)
                  .bind(const SizedBox.expand()),
            ),
        ],
      ),
    ),
  );
}

Future<void> _until(WidgetTester tester, bool Function() done) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 100 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  expect(done(), isTrue);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
}

Future<void> _drive(WidgetTester tester, bool Function() done) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 80 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  expect(done(), isTrue);
}

Future<void> _finish(WidgetTester tester, Future<void> export) async {
  var completed = false;
  final done = export.whenComplete(() => completed = true);
  await _until(tester, () => completed);
  await done;
}

final class _GatedCapture extends FakeSlideCaptureService {
  _GatedCapture(super.bytes);

  final gates = <Completer<void>>[];

  @override
  Future<Uint8List> captureFromKey({
    required GlobalKey key,
    required SlideCaptureQuality quality,
  }) async {
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;

    return super.captureFromKey(key: key, quality: quality);
  }
}

final class _FailAfterFirst extends FakeSlideCaptureService {
  _FailAfterFirst(super.bytes);

  @override
  Future<Uint8List> captureFromKey({
    required GlobalKey key,
    required SlideCaptureQuality quality,
  }) async {
    final image = await super.captureFromKey(key: key, quality: quality);
    if (captureFromKeyCalls > 1) throw StateError('capture failed');

    return image;
  }
}

final class _ScriptedCapture extends FakeSlideCaptureService {
  _ScriptedCapture(this._onCall) : super(_png);

  final Future<Uint8List> Function(int call) _onCall;
  var calls = 0;

  @override
  Future<Uint8List> captureFromKey({
    required GlobalKey key,
    required SlideCaptureQuality quality,
  }) {
    calls++;

    return _onCall(calls);
  }
}
