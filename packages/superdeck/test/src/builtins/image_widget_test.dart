import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/builtins/image_widget.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck/src/ui/widgets/cache_image_widget.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/ui/widgets/resolved_asset_image.dart';
import 'package:superdeck/src/utils/converters.dart';
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
          'scale': 1.25,
        });

        expect(dto.src, Uri.parse('assets/logo.png'));
        expect(dto.fit, ImageFit.cover);
        expect(dto.width, 300.0);
        expect(dto.height, 200.0);
        expect(dto.scale, 1.25);
      });

      test('uses defaults when optional fields are omitted or null', () {
        final omitted = ImageDto.parse({'src': 'assets/x.png'});
        final explicitNull = ImageDto.parse({
          'src': 'assets/x.png',
          'fit': null,
          'width': null,
          'height': null,
          'scale': null,
        });

        expect(omitted.fit, ImageFit.contain);
        expect(omitted.width, isNull);
        expect(omitted.height, isNull);
        expect(omitted.scale, 1.0);
        expect(explicitNull.fit, ImageFit.contain);
        expect(explicitNull.width, isNull);
        expect(explicitNull.height, isNull);
        expect(explicitNull.scale, 1.0);
      });

      test('accepts integer width, height, and scale authoring', () {
        final dto = ImageDto.parse({
          'src': 'assets/logo.png',
          'width': 300,
          'height': 300,
          'scale': 1,
        });

        expect(dto.width, 300.0);
        expect(dto.height, 300.0);
        expect(dto.scale, 1.0);
      });

      test('rejects non-positive dimensions with one numeric rule', () {
        for (final field in const ['width', 'height', 'scale']) {
          for (final value in [0, -1, double.nan, double.infinity]) {
            expect(
              () => ImageDto.parse({'src': 'a.png', field: value}),
              throwsA(anything),
              reason: '$field: $value',
            );
          }
        }
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

      test('parses data URI, absolute, file URI, and Windows path sources', () {
        final dataUri = ImageDto.parse({'src': _transparentPixelDataUri});
        expect(dataUri.src.scheme, 'data');

        final absolute = ImageDto.parse({'src': '/tmp/superdeck-image.png'});
        expect(absolute.src.path, '/tmp/superdeck-image.png');

        final fileUri = ImageDto.parse({
          'src': 'file:///tmp/superdeck-image.png',
        });
        expect(fileUri.src.scheme, 'file');
        expect(fileUri.src.path, '/tmp/superdeck-image.png');

        final windows = ImageDto.parse({'src': r'C:\Users\me\image.png'});
        expect(windows.src.scheme, 'file');
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

      test('rejects non-positive and non-finite scale with field context', () {
        for (final scale in [
          0.0,
          -1.0,
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]) {
          expect(
            () => ImageDto.parse({'src': 'a.png', 'scale': scale}),
            throwsA(
              isA<ArgumentError>()
                  .having((error) => error.name, 'name', 'scale')
                  .having(
                    (error) => error.message.toString(),
                    'message',
                    contains('finite number greater than zero'),
                  ),
            ),
          );
        }
      });

      test('public construction enforces the same scale invariant', () {
        final dto = ImageDto(src: Uri.parse('a.png'), scale: 1.25);
        expect(dto.scale, 1.25);

        expect(
          () => ImageDto(src: Uri.parse('a.png'), scale: 0),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', 'scale')
                .having(
                  (error) => error.message.toString(),
                  'message',
                  contains('finite number greater than zero'),
                ),
          ),
        );
      });
    });
  });

  group('image provider selection', () {
    test('uses memory provider for data URI images', () {
      final provider = getImageProvider(Uri.parse(_transparentPixelDataUri));
      expect(provider, isA<MemoryImage>());
    });

    test('uses file provider for absolute, file URI, and relative paths', () {
      final absolute = getImageProvider(Uri.file('/tmp/superdeck-image.png'));
      final fileUri = getImageProvider(Uri.parse('file:///tmp/from-uri.png'));
      final relative = getImageProvider(Uri.parse('assets/concepta-icon.png'));

      expect(absolute, isA<FileImage>());
      expect(fileUri, isA<FileImage>());
      expect(relative, isA<FileImage>());
      expect(
        (relative as FileImage).file.path,
        endsWith('assets/concepta-icon.png'),
      );
    });

    test('uses cached network provider for http and https images', () {
      final http = getImageProvider(Uri.parse('http://example.com/a.png'));
      final https = getImageProvider(Uri.parse('https://example.com/a.jpg'));

      expect(http, isA<CachedNetworkImageProvider>());
      expect(https, isA<CachedNetworkImageProvider>());
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
      expect(_insideImageWidget(Transform), findsNothing);
      expect(_insideImageWidget(ClipRect), findsNothing);
    });

    for (final fit in ImageFit.values) {
      testWidgets('applies ${fit.name} fit to CachedImage', (tester) async {
        await tester.pumpWidget(
          _ImageHarness(
            size: const Size(640, 480),
            args: {'src': _transparentPixelDataUri, 'fit': fit.toJson()},
          ),
        );
        await tester.pump();

        final image = tester.widget<CachedImage>(find.byType(CachedImage));
        expect(image.styleSpec.spec.fit, fit.toBoxFit);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('scale one retains the current widget path exactly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _ImageHarness(
          size: Size(640, 480),
          args: {'src': _transparentPixelDataUri, 'scale': 1.0},
        ),
      );
      await tester.pump();

      expect(find.byType(CachedImage), findsOneWidget);
      expect(_insideImageWidget(Transform), findsNothing);
      expect(_insideImageWidget(ClipRect), findsNothing);
    });

    testWidgets('scale paints inside the content frame using block alignment', (
      tester,
    ) async {
      const frameSize = Size(640, 480);
      await tester.pumpWidget(
        const _ImageHarness(
          size: frameSize,
          align: ContentAlignment.bottomRight,
          args: {'src': _transparentPixelDataUri, 'scale': 1.25},
        ),
      );
      await tester.pump();

      expect(find.byType(CachedImage), findsOneWidget);
      final transformFinder = _insideImageWidget(Transform);
      final clipFinder = _insideImageWidget(ClipRect);
      expect(transformFinder, findsOneWidget);
      expect(clipFinder, findsOneWidget);

      final transform = tester.widget<Transform>(transformFinder);
      expect(transform.alignment, Alignment.bottomRight);
      expect(transform.transform.storage[0], 1.25);
      expect(transform.transform.storage[5], 1.25);
      expect(tester.getSize(clipFinder), frameSize);
      expect(
        tester.getSize(transformFinder),
        tester.getSize(find.byType(CachedImage)),
      );

      final image = tester.widget<CachedImage>(find.byType(CachedImage));
      expect(image.styleSpec.spec.alignment, Alignment.bottomRight);
    });

    testWidgets('explicit dimensions define the scaled clipping frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _ImageHarness(
          size: Size(640, 480),
          args: {
            'src': _transparentPixelDataUri,
            'width': 120.0,
            'height': 80.0,
            'scale': 1.25,
          },
        ),
      );
      await tester.pump();

      expect(tester.getSize(_insideImageWidget(ClipRect)), const Size(120, 80));
      expect(
        tester.getSize(_insideImageWidget(Transform)),
        const Size(120, 80),
      );
      expect(tester.getSize(find.byType(CachedImage)), const Size(120, 80));
    });

    testWidgets('scaled bare-key images reuse the existing resolver path', (
      tester,
    ) async {
      final store = _CountingCacheStore();
      final harness = _ImageHarness(
        size: const Size(640, 480),
        assetCacheStore: store,
        args: const {'src': 'generated-image.png', 'scale': 1.25},
      );

      await tester.pumpWidget(harness);
      await tester.pumpAndSettle();

      expect(store.resolveCount, 1);
      expect(find.byType(ResolvedAssetImage), findsOneWidget);
      expect(find.byType(CachedImage), findsOneWidget);
      expect(_insideImageWidget(Transform), findsOneWidget);

      await tester.pumpWidget(harness);
      await tester.pumpAndSettle();
      expect(store.resolveCount, 1);
    });
  });
}

const _transparentPixelDataUri =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

class _ImageHarness extends StatelessWidget {
  final Map<String, Object?> args;
  final Size size;
  final ContentAlignment align;
  final AssetCacheStore? assetCacheStore;

  const _ImageHarness({
    required this.args,
    required this.size,
    this.align = ContentAlignment.center,
    this.assetCacheStore,
  });

  @override
  Widget build(BuildContext context) {
    Widget tree = InheritedData<BlockConfiguration>(
      data: BlockConfiguration(
        spec: const SlideSpec(),
        size: size,
        align: align,
        runtimeKey: 'test-slide:s0:b0',
      ),
      child: Scaffold(body: ImageWidget(args)),
    );

    if (assetCacheStore case final store?) {
      tree = InheritedData<SlideConfiguration>(
        data: SlideConfiguration(
          slideIndex: 0,
          style: SlideStyler(),
          slide: Slide(key: 'image-test'),
          thumbnailKey: 'image-test-thumbnail.png',
          assetCacheStore: store,
        ),
        child: tree,
      );
    }

    return MaterialApp(home: tree);
  }
}

class _CountingCacheStore implements AssetCacheStore {
  int resolveCount = 0;

  @override
  Future<void> delete(String assetKey) async {}

  @override
  Future<Uri?> resolve(String assetKey) async {
    resolveCount += 1;
    return Uri.parse(_transparentPixelDataUri);
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async => null;
}

Finder _insideImageWidget(Type type) {
  return find.descendant(
    of: find.byType(ImageWidget),
    matching: find.byType(type),
  );
}
