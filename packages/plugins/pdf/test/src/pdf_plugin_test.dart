import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck_pdf/superdeck_pdf.dart';

import '../helpers/test_helpers.dart';

class _OpenPdfActionButton extends StatelessWidget {
  const _OpenPdfActionButton({required this.action});

  final DeckAction action;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => action.invoke(context, DeckController.of(context)),
      child: const Text('Open PDF action'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pdfActions', () {
    test('exposes one Export PDF deck action', () {
      final actions = pdfActions();

      expect(actions, hasLength(1));
      expect(actions.single.label, 'Export PDF');
    });

    testWidgets('export action opens the PDF export screen', (tester) async {
      final loader = TestDeckLoader(
        slides: [
          Slide(
            key: 'pdf-action-test',
            options: SlideOptions(title: ''),
            sections: [
              SectionBlock([WidgetBlock(name: 'open-pdf-action')]),
            ],
          ),
        ],
      );
      addTearDown(loader.dispose);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view
        ..physicalSize = superDeckSlideSize
        ..devicePixelRatio = 1.0;

      await tester.pumpWidget(
        SuperDeckApp(
          options: DeckOptions(
            widgets: {
              'open-pdf-action': (_) => _OpenPdfActionButton(
                action: pdfExportAction(pdfSaver: (_) async => true),
              ),
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

      await tester.tap(find.text('Open PDF action'));
      await tester.pump();

      expect(find.byType(PdfExportDialogScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
