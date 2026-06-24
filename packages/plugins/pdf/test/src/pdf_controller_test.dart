import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';
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
          options: PdfExportOptions(pdfSaver: pdfSaver),
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

      testWidgets('save failure marks export as failed without throwing', (
        tester,
      ) async {
        final exportController = createExportController(
          pdfSaver: (pdf) async => throw Exception('disk full'),
        );

        await tester.pumpWidget(_buildExportHarness(exportController));
        await tester.pump();

        final error = await _runExportAndPump(tester, exportController);

        expect(error, isNull);
        expect(exportController.exportStatus.value, PdfExportStatus.failed);
        expect(exportController.exportError.value, contains('disk full'));
      });

      testWidgets('web file saver exceptions mark export as failed', (
        tester,
      ) async {
        final exportController = createExportController(
          pdfSaver: (pdf) {
            return savePdfWithFileSaverForTesting(
              pdf: pdf,
              fileName: 'slides',
              isWeb: true,
              targetPlatform: TargetPlatform.macOS,
              saveFile:
                  ({
                    required String name,
                    required Uint8List bytes,
                    required String ext,
                    required MimeType mimeType,
                  }) async {
                    throw StateError('browser download failed');
                  },
              saveAs:
                  ({
                    required String name,
                    required Uint8List bytes,
                    required String ext,
                    required MimeType mimeType,
                  }) async {
                    fail('saveAs should not be used for web PDF export');
                  },
            );
          },
        );

        await tester.pumpWidget(_buildExportHarness(exportController));
        await tester.pump();

        final error = await _runExportAndPump(tester, exportController);

        expect(error, isNull);
        expect(exportController.exportStatus.value, PdfExportStatus.failed);
        expect(
          exportController.exportError.value,
          contains('browser download failed'),
        );
      });

      testWidgets(
        'dispose during in-flight saver does not write to disposed signals',
        (tester) async {
          final releaseSave = Completer<bool>();
          var saverCalled = false;
          var exportCompleted = false;
          addTearDown(() {
            if (!releaseSave.isCompleted) releaseSave.complete(false);
          });
          final exportController = PdfController(
            slides: [testSlides.first],
            slideCaptureService: FakeSlideCaptureService(_testPngBytes),
            waitDuration: Duration.zero,
            options: PdfExportOptions(
              pdfSaver: (pdf) {
                saverCalled = true;
                return releaseSave.future;
              },
            ),
          );

          await tester.pumpWidget(_buildExportHarness(exportController));
          await tester.pump();

          // All async work inside runAsync so real + fake timers both work.
          await tester.runAsync(() async {
            Object? asyncError;
            final exportFuture = exportController
                .export()
                .catchError((Object e, StackTrace _) {
                  asyncError = e;
                })
                .whenComplete(() {
                  exportCompleted = true;
                });

            // Drive until the saver is pending.
            for (var i = 0; i < 100 && !saverCalled; i++) {
              await tester.pump(const Duration(milliseconds: 50));
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }

            // Dispose while saver has not yet completed.
            exportController.dispose();

            // Release the saver after disposal.
            releaseSave.complete(true);

            // Drive until export future completes.
            for (var i = 0; i < 50 && !exportCompleted; i++) {
              await tester.pump(const Duration(milliseconds: 50));
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }

            await exportFuture;

            expect(asyncError, isNull);
          });

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('moves captured images into the PDF isolate', (tester) async {
        Uint8List? savedPdf;
        final captureService = FakeSlideCaptureService(_testPngBytes);
        final exportController = PdfController(
          slides: testSlides,
          slideCaptureService: captureService,
          waitDuration: Duration.zero,
          options: PdfExportOptions(
            pdfSaver: (pdf) async {
              savedPdf = pdf;
              return true;
            },
          ),
        );
        addTearDown(exportController.dispose);

        await tester.pumpWidget(_buildExportHarness(exportController));
        await tester.pump();

        final error = await _runExportAndPump(tester, exportController);

        expect(error, isNull);
        expect(exportController.exportStatus.value, PdfExportStatus.complete);
        expect(exportController.capturedImageCountForTesting, 0);
        expect(captureService.captureFromKeyCalls, testSlides.length);
        expect(
          captureService.captureFromKeyQualities,
          everyElement(SlideCaptureQuality.good),
        );
        expect(savedPdf, isNotNull);
        expect(savedPdf, isNotEmpty);
        expect(String.fromCharCodes(savedPdf!.take(4)), '%PDF');
      });
    });

    group('Default saver', () {
      test('uses saveFile instead of saveAs on Linux', () async {
        final calls = <String>[];

        final saved = await savePdfWithFileSaverForTesting(
          pdf: Uint8List.fromList([1, 2, 3]),
          fileName: 'slides',
          isWeb: false,
          targetPlatform: TargetPlatform.linux,
          saveFile:
              ({
                required String name,
                required Uint8List bytes,
                required String ext,
                required MimeType mimeType,
              }) async {
                calls.add('saveFile');
                expect(name, 'slides');
                expect(bytes, [1, 2, 3]);
                expect(ext, 'pdf');
                expect(mimeType, MimeType.pdf);

                return '/tmp/slides.pdf';
              },
          saveAs:
              ({
                required String name,
                required Uint8List bytes,
                required String ext,
                required MimeType mimeType,
              }) async {
                calls.add('saveAs');

                return '/tmp/save-as.pdf';
              },
        );

        expect(saved, isTrue);
        expect(calls, ['saveFile']);
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
