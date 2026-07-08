import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'pdf_controller.dart';
import 'pdf_export_options.dart';

/// Internal dialog surface used to capture slides and export them as a PDF.
class PdfExportDialogScreen extends StatefulWidget {
  /// Creates a PDF export dialog for [slides].
  const PdfExportDialogScreen({
    super.key,
    required this.slides,
    this.options = const PdfExportOptions(),
    this.onClose,
  });

  /// Slides to capture into the PDF.
  final List<SlideConfiguration> slides;

  /// PDF export configuration.
  final PdfExportOptions options;

  /// Callback used when the export surface is hosted by a shell modal.
  final VoidCallback? onClose;

  @override
  State<PdfExportDialogScreen> createState() => _PdfExportDialogScreenState();

  /// Opens the PDF export flow for the deck in [context].
  ///
  /// Uses the SuperDeck shell modal when available; otherwise falls back to a
  /// non-dismissible Flutter dialog.
  static Future<void> show(
    BuildContext context, {
    PdfExportOptions options = const PdfExportOptions(),
  }) {
    final deckController = DeckController.of(context);
    final slides = deckController.slides.value;
    final shellModal = DeckShellModal.maybeOf(context);
    if (shellModal != null) {
      DeckShellModalEntry? entry;
      entry = shellModal.show(
        builder: (context) => PdfExportDialogScreen(
          slides: slides,
          options: options,
          onClose: () => entry?.close(),
        ),
      );

      return entry.closed;
    }

    final dialogContext =
        deckController
            .presentation
            .router
            .routerDelegate
            .navigatorKey
            .currentContext ??
        context;

    return showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) =>
          PdfExportDialogScreen(slides: slides, options: options),
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
      options: widget.options,
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
    await _exportController.export();
    if (!mounted) return;

    if (_exportController.exportStatus.value != PdfExportStatus.failed) {
      _close();
    }
  }

  void _close() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
      return;
    }

    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
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
    return SignalBuilder(
      builder: (context) {
        _exportController.exportStatus.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: SizedBox.fromSize(
                size: superDeckSlideSize,
                child: PageView.builder(
                  controller: _exportController.pageController,
                  itemCount: _exportController.slides.length,
                  itemBuilder: (context, index) {
                    final slide = _exportController.slides[index].copyWith(
                      isStaticRendering: true,
                      debug: false,
                    );

                    return RepaintBoundary(
                      key: _exportController.getSlideKey(slide),
                      child: _PdfSlideCaptureView(slide: slide),
                    );
                  },
                ),
              ),
            ),
            const ModalBarrier(color: Colors.black, dismissible: false),
            Center(
              child: _PdfExportBar(
                exportController: _exportController,
                onCancel: () {
                  _exportController.cancel();
                  _close();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PdfSlideCaptureView extends StatelessWidget {
  const _PdfSlideCaptureView({required this.slide});

  final SlideConfiguration slide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlideRenderView(slide),
    );
  }
}

class _PdfExportBar extends StatelessWidget {
  const _PdfExportBar({required this.exportController, required this.onCancel});

  final PdfController exportController;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final status = exportController.exportStatus.value;
        final progressValue = exportController.progress.value;
        final (current, total) = exportController.progressTuple.value;
        final theme = Theme.of(context);
        final indicatorValue = status == PdfExportStatus.capturing
            ? progressValue
            : null;
        final isDone = switch (status) {
          PdfExportStatus.complete || PdfExportStatus.failed => true,
          _ => false,
        };

        final progressText = switch (status) {
          PdfExportStatus.building => 'Building PDF...',
          PdfExportStatus.complete => 'Done',
          PdfExportStatus.capturing => 'Exporting $current / $total',
          PdfExportStatus.idle => 'Exporting $current / $total',
          PdfExportStatus.preparing => 'Preparing...',
          PdfExportStatus.failed =>
            exportController.exportError.value ?? 'Export failed',
        };

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, minWidth: 280),
          child: Material(
            color: const Color(0xff171717),
            elevation: 24,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  switch (status) {
                    PdfExportStatus.complete => Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    PdfExportStatus.failed => Icon(
                      Icons.error,
                      color: theme.colorScheme.error,
                      size: 32,
                    ),
                    _ => SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(value: indicatorValue),
                    ),
                  },
                  const SizedBox(height: 16.0),
                  Text(
                    progressText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton.icon(
                    onPressed: onCancel,
                    icon: Icon(isDone ? Icons.close : Icons.cancel),
                    label: Text(isDone ? 'Close' : 'Cancel'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
