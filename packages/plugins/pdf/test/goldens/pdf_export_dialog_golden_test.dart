import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';
import 'package:superdeck_pdf/src/pdf_export_screen.dart';

import '../helpers/test_helpers.dart';

final _goldenBoundaryKey = GlobalKey(debugLabel: 'pdf-export-dialog-golden');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PDF export dialog building state matches golden',
    (tester) async {
      final releaseSave = Completer<bool>();
      var saverCalled = false;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        if (!releaseSave.isCompleted) {
          releaseSave.complete(false);
        }
      });

      tester.view
        ..physicalSize = superDeckSlideSize
        ..devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Ahem'),
          home: RepaintBoundary(
            key: _goldenBoundaryKey,
            child: TickerMode(
              enabled: false,
              child: PdfExportDialogScreen(
                slides: [
                  SlideTestHarness.createConfiguration(
                    Slide(
                      key: 'pdf-dialog-golden',
                      options: SlideOptions(title: ''),
                      sections: [
                        SectionBlock([ContentBlock('# PDF export golden')]),
                      ],
                    ),
                  ),
                ],
                options: PdfExportOptions(
                  pdfSaver: (_) {
                    saverCalled = true;
                    return releaseSave.future;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await _pumpUntil(
        tester,
        () => saverCalled && find.text('Building PDF...').evaluate().isNotEmpty,
        debugLabel: 'PDF export dialog building state',
      );

      await expectLater(
        find.byKey(_goldenBoundaryKey),
        matchesGoldenFile('pdf_export_dialog_building.png'),
      );

      releaseSave.complete(true);
      await tester.pump();
    },
    tags: ['ci-excluded', 'golden'],
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String debugLabel,
  Duration timeout = const Duration(seconds: 20),
}) async {
  await tester.runAsync(() async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (condition()) return;

      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  if (!condition()) {
    fail('Timed out waiting for $debugLabel after ${timeout.inSeconds}s');
  }
}
