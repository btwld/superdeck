import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';

import '../helpers/test_helpers.dart';

class _OpenPdfButton extends StatelessWidget {
  const _OpenPdfButton({required this.pdfSaver});

  final PdfSaver pdfSaver;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => PdfExportDialogScreen.show(context, pdfSaver: pdfSaver),
      child: const Text('Open PDF export'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfExportDialogScreen', () {
    late TestDeckLoader loader;

    setUp(() async {
      loader = TestDeckLoader(
        slides: [
          Slide(
            key: 'pdf-test',
            options: SlideOptions(title: ''),
            sections: [
              SectionBlock([WidgetBlock(name: 'open-pdf')]),
            ],
          ),
        ],
      );
    });

    tearDown(() async {
      await loader.dispose();
    });

    testWidgets('opens from a widget below SuperDeckApp', (tester) async {
      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(
            widgets: {
              'open-pdf': (_) => _OpenPdfButton(pdfSaver: (_) async => true),
            },
          ),
          deckLoader: loader,
          assetCacheStore: NoopAssetCacheStore(),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Open PDF export'));
      await tester.pump();

      expect(find.byType(PdfExportDialogScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('captures shell modal slides with Material text defaults', (
      tester,
    ) async {
      final releaseSave = Completer<bool>();
      var saverCalled = false;
      final styleLoader = TestDeckLoader(
        slides: [
          Slide(
            key: 'pdf-shell-style-test',
            options: SlideOptions(title: ''),
            sections: [
              SectionBlock([ContentBlock('# PDF shell export style test')]),
            ],
          ),
        ],
      );
      final controller = DeckController(
        deckLoader: styleLoader,
        options: DeckOptions(),
        assetCacheStore: NoopAssetCacheStore(),
      );
      addTearDown(() {
        if (!releaseSave.isCompleted) {
          releaseSave.complete(false);
        }
      });
      addTearDown(() async {
        controller.dispose();
        await styleLoader.dispose();
      });
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view
        ..physicalSize = superDeckSlideSize
        ..devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: InheritedData(
            data: controller,
            child: DeckShellModalHost(
              child: Scaffold(
                body: Center(
                  child: _OpenPdfButton(
                    pdfSaver: (_) {
                      saverCalled = true;
                      return releaseSave.future;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Open PDF export'));
      await tester.pump();

      await tester.runAsync(() async {
        for (var i = 0; i < 200 && !saverCalled; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });

      final exportedTitle = find.descendant(
        of: find.byType(PageView),
        matching: find.text('PDF shell export style test'),
      );

      expect(exportedTitle, findsOneWidget);
      expect(
        DefaultTextStyle.of(tester.element(exportedTitle)).style.decoration,
        isNot(TextDecoration.underline),
      );

      releaseSave.complete(true);
    });

    testWidgets('captures rendered slides and saves PDF bytes', (tester) async {
      Uint8List? savedPdf;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view
        ..physicalSize = superDeckSlideSize
        ..devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: PdfExportDialogScreen(
            slides: [
              SlideTestHarness.createConfiguration(
                Slide(
                  key: 'pdf-dialog-export-test',
                  options: SlideOptions(title: ''),
                  sections: [
                    SectionBlock([ContentBlock('# PDF export smoke test')]),
                  ],
                ),
              ),
            ],
            pdfSaver: (pdf) async {
              savedPdf = pdf;
              return true;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.runAsync(() async {
        for (var i = 0; i < 200 && savedPdf == null; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });

      expect(tester.takeException(), isNull);
      expect(savedPdf, isNotNull);
      expect(String.fromCharCodes(savedPdf!.take(4)), '%PDF');
    });
  });
}
