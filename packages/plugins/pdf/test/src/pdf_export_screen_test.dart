import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
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
  });
}
