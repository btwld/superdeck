import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'pdf_controller.dart';

class PdfExportDialogScreen extends StatefulWidget {
  const PdfExportDialogScreen({super.key, required this.slides, this.pdfSaver});

  final List<SlideConfiguration> slides;
  final PdfSaver? pdfSaver;

  @override
  State<PdfExportDialogScreen> createState() => _PdfExportDialogScreenState();

  static void show(BuildContext context, {PdfSaver? pdfSaver}) {
    final deckController = DeckController.of(context);
    final dialogContext =
        deckController.router.routerDelegate.navigatorKey.currentContext ??
        context;

    showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => PdfExportDialogScreen(
        slides: deckController.slides.value,
        pdfSaver: pdfSaver,
      ),
    );
  }
}

class _PdfExportDialogScreenState extends State<PdfExportDialogScreen> {
  late PdfController _exportController;

  @override
  void initState() {
    super.initState();
    _setupExportController();
  }

  void _setupExportController() {
    _exportController = PdfController(
      slides: widget.slides,
      slideCaptureService: SlideCaptureService(),
      pdfSaver: widget.pdfSaver,
    );

    _scheduleExportAfterMount();
  }

  void _scheduleExportAfterMount() {
    // Wait until the dialog and PageView are both mounted before capture.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleExport();
      });
    });
  }

  Future<void> _handleExport() async {
    Object? error;
    StackTrace? stackTrace;

    try {
      await _exportController.export();
    } catch (caughtError, caughtStackTrace) {
      error = caughtError;
      stackTrace = caughtStackTrace;
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (error != null) {
      Error.throwWithStackTrace(error, stackTrace!);
    }
  }

  @override
  void didUpdateWidget(PdfExportDialogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides != widget.slides) {
      _exportController.dispose();
      _setupExportController();
    }
  }

  @override
  void dispose() {
    _exportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: SizedBox.fromSize(
        size: superDeckSlideSize,
        child: Watch((context) {
          _exportController.exportStatus.value;

          return Stack(
            children: [
              PageView.builder(
                controller: _exportController.pageController,
                itemCount: _exportController.slides.length,
                itemBuilder: (context, index) {
                  final slide = _exportController.slides[index].copyWith(
                    isStaticRendering: true,
                    debug: false,
                  );

                  return RepaintBoundary(
                    key: _exportController.getSlideKey(slide),
                    child: SlideRenderView(slide),
                  );
                },
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Align(
                    alignment: Alignment.center,
                    child: _PdfExportBar(exportController: _exportController),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _PdfExportBar extends StatelessWidget {
  const _PdfExportBar({required this.exportController});

  final PdfController exportController;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final status = exportController.exportStatus.value;
      final progressValue = exportController.progress.value;
      final (current, total) = exportController.progressTuple.value;

      final progressText = switch (status) {
        PdfExportStatus.building => 'Building PDF...',
        PdfExportStatus.complete => 'Done',
        PdfExportStatus.capturing => 'Exporting $current / $total',
        PdfExportStatus.idle => 'Exporting $current / $total',
        PdfExportStatus.preparing => 'Preparing...',
        PdfExportStatus.failed =>
          exportController.exportError.value ?? 'Export failed',
      };

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            switch (status) {
              PdfExportStatus.complete => Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              PdfExportStatus.failed => Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.error,
                size: 32,
              ),
              _ => SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(value: progressValue),
              ),
            },
            const SizedBox(height: 16.0),
            Text(
              progressText,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                exportController.cancel();
                Navigator.of(context, rootNavigator: true).pop();
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
            ),
          ],
        ),
      );
    });
  }
}
