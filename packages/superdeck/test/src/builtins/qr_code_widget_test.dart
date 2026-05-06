import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:superdeck/src/builtins/qr_code_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QrCodeDto', () {
    group('parse', () {
      test('returns typed values for valid arguments', () {
        final dto = QrCodeDto.parse({
          'text': 'https://example.com',
          'size': 128.0,
          'errorCorrection': 'highest',
          'backgroundColor': '#ffffff',
          'foregroundColor': '#000000',
        });

        expect(dto.text, 'https://example.com');
        expect(dto.size, 128.0);
        expect(dto.errorCorrection, 'highest');
        expect(dto.backgroundColor, '#ffffff');
        expect(dto.foregroundColor, '#000000');
      });

      test('uses defaults when optional fields are omitted or null', () {
        final omitted = QrCodeDto.parse({'text': 'omitted'});
        final explicitNull = QrCodeDto.parse({
          'text': 'explicit-null',
          'size': null,
          'errorCorrection': null,
          'backgroundColor': null,
          'foregroundColor': null,
        });

        expect(omitted.size, 200.0);
        expect(omitted.errorCorrection, 'medium');
        expect(omitted.backgroundColor, isNull);
        expect(omitted.foregroundColor, isNull);
        expect(explicitNull.size, 200.0);
        expect(explicitNull.errorCorrection, 'medium');
      });

      test('rejects missing or empty text', () {
        expect(() => QrCodeDto.parse({}), throwsA(anything));
        expect(() => QrCodeDto.parse({'text': ''}), throwsA(anything));
      });

      test('rejects text exceeding 1000 characters', () {
        expect(() => QrCodeDto.parse({'text': 'x' * 1001}), throwsA(anything));
      });

      test('rejects invalid hex color', () {
        expect(
          () => QrCodeDto.parse({
            'text': 'hello',
            'backgroundColor': 'not-a-color',
          }),
          throwsA(anything),
        );
      });
    });
  });

  group('QrCodeWidget', () {
    testWidgets('renders a QrImageView without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrCodeWidget({
              'text': 'https://example.com',
              'size': 160.0,
              'errorCorrection': 'high',
              'backgroundColor': '#ffff00',
              'foregroundColor': '#123456',
            }),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(QrImageView), findsOneWidget);

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.size, 160.0);
      expect(qrImage.errorCorrectionLevel, QrErrorCorrectLevel.Q);
      expect(qrImage.backgroundColor, const Color(0xFFFFFF00));
      expect(qrImage.eyeStyle.color, const Color(0xFF123456));
      expect(qrImage.dataModuleStyle.color, const Color(0xFF123456));
    });
  });
}
