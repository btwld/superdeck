import 'package:flutter/material.dart' show Icons, Colors, Theme;
import 'package:flutter/widgets.dart';
import 'package:remix/remix.dart';
import 'package:superdeck/src/ui/ui.dart';
import 'package:superdeck/src/utils/constants.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/export/slide_capture_service.dart';

import '../rendering/slides/slide_view.dart';
import '../deck/slide_configuration.dart';
import 'pdf_controller.dart';

class PdfExportDialogScreen extends StatefulWidget {
  const PdfExportDialogScreen({super.key, required this.slides});

  final List<SlideConfiguration> slides;

  @override
  State<PdfExportDialogScreen> createState() => _PdfExportDialogScreenState();

  static void show(BuildContext context) {
    final deckController = DeckController.of(context);
    showRemixDialog(
      context: context,
      builder: (context) =>
          PdfExportDialogScreen(slides: deckController.slides),
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
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _handleExport());
  }

  Future<void> _handleExport() async {
    try {
      await _exportController.export();
    } finally {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
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
    return RemixDialog(
      child: SizedBox.fromSize(
        size: kResolution,
        child: ListenableBuilder(
          listenable: _exportController,
          builder: (context, _) {
            return Stack(
              children: [
                PageView.builder(
                  controller: _exportController.pageController,
                  itemCount: _exportController.slides.length,
                  itemBuilder: (context, index) {
                    // Set to exporting true
                    final slide = _exportController.slides[index].copyWith(
                      isExporting: true,
                      debug: false,
                    );

                    return RepaintBoundary(
                      key: _exportController.getSlideKey(slide),
                      child: InheritedData(
                        data: slide,
                        child: SlideView(slide),
                      ),
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
          },
        ),
      ),
    );
  }
}

class _PdfExportBar extends StatelessWidget {
  const _PdfExportBar({required this.exportController});

  final PdfController exportController;

  /// Human readable progress text
  String get _progressText {
    final current = exportController.progressTuple.$1;
    final total = exportController.progressTuple.$2;
    return switch (exportController.exportStatus) {
      PdfExportStatus.building => 'Building PDF...',
      PdfExportStatus.complete => 'Done',
      PdfExportStatus.capturing => 'Exporting $current / $total',
      PdfExportStatus.idle => 'Exporting $current / $total',
      PdfExportStatus.preparing => 'Preparing...',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          exportController.exportStatus == PdfExportStatus.complete
              ? Icon(
                  Icons.check_circle,
                  // TODO: Replace with Remix
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                )
              : SizedBox(
                  height: 32,
                  width: 32,
                  child: IsometricProgressIndicator(
                    progress: exportController.progress,
                  ),
                ),
          const SizedBox(height: 16.0),
          Text(
            _progressText,
            // TODO: Replace with Remix
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16.0),
          SDButton(
            onPressed: () {
              exportController.cancel();
              Navigator.of(context).pop();
            },
            label: 'Cancel',
            icon: Icons.cancel,
          ),
        ],
      ),
    );
  }
}
