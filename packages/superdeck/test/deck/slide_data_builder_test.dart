import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:superdeck/src/slides/slide_data_builder.dart';

void main() {
  final config = DeckWorkspace();
  final builder = SlideDataBuilder(configuration: config);

  group('SlideDataBuilder', () {
    test('returns empty list for empty slides', () {
      final result = builder.buildSlides([], const DeckTheme());
      expect(result, isEmpty);
    });

    test('backward compatibility — no templates, applies deck styles', () {
      final baseStyle = SlideStyle();
      final theme = DeckTheme(baseStyle: baseStyle);
      final slides = [const Slide(key: 'slide-1')];

      final configs = builder.buildSlides(slides, theme);

      expect(configs.length, 1);
      expect(configs[0].style, defaultSlideStyle.merge(baseStyle).merge(null));
      expect(configs[0].frame, theme.frame);
    });

    test('slide with named style resolves from deck styles', () {
      final namedStyle = SlideStyle();
      final theme = DeckTheme(styles: {'dark': namedStyle});
      final slides = [
        const Slide(
          key: 'styled',
          options: SlideOptions(style: 'dark'),
        ),
      ];

      final configs = builder.buildSlides(slides, theme);

      expect(configs[0].style, defaultSlideStyle.merge(null).merge(namedStyle));
    });

    test('slide with template uses template frame and style', () {
      final templateBase = SlideStyle();
      final templateFrame = SlideFrame();
      final template = SlideTemplate(
        baseStyle: templateBase,
        frame: templateFrame,
      );
      final theme = DeckTheme(templates: {'corporate': template});
      final slides = [
        const Slide(
          key: 'tmpl-slide',
          options: SlideOptions(template: 'corporate'),
        ),
      ];

      final configs = builder.buildSlides(slides, theme);

      expect(
        configs[0].style,
        defaultSlideStyle.merge(templateBase).merge(null),
      );
      expect(configs[0].frame, templateFrame);
    });

    test('slide with template + style uses template style variants', () {
      final variant = SlideStyle();
      final template = SlideTemplate(styles: {'highlight': variant});
      final theme = DeckTheme(templates: {'t': template});
      final slides = [
        const Slide(
          key: 'variant-slide',
          options: SlideOptions(template: 't', style: 'highlight'),
        ),
      ];

      final configs = builder.buildSlides(slides, theme);

      expect(configs[0].style, defaultSlideStyle.merge(null).merge(variant));
    });

    test('defaultTemplate applies to slides without explicit template', () {
      final defaultTemplate = SlideTemplate(baseStyle: SlideStyle());
      final theme = DeckTheme(defaultTemplate: defaultTemplate);
      final slides = [const Slide(key: 'default-tmpl')];

      final configs = builder.buildSlides(slides, theme);

      expect(configs[0].frame, defaultTemplate.frame);
    });

    test('template: "none" opts out of defaultTemplate', () {
      final defaultTemplate = SlideTemplate(baseStyle: SlideStyle());
      final deckBase = SlideStyle();
      final theme = DeckTheme(
        defaultTemplate: defaultTemplate,
        baseStyle: deckBase,
      );
      final slides = [
        const Slide(
          key: 'no-tmpl',
          options: SlideOptions(template: 'none'),
        ),
      ];

      final configs = builder.buildSlides(slides, theme);

      expect(configs[0].frame, theme.frame);
      expect(configs[0].style, defaultSlideStyle.merge(deckBase).merge(null));
    });

    test('unknown template throws TemplateException', () {
      final theme = DeckTheme(
        templates: {'real': SlideTemplate()},
      );
      final slides = [
        const Slide(
          key: 'bad',
          options: SlideOptions(template: 'fake'),
        ),
      ];

      expect(
        () => builder.buildSlides(slides, theme),
        throwsA(isA<TemplateException>()),
      );
    });

    test('mixed slides — some with template, some without', () {
      final template = SlideTemplate(baseStyle: SlideStyle());
      final deckBase = SlideStyle();
      final theme = DeckTheme(
        baseStyle: deckBase,
        templates: {'t': template},
      );
      final slides = [
        const Slide(key: 'plain'),
        const Slide(
          key: 'templated',
          options: SlideOptions(template: 't'),
        ),
      ];

      final configs = builder.buildSlides(slides, theme);

      expect(configs[0].frame, theme.frame);
      expect(configs[1].frame, template.frame);
    });

    test('slideIndex is correctly assigned', () {
      const theme = DeckTheme();
      final slides = [
        const Slide(key: 'a'),
        const Slide(key: 'b'),
        const Slide(key: 'c'),
      ];

      final configs = builder.buildSlides(slides, theme);

      expect(configs[0].slideIndex, 0);
      expect(configs[1].slideIndex, 1);
      expect(configs[2].slideIndex, 2);
    });

    test('thumbnailFile stores generated asset key only', () {
      const theme = DeckTheme();
      final slides = [const Slide(key: 'cover')];

      final configs = builder.buildSlides(slides, theme);

      expect(
        configs.first.thumbnailFile,
        allOf(startsWith('thumbnail_cover_'), endsWith('.png')),
      );
    });
  });
}
