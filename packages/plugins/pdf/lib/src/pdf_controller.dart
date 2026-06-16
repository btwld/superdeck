import 'dart:async';
import 'dart:developer';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:signals/signals.dart';
import 'package:superdeck/superdeck.dart';

/// Persists generated PDF bytes.
///
/// Return `true` when the save succeeds and `false` when the user cancels or
/// chooses not to persist the file. Throw to mark the export as failed.
typedef PdfSaver = Future<bool> Function(Uint8List pdf);

/// Status values for PDF export.
enum PdfExportStatus {
  /// No export is in progress.
  idle,

  /// Slide images are being captured.
  capturing,

  /// A PDF is being built from captured images.
  building,

  /// The PDF export completed successfully.
  complete,

  /// Slides are being prepared for capture.
  preparing,

  /// The PDF export failed.
  failed,
}

/// Exports slides to a PDF document.
///
/// This controller captures each slide as an image and combines the results
/// into a PDF on web and native platforms.
class PdfController {
  static const _kPollInterval = Duration(milliseconds: 10);
  static const _kRetryDelay = Duration(milliseconds: 100);
  static const _kPrepareAnimationDuration = Duration(milliseconds: 50);
  static const _kCaptureAnimationDuration = Duration(milliseconds: 1);
  static const _kRenderAttachmentTimeout = Duration(seconds: 5);

  /// Creates a controller that exports [slides] with [slideCaptureService].
  ///
  /// The controller waits [waitDuration] between export stages and gives each
  /// render boundary up to [renderAttachmentTimeout] to attach.
  PdfController({
    required this.slides,
    required this.slideCaptureService,
    PdfSaver? pdfSaver,
    Duration waitDuration = const Duration(milliseconds: 100),
    Duration renderAttachmentTimeout = _kRenderAttachmentTimeout,
  }) : _pdfSaver = pdfSaver ?? _defaultPdfSaver,
       _waitDuration = waitDuration,
       _renderAttachmentTimeout = renderAttachmentTimeout {
    _pageController = PageController(initialPage: 0);
    _slideKeys = {for (var slide in slides) slide.key: GlobalKey()};
  }

  late final PageController _pageController;
  late final Map<String, GlobalKey> _slideKeys;
  final PdfSaver _pdfSaver;
  final List<Uint8List> _images = [];
  bool _disposed = false;
  bool _cancelled = false;

  final _exportStatus = signal<PdfExportStatus>(PdfExportStatus.idle);
  final _capturedCount = signal<int>(0);
  final _exportError = signal<String?>(null);

  /// Fraction of slides captured during the current export.
  late final progress = computed(() {
    if (_slideKeys.isEmpty) return 0.0;
    return _capturedCount.value / _slideKeys.length;
  });

  /// The current captured slide count and total slide count.
  late final progressTuple = computed(() {
    return (_capturedCount.value, _slideKeys.length);
  });

  /// Current export phase.
  ReadonlySignal<PdfExportStatus> get exportStatus => _exportStatus;

  /// Last export error message, if the export failed.
  ReadonlySignal<String?> get exportError => _exportError;

  void _checkExportAllowed() {
    if (_disposed) throw _ExportCancelledException('Controller disposed');
    if (_cancelled) throw _ExportCancelledException();
  }

  /// The slides to export.
  final List<SlideConfiguration> slides;

  /// The service used to capture slides.
  final SlideCaptureService slideCaptureService;

  final Duration _waitDuration;
  final Duration _renderAttachmentTimeout;

  /// Whether this controller has been disposed.
  bool get disposed => _disposed;

  /// The page controller used during export.
  PageController get pageController => _pageController;

  /// The [GlobalKey] for [slide].
  GlobalKey getSlideKey(SlideConfiguration slide) => _slideKeys[slide.key]!;

  /// Waits until [key]'s render boundary is attached.
  @visibleForTesting
  Future<void> waitForRenderBoundaryPaint(GlobalKey key) =>
      _waitForRenderBoundaryPaint(key);

  /// Waits for [key]'s render boundary to attach.
  Future<void> _waitForRenderBoundaryPaint(GlobalKey key) async {
    var elapsed = Duration.zero;
    var hasSeenContext = false;

    while (elapsed < _renderAttachmentTimeout) {
      _checkExportAllowed();

      if (key.currentContext != null) {
        hasSeenContext = true;
      }

      final repaintBoundary = key.currentContext?.findRenderObject();
      if (repaintBoundary != null && repaintBoundary.attached) {
        await WidgetsBinding.instance.endOfFrame;
        return;
      }
      await Future.delayed(_kPollInterval);
      elapsed += _kPollInterval;
    }

    throw StateError(
      hasSeenContext
          ? 'RenderObject not attached within $_renderAttachmentTimeout'
          : 'RenderObject context not available within $_renderAttachmentTimeout',
    );
  }

  Future<void> _waitForPageControllerAttachment() async {
    var elapsed = Duration.zero;

    while (elapsed < _renderAttachmentTimeout) {
      _checkExportAllowed();

      if (_pageController.hasClients) {
        await WidgetsBinding.instance.endOfFrame;
        return;
      }

      await Future.delayed(_kPollInterval);
      elapsed += _kPollInterval;
    }

    throw StateError(
      'PageController not attached within $_renderAttachmentTimeout',
    );
  }

  /// Captures [key] with retry logic.
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
        await Future.delayed(_kRetryDelay);
      }
    }
    throw Exception('Failed to capture image after $maxAttempts attempts.');
  }

  /// Prepares slides for export by ensuring they are rendered.
  Future<void> _prepare() async {
    for (var i = 0; i < _slideKeys.length; i++) {
      if (_cancelled) return;
      final slide = slides[i];
      final key = _slideKeys[slide.key]!;

      await _waitForPageControllerAttachment();
      await _pageController.animateToPage(
        i,
        duration: _kPrepareAnimationDuration,
        curve: Curves.linear,
      );

      await _waitForRenderBoundaryPaint(key);
    }
  }

  /// Captures each slide and writes the resulting PDF.
  Future<void> export() async {
    _cancelled = false;
    _capturedCount.value = 0;
    _images.clear();
    _exportStatus.value = PdfExportStatus.preparing;

    try {
      await _prepare();

      _exportStatus.value = PdfExportStatus.capturing;

      for (var i = 0; i < _slideKeys.length; i++) {
        _checkExportAllowed();

        final slide = slides[i];
        final key = _slideKeys[slide.key]!;

        await _waitForPageControllerAttachment();
        await _pageController.animateToPage(
          i,
          duration: _kCaptureAnimationDuration,
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

      _images.clear();
      _capturedCount.value = 0;
      if (!await _savePdf(pdf)) {
        _exportStatus.value = PdfExportStatus.idle;
        return;
      }

      _exportStatus.value = PdfExportStatus.complete;
    } on _ExportCancelledException catch (e) {
      _exportStatus.value = PdfExportStatus.idle;
      log(e.toString());
    } catch (e) {
      _exportError.value = 'Export failed: $e';
      _exportStatus.value = PdfExportStatus.failed;
      rethrow;
    }
  }

  /// Saves [pdf] using the injected [PdfSaver].
  Future<bool> _savePdf(Uint8List pdf) => _pdfSaver(pdf);

  /// Requests cancellation of the active export.
  void cancel() {
    _cancelled = true;
  }

  /// Releases page-controller and signal resources owned by this controller.
  void dispose() {
    _disposed = true;
    _pageController.dispose();

    // Dispose computed signals first, then source signals
    progress.dispose();
    progressTuple.dispose();
    _exportStatus.dispose();
    _capturedCount.dispose();
    _exportError.dispose();
  }
}

/// Default [PdfSaver] that uses [FileSaver] to save via platform dialog.
Future<bool> _defaultPdfSaver(Uint8List pdf) async {
  final saver = FileSaver.instance;
  const name = 'superdeck';
  const ext = 'pdf';
  const mime = MimeType.pdf;

  // Web doesn't support saveAs (throws UnimplementedError),
  // so use saveFile which triggers a browser download.
  if (kIsWeb) {
    await saver.saveFile(name: name, bytes: pdf, ext: ext, mimeType: mime);
    return true;
  }

  final result = await saver.saveAs(
    name: name,
    bytes: pdf,
    ext: ext,
    mimeType: mime,
  );
  return result != null;
}

/// Builds a PDF document from [images].
///
/// This runs on a separate isolate via [compute]
Future<Uint8List> _buildPdf(List<Uint8List> images) async {
  final pdf = pw.Document();

  for (final imageData in images) {
    final image = pw.MemoryImage(imageData);

    final pdfImage = pw.Image(
      image,
      width: superDeckSlideSize.width,
      height: superDeckSlideSize.height,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          superDeckSlideSize.width,
          superDeckSlideSize.height,
        ),
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
