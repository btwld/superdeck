import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('ThumbnailManifest', () {
    late ThumbnailRenderSignature signature;
    late List<ThumbnailManifestSlide> slides;

    setUp(() {
      signature = const ThumbnailRenderSignature(
        viewportWidth: 1920,
        viewportHeight: 1080,
        devicePixelRatio: 2.0,
        quality: 90,
      );
      slides = const [
        ThumbnailManifestSlide(
          slideKey: 'intro',
          fileName: 'thumbnail_intro.png',
        ),
        ThumbnailManifestSlide(
          slideKey: 'agenda',
          fileName: 'thumbnail_agenda.png',
        ),
      ];
    });

    test('serializes and deserializes with toMap/fromMap', () {
      final manifest = ThumbnailManifest(
        schemaVersion: 1,
        renderSignature: signature,
        slides: slides,
      );

      final restored = ThumbnailManifest.fromMap(manifest.toMap());

      expect(restored, manifest);
    });

    test('parse accepts valid payload', () {
      final manifest = ThumbnailManifest.parse({
        'schema_version': 1,
        'render_signature': {
          'viewport_width': 1920,
          'viewport_height': 1080,
          'device_pixel_ratio': 2.0,
          'quality': 90,
        },
        'slides': [
          {'slide_key': 'intro', 'file_name': 'thumbnail_intro.png'},
        ],
      });

      expect(manifest.schemaVersion, 1);
      expect(manifest.renderSignature.viewportWidth, 1920);
      expect(manifest.slides, hasLength(1));
      expect(manifest.slides.first.slideKey, 'intro');
    });

    test('parse throws on missing render_signature', () {
      expect(
        () => ThumbnailManifest.parse({
          'schema_version': 1,
          'slides': [
            {'slide_key': 'intro', 'file_name': 'thumbnail_intro.png'},
          ],
        }),
        throwsA(isA<Object>()),
      );
    });

    test('parse throws on invalid slides payload', () {
      expect(
        () => ThumbnailManifest.parse({
          'schema_version': 1,
          'render_signature': {
            'viewport_width': 1920,
            'viewport_height': 1080,
            'device_pixel_ratio': 2.0,
            'quality': 90,
          },
          'slides': [
            {'slide_key': 100, 'file_name': true},
          ],
        }),
        throwsA(isA<Object>()),
      );
    });
  });
}
