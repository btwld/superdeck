import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/export/pdf_controller.dart';
import 'package:superdeck/src/export/slide_capture_service.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck/src/styling/components/slide.dart';

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

void main() {
  group('PdfController', () {
    late PdfController controller;
    late SlideCaptureService slideCaptureService;
    late List<SlideConfiguration> testSlides;

    setUp(() {
      // Create minimal test slides using real constructor
      final slide1 = Slide(key: 'slide-1', sections: [], comments: []);
      final slide2 = Slide(key: 'slide-2', sections: [], comments: []);
      final slide3 = Slide(key: 'slide-3', sections: [], comments: []);

      testSlides = [
        SlideConfiguration(
          slideIndex: 0,
          style: SlideStyle(),
          slide: slide1,
          thumbnailFile: 'thumb1.png',
        ),
        SlideConfiguration(
          slideIndex: 1,
          style: SlideStyle(),
          slide: slide2,
          thumbnailFile: 'thumb2.png',
        ),
        SlideConfiguration(
          slideIndex: 2,
          style: SlideStyle(),
          slide: slide3,
          thumbnailFile: 'thumb3.png',
        ),
      ];

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

    group('State Management', () {
      test('pageController is initialized', () {
        expect(controller.pageController.initialPage, 0);
      });

      // Note: dispose test skipped - PageController disposal requires
      // widget test context
    });

    group('Export Status', () {
      test('starts with idle status', () {
        expect(controller.exportStatus.value, PdfExportStatus.idle);
      });

      // Note: Full export tests would require widget testing
      // and mock implementations of the capture service
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
