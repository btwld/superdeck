import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/deck/slide_configuration_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('SlideConfigurationBuilder', () {
    late Slide slide;
    late SlideConfigurationBuilder builder;
    late DeckConfiguration configuration;

    setUp(() {
      slide = Slide(
        key: 'slide-1',
        sections: [
          SectionBlock([ContentBlock('Hello world')]),
        ],
      );
      configuration = DeckConfiguration(projectDir: '/tmp/superdeck');
      builder = SlideConfigurationBuilder(configuration: configuration);
    });

    test('generates thumbnail path by default', () {
      final configs = builder.buildConfigurations([slide], const DeckOptions());

      expect(configs, hasLength(1));
      final thumbnailFile = configs.first.thumbnailFile;
      expect(thumbnailFile, isNotNull);
      expect(thumbnailFile, contains(configuration.assetsDir.path));
      expect(thumbnailFile, contains('thumbnail_slide-1.png'));
    });

    test('omits thumbnail path when thumbnail generation is disabled', () {
      final configs = builder.buildConfigurations([
        slide,
      ], const DeckOptions(generateThumbnails: false));

      expect(configs, hasLength(1));
      expect(configs.first.thumbnailFile, isNull);
    });
  });
}
