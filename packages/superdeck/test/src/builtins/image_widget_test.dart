import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/builtins/image_widget.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck/src/ui/widgets/cache_image_widget.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageDto', () {
    group('parse', () {
      test('returns typed values for valid arguments', () {
        final dto = ImageDto.parse({
          'src': 'assets/logo.png',
          'fit': 'cover',
          'width': 300.0,
          'height': 200.0,
        });

        expect(dto.src, Uri.parse('assets/logo.png'));
        expect(dto.fit, ImageFit.cover);
        expect(dto.width, 300.0);
        expect(dto.height, 200.0);
      });

      test('uses defaults when optional fields are omitted or null', () {
        final omitted = ImageDto.parse({'src': 'assets/x.png'});
        final explicitNull = ImageDto.parse({
          'src': 'assets/x.png',
          'fit': null,
          'width': null,
          'height': null,
        });

        expect(omitted.fit, ImageFit.contain);
        expect(omitted.width, isNull);
        expect(omitted.height, isNull);
        expect(explicitNull.fit, ImageFit.contain);
        expect(explicitNull.width, isNull);
        expect(explicitNull.height, isNull);
      });

      test('trims whitespace from src', () {
        final dto = ImageDto.parse({'src': '  assets/logo.png  '});
        expect(dto.src, Uri.parse('assets/logo.png'));
      });

      test('parses http URL sources', () {
        final dto = ImageDto.parse({'src': 'https://example.com/img.png'});
        expect(dto.src.scheme, 'https');
        expect(dto.src.host, 'example.com');
      });

      test('rejects missing src', () {
        expect(() => ImageDto.parse({}), throwsA(anything));
      });

      test('rejects empty src', () {
        expect(() => ImageDto.parse({'src': ''}), throwsA(anything));
        expect(() => ImageDto.parse({'src': '   '}), throwsA(anything));
      });

      test('rejects wrong types', () {
        expect(() => ImageDto.parse({'src': 42}), throwsA(anything));
        expect(
          () => ImageDto.parse({'src': 'a.png', 'width': 'huge'}),
          throwsA(anything),
        );
      });

      test('accepts each valid ImageFit value', () {
        for (final fit in ImageFit.values) {
          final dto = ImageDto.parse({'src': 'a.png', 'fit': fit.toJson()});
          expect(dto.fit, fit);
        }
      });
    });
  });

  group('ImageWidget', () {
    testWidgets('renders a cached image with explicit sizing and fit', (
      tester,
    ) async {
      const size = Size(640, 480);

      await tester.pumpWidget(
        const _ImageHarness(
          size: size,
          args: {
            'src': _transparentPixelDataUri,
            'fit': 'cover',
            'width': 120.0,
            'height': 80.0,
          },
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CachedImage), findsOneWidget);

      final image = tester.widget<CachedImage>(find.byType(CachedImage));
      expect(image.uri.scheme, 'data');
      expect(image.targetSize, size);

      final explicitSize = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(CachedImage),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(explicitSize.width, 120.0);
      expect(explicitSize.height, 80.0);
    });
  });
}

const _transparentPixelDataUri =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

class _ImageHarness extends StatelessWidget {
  final Map<String, Object?> args;
  final Size size;

  const _ImageHarness({required this.args, required this.size});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InheritedData<BlockConfiguration>(
        data: BlockConfiguration(
          spec: const SlideSpec(),
          size: size,
          align: ContentAlignment.center,
        ),
        child: Scaffold(body: ImageWidget(args)),
      ),
    );
  }
}
