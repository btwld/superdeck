import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_pdf/src/pdf_controller.dart';

import '../helpers/fake_slide_capture_service.dart';
import '../helpers/test_helpers.dart';

class _SequencedRenderObject extends Fake implements RenderObject {
  _SequencedRenderObject(this._attachedValues);

  final List<bool> _attachedValues;
  int _readIndex = 0;
  int attachedReadCount = 0;

  @override
  bool get attached {
    attachedReadCount += 1;
    if (_attachedValues.isEmpty) return true;
    final index = _readIndex < _attachedValues.length
        ? _readIndex
        : _attachedValues.length - 1;
    final value = _attachedValues[index];
    if (_readIndex < _attachedValues.length - 1) {
      _readIndex += 1;
    }
    return value;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return '_SequencedRenderObject(attachedReadCount: $attachedReadCount)';
  }
}

class _FakeBuildContext extends Fake implements BuildContext {
  _FakeBuildContext(this.renderObject);

  final RenderObject renderObject;

  @override
  RenderObject? findRenderObject() => renderObject;
}

class _FakeGlobalKey extends GlobalKey<State<StatefulWidget>> {
  _FakeGlobalKey(this._contexts)
    : _state = _KeyReadState(),
      super.constructor();

  final List<BuildContext?> _contexts;
  final _KeyReadState _state;

  int get contextReadCount => _state.readCount;

  @override
  BuildContext? get currentContext {
    _state.readCount += 1;
    if (_contexts.isEmpty) return null;
    final index = _state.readIndex < _contexts.length
        ? _state.readIndex
        : _contexts.length - 1;
    final value = _contexts[index];
    if (_state.readIndex < _contexts.length - 1) {
      _state.readIndex += 1;
    }
    return value;
  }
}

class _KeyReadState {
  int readIndex = 0;
  int readCount = 0;
}

final _testPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
);

Widget _buildExportHarness(PdfController controller) {
  return MaterialApp(
    home: Scaffold(
      body: PageView(
        controller: controller.pageController,
        children: [
          for (final slide in controller.slides)
            RepaintBoundary(
              key: controller.getSlideKey(slide),
              child: const SizedBox.expand(),
            ),
        ],
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

    for (var i = 0; i < 100 && !completed; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(completed, isTrue, reason: 'export() did not complete in time');
    await completion;
    return error;
  });
}

void main() {
  group('PdfController', () {
    late PdfController controller;
    late SlideCaptureService slideCaptureService;
    late List<SlideConfiguration> testSlides;

    setUp(() {
      testSlides = createTestSlides(3);
      slideCaptureService = SlideCaptureService();

      controller = PdfController(
        slides: testSlides,
        slideCaptureService: slideCaptureService,
        waitDuration: const Duration(milliseconds: 10),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('initializes with idle status', () {
        expect(controller.exportStatus.value, PdfExportStatus.idle);
      });

      test('initializes with provided slides', () {
        expect(controller.slides, testSlides);
        expect(controller.slides.length, 3);
      });

      test('creates PageController', () {
        expect(controller.pageController, isNotNull);
        expect(controller.pageController.initialPage, 0);
      });

      test('disposed is false initially', () {
        expect(controller.disposed, false);
      });

      test('progress starts at zero', () {
        expect(controller.progress.value, 0.0);
      });

      test('progressTuple shows zero captured', () {
        final (current, total) = controller.progressTuple.value;
        expect(current, 0);
        expect(total, 3);
      });
    });

    group('Export flow', () {
      PdfController createExportController({PdfSaver? pdfSaver}) {
        final c = PdfController(
          slides: [testSlides.first],
          slideCaptureService: FakeSlideCaptureService(_testPngBytes),
          waitDuration: Duration.zero,
          pdfSaver: pdfSaver,
        );
        addTearDown(c.dispose);
        return c;
      }

      testWidgets('successful save completes export', (tester) async {
        Uint8List? savedPdf;
        final exportController = createExportController(
          pdfSaver: (pdf) async {
            savedPdf = pdf;
            return true;
          },
        );

        await tester.pumpWidget(_buildExportHarness(exportController));
        await tester.pump();

        final error = await _runExportAndPump(tester, exportController);

        expect(error, isNull);
        expect(exportController.exportStatus.value, PdfExportStatus.complete);
        expect(exportController.exportError.value, isNull);
        expect(savedPdf, isNotNull);
      });

      testWidgets('cancelled save returns export to idle', (tester) async {
        final exportController = createExportController(
          pdfSaver: (pdf) async => false,
        );

        await tester.pumpWidget(_buildExportHarness(exportController));
        await tester.pump();

        final error = await _runExportAndPump(tester, exportController);

        expect(error, isNull);
        expect(exportController.exportStatus.value, PdfExportStatus.idle);
        expect(exportController.exportError.value, isNull);
      });

      testWidgets('save failure marks export as failed', (tester) async {
        final exportController = createExportController(
          pdfSaver: (pdf) async => throw Exception('disk full'),
        );

        await tester.pumpWidget(_buildExportHarness(exportController));
        await tester.pump();

        final error = await _runExportAndPump(tester, exportController);

        expect(error, isA<Exception>());
        expect(exportController.exportStatus.value, PdfExportStatus.failed);
        expect(exportController.exportError.value, contains('disk full'));
      });
    });

    group('Render boundary paint waiting', () {
      testWidgets('re-reads attached until render object is attached', (
        tester,
      ) async {
        final renderObject = _SequencedRenderObject([false, true]);
        final buildContext = _FakeBuildContext(renderObject);
        final key = _FakeGlobalKey([null, buildContext]);

        final waitFuture = controller.waitForRenderBoundaryPaint(key);

        await tester.pump(const Duration(milliseconds: 25));
        await tester.pump();
        await waitFuture;

        expect(key.contextReadCount, greaterThanOrEqualTo(2));
        expect(renderObject.attachedReadCount, greaterThanOrEqualTo(2));
      });

      testWidgets('continues waiting when context is temporarily null', (
        tester,
      ) async {
        final renderObject = _SequencedRenderObject([true]);
        final buildContext = _FakeBuildContext(renderObject);
        final key = _FakeGlobalKey([null, buildContext, null, buildContext]);

        final waitFuture = controller.waitForRenderBoundaryPaint(key);

        await tester.pump(const Duration(milliseconds: 40));
        await tester.pump();
        await waitFuture;
      });

      testWidgets('times out when context never becomes available', (
        tester,
      ) async {
        final timeoutController = PdfController(
          slides: testSlides,
          slideCaptureService: slideCaptureService,
          waitDuration: const Duration(milliseconds: 10),
          renderAttachmentTimeout: const Duration(milliseconds: 30),
        );
        final key = _FakeGlobalKey([null]);

        final waitFuture = timeoutController.waitForRenderBoundaryPaint(key);
        final expectation = expectLater(
          waitFuture,
          throwsA(
            isA<StateError>().having(
              (error) => error.toString(),
              'message',
              contains('context not available'),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 60));
        await expectation;

        timeoutController.dispose();
      });

      testWidgets('throws cancellation while waiting for context', (
        tester,
      ) async {
        final cancellableController = PdfController(
          slides: testSlides,
          slideCaptureService: slideCaptureService,
          waitDuration: const Duration(milliseconds: 10),
          renderAttachmentTimeout: const Duration(seconds: 1),
        );
        final key = _FakeGlobalKey([null]);

        final waitFuture = cancellableController.waitForRenderBoundaryPaint(
          key,
        );
        final expectation = expectLater(
          waitFuture,
          throwsA(
            predicate((error) => error.toString().contains('Export cancelled')),
          ),
        );
        cancellableController.cancel();
        await tester.pump(const Duration(milliseconds: 20));
        await expectation;

        cancellableController.dispose();
      });
    });
  });
}
