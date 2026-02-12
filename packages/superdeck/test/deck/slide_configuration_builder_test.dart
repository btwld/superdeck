import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/deck/slide_configuration_builder.dart';
import 'package:superdeck/src/styling/styling.dart';
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
      expect(thumbnailFile, contains(configuration.thumbnailsDir.path));
      expect(thumbnailFile, contains('thumbnail_slide-1.png'));
    });

    test('omits thumbnail path when thumbnail generation is disabled', () {
      final configs = builder.buildConfigurations([
        slide,
      ], const DeckOptions(showThumbnails: false));

      expect(configs, hasLength(1));
      expect(configs.first.thumbnailFile, isNull);
    });

    test('returns empty list for empty slides', () {
      final configs = builder.buildConfigurations([], const DeckOptions());

      expect(configs, isEmpty);
    });

    test('assigns correct indices to multiple slides', () {
      final slides = [
        Slide(
          key: 'a',
          sections: [
            SectionBlock([ContentBlock('Slide A')]),
          ],
        ),
        Slide(
          key: 'b',
          sections: [
            SectionBlock([ContentBlock('Slide B')]),
          ],
        ),
        Slide(
          key: 'c',
          sections: [
            SectionBlock([ContentBlock('Slide C')]),
          ],
        ),
      ];

      final configs = builder.buildConfigurations(slides, const DeckOptions());

      expect(configs, hasLength(3));
      expect(configs[0].slideIndex, 0);
      expect(configs[1].slideIndex, 1);
      expect(configs[2].slideIndex, 2);
      expect(configs[0].key, 'a');
      expect(configs[1].key, 'b');
      expect(configs[2].key, 'c');
    });

    test('each slide gets a unique thumbnail path', () {
      final slides = [
        Slide(
          key: 'first',
          sections: [
            SectionBlock([ContentBlock('First')]),
          ],
        ),
        Slide(
          key: 'second',
          sections: [
            SectionBlock([ContentBlock('Second')]),
          ],
        ),
      ];

      final configs = builder.buildConfigurations(slides, const DeckOptions());

      expect(configs[0].thumbnailFile, contains('thumbnail_first.png'));
      expect(configs[1].thumbnailFile, contains('thumbnail_second.png'));
      expect(configs[0].thumbnailFile, isNot(configs[1].thumbnailFile));
    });

    test('applies base style via merge chain', () {
      final baseStyle = SlideStyle(
        link: const TextStyle(color: Color(0xFFFF0000)),
      );

      final configs = builder.buildConfigurations([
        slide,
      ], DeckOptions(baseStyle: baseStyle));

      final expected = defaultSlideStyle.merge(baseStyle);
      expect(configs.first.style, expected);
    });

    test('slide-specific style takes precedence over base', () {
      final baseStyle = SlideStyle(
        link: const TextStyle(color: Color(0xFF0000FF)),
      );
      final customStyle = SlideStyle(
        link: const TextStyle(color: Color(0xFFFF0000)),
      );

      final slideWithStyle = Slide(
        key: 'styled',
        sections: [
          SectionBlock([ContentBlock('Styled')]),
        ],
        options: const SlideOptions(style: 'custom'),
      );

      final configs = builder.buildConfigurations([
        slideWithStyle,
      ], DeckOptions(baseStyle: baseStyle, styles: {'custom': customStyle}));

      final expected = defaultSlideStyle.merge(baseStyle).merge(customStyle);
      expect(configs.first.style, expected);
    });

    test('passes debug flag through to configurations', () {
      final configs = builder.buildConfigurations([
        slide,
      ], const DeckOptions(debug: true));

      expect(configs.first.debug, isTrue);
    });
  });
}
