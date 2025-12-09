import 'dart:async';
import 'dart:developer';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:signals/signals.dart';
import 'package:superdeck/src/utils/constants.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:universal_html/html.dart' as html;

import 'slide_capture_service.dart';

/// Status of the export process
enum PdfExportStatus {
  /// Initial state, no export in progress
  idle,

  /// Currently capturing slide images
  capturing,

  /// Building PDF from captured images
  building,

  /// Export completed successfully
  complete,

  /// Preparing slides for export
  preparing,
}

/// Controller for exporting slides to PDF
///
/// Handles capturing slides as images and combining them into a PDF document.
/// Supports both web and native platforms.
class PdfController {
  /// Creates a new [PdfController]
  ///
  /// [slides] - List of slides to export
  /// [slideCaptureService] - Service used to capture slide images
  /// [waitDuration] - Duration to wait between operations
  PdfController({
    required this.slides,
    required this.slideCaptureService,
    Duration waitDuration = const Duration(milliseconds: 100),
  }) : _waitDuration = waitDuration {
    _pageController = PageController(initialPage: 0);
    _slideKeys = {for (var slide in slides) slide.key: GlobalKey()};
  }

  late final PageController _pageController;
  late final Map<String, GlobalKey> _slideKeys;
  final List<Uint8List> _images = [];
  bool _disposed = false;
  bool _cancelled = false;

  // Reactive state - Signals
  final _exportStatus = signal<PdfExportStatus>(PdfExportStatus.idle);
  final _capturedCount = signal<int>(0);

  // Computed signals
  late final progress = computed(() {
    if (_slideKeys.isEmpty) return 0.0;
    return _capturedCount.value / _slideKeys.length;
  });

  late final progressTuple = computed(() {
    return (_capturedCount.value, _slideKeys.length);
  });

  // Readonly accessors
  ReadonlySignal<PdfExportStatus> get exportStatus => _exportStatus;

  void _checkExportAllowed() {
    if (_disposed) throw _ExportCancelledException('Controller disposed');
    if (_cancelled) throw _ExportCancelledException();
  }

  /// The list of slides to export
  final List<SlideConfiguration> slides;

  /// Service used to capture slides
  final SlideCaptureService slideCaptureService;

  /// Duration used to wait between operations
  final Duration _waitDuration;

  /// Whether this controller has been disposed
  bool get disposed => _disposed;

  /// Page controller for navigating between slides
  PageController get pageController => _pageController;

  /// Gets the [GlobalKey] for a specific slide
  GlobalKey getSlideKey(SlideConfiguration slide) => _slideKeys[slide.key]!;

  /// Waits for a render boundary widget to be painted
  Future<void> _waitForRenderBoundaryPaint(GlobalKey key) async {
    while (key.currentContext == null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    final repaintBoundary = key.currentContext!.findRenderObject()!;
    final isAttached = repaintBoundary.attached;

    while (!isAttached) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    await WidgetsBinding.instance.endOfFrame;
  }

  /// Captures an image from a [GlobalKey] with retry logic
  Future<Uint8List> _captureImageWithRetry(GlobalKey key) async {
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await slideCaptureService.captureFromKey(
          quality: kIsWeb
              ? SlideCaptureQuality.thumbnail
              : SlideCaptureQuality.good,
          key: key,
        );
      } catch (error) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    throw Exception('Failed to capture image after $maxAttempts attempts.');
  }

  /// Prepares slides for export by ensuring they are properly rendered
  Future<void> _prepare() async {
    for (var i = 0; i < _slideKeys.length; i++) {
      // just return if cancelled
      if (_cancelled) return;
      final slide = slides[i];
      final key = _slideKeys[slide.key]!;

      await _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
      );

      await _waitForRenderBoundaryPaint(key);
    }
  }

  /// Starts the export process
  ///
  /// Captures slides as images and combines them into a PDF document.
  Future<void> export() async {
    _cancelled = false;
    _capturedCount.value = 0;
    _images.clear();
    _exportStatus.value = PdfExportStatus.preparing;

    try {
      await _prepare();

      _exportStatus.value = PdfExportStatus.capturing;

      for (var i = 0; i < _slideKeys.length; i++) {
        _checkExportAllowed(); // check before starting this iteration

        final slide = slides[i];
        final key = _slideKeys[slide.key]!;

        await _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 1),
          curve: Curves.linear,
        );

        _checkExportAllowed();
        await _waitForRenderBoundaryPaint(key);
        _checkExportAllowed();

        final image = await _captureImageWithRetry(key);
        _checkExportAllowed();

        _images.add(image);
        _capturedCount.value = _images.length;
      }

      _exportStatus.value = PdfExportStatus.building;

      await Future.delayed(_waitDuration);
      _checkExportAllowed();

      final pdf = await compute(_buildPdf, [..._images]);
      _checkExportAllowed();

      _savePdf(pdf);

      _exportStatus.value = PdfExportStatus.complete;
      _images.clear();
      _capturedCount.value = 0;
    } on _ExportCancelledException catch (e) {
      // Handle cancellation: update status.
      _exportStatus.value = PdfExportStatus.idle;

      // Optionally, log the cancellation.
      log(e.toString());
    }
  }

  /// Saves the generated PDF file
  ///
  /// Uses different approaches for web and native platforms
  Future<void> _savePdf(Uint8List pdf) async {
    try {
      if (kIsWeb) {
        final blob = html.Blob([pdf], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: url)
          ..setAttribute('download', 'superdeck.pdf')
          ..click();

        return;
      }

      log('Saving pdf');
      final result = await FileSaver.instance.saveAs(
        name: 'superdeck',
        bytes: pdf,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      log('Save result: $result');
    } catch (e) {
      log('Error saving pdf: $e');
    }
  }

  void cancel() {
    _cancelled = true;
  }

  void dispose() {
    _disposed = true;
    _pageController.dispose();

    // Dispose computed signals first, then source signals
    progress.dispose();
    progressTuple.dispose();
    _exportStatus.dispose();
    _capturedCount.dispose();
  }
}

/// Builds a PDF document from a list of images
///
/// This runs on a separate isolate via [compute]
Future<Uint8List> _buildPdf(List<Uint8List> images) async {
  final pdf = pw.Document();

  for (final imageData in images) {
    final image = pw.MemoryImage(imageData);

    final pdfImage = pw.Image(
      image,
      width: kResolution.width,
      height: kResolution.height,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(kResolution.width, kResolution.height),
        build: (pw.Context context) {
          return pw.Center(child: pdfImage);
        },
      ),
    );
  }

  return await pdf.save();
}

class _ExportCancelledException implements Exception {
  final String message;
  _ExportCancelledException([this.message = 'Export cancelled']);
  @override
  String toString() => message;
}
