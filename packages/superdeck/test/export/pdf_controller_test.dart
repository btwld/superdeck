import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/export/pdf_controller.dart';
import 'package:superdeck/src/export/slide_capture_service.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck/src/styling/slide_style.dart';

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
  });
}
