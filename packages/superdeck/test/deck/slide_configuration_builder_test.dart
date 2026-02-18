import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/slide_configuration_builder.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  final config = DeckConfiguration();
  final builder = SlideConfigurationBuilder(configuration: config);

  group('SlideConfigurationBuilder', () {
    test('returns empty list for empty slides', () {
      final result = builder.buildConfigurations([], const DeckOptions());
      expect(result, isEmpty);
    });

    test('backward compatibility — no templates, applies deck styles', () {
      final baseStyle = SlideStyle();
      final options = DeckOptions(baseStyle: baseStyle);
      final slides = [const Slide(key: 'slide-1')];

      final configs = builder.buildConfigurations(slides, options);

      expect(configs.length, 1);
      expect(configs[0].style, defaultSlideStyle.merge(baseStyle).merge(null));
      expect(configs[0].parts, options.parts);
    });

    test('slide with named style resolves from deck styles', () {
      final namedStyle = SlideStyle();
      final options = DeckOptions(styles: {'dark': namedStyle});
      final slides = [
        const Slide(
          key: 'styled',
          options: SlideOptions(style: 'dark'),
        ),
      ];

      final configs = builder.buildConfigurations(slides, options);

      expect(configs[0].style, defaultSlideStyle.merge(null).merge(namedStyle));
    });

    test('slide with template uses template parts and style', () {
      final templateBase = SlideStyle();
      final templateParts = SlideParts();
      final template = SlideTemplate(
        baseStyle: templateBase,
        parts: templateParts,
      );
      final options = DeckOptions(templates: {'corporate': template});
      final slides = [
        const Slide(
          key: 'tmpl-slide',
          options: SlideOptions(template: 'corporate'),
        ),
      ];

      final configs = builder.buildConfigurations(slides, options);

      expect(configs[0].style, defaultSlideStyle.merge(templateBase).merge(null));
      expect(configs[0].parts, templateParts);
    });

    test('slide with template + style uses template style variants', () {
      final variant = SlideStyle();
      final template = SlideTemplate(styles: {'highlight': variant});
      final options = DeckOptions(templates: {'t': template});
      final slides = [
        const Slide(
          key: 'variant-slide',
          options: SlideOptions(template: 't', style: 'highlight'),
        ),
      ];

      final configs = builder.buildConfigurations(slides, options);

      expect(configs[0].style, defaultSlideStyle.merge(null).merge(variant));
    });

    test('defaultTemplate applies to slides without explicit template', () {
      final defaultTemplate = SlideTemplate(baseStyle: SlideStyle());
      final options = DeckOptions(defaultTemplate: defaultTemplate);
      final slides = [const Slide(key: 'default-tmpl')];

      final configs = builder.buildConfigurations(slides, options);

      expect(configs[0].parts, defaultTemplate.parts);
    });

    test('template: "none" opts out of defaultTemplate', () {
      final defaultTemplate = SlideTemplate(baseStyle: SlideStyle());
      final deckBase = SlideStyle();
      final options = DeckOptions(
        defaultTemplate: defaultTemplate,
        baseStyle: deckBase,
      );
      final slides = [
        const Slide(
          key: 'no-tmpl',
          options: SlideOptions(template: 'none'),
        ),
      ];

      final configs = builder.buildConfigurations(slides, options);

      expect(configs[0].parts, options.parts);
      expect(configs[0].style, defaultSlideStyle.merge(deckBase).merge(null));
    });

    test('unknown template throws TemplateException', () {
      final options = DeckOptions(templates: {'real': SlideTemplate()});
      final slides = [
        const Slide(
          key: 'bad',
          options: SlideOptions(template: 'fake'),
        ),
      ];

      expect(
        () => builder.buildConfigurations(slides, options),
        throwsA(isA<TemplateException>()),
      );
    });

    test('mixed slides — some with template, some without', () {
      final template = SlideTemplate(baseStyle: SlideStyle());
      final deckBase = SlideStyle();
      final options = DeckOptions(
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

      final configs = builder.buildConfigurations(slides, options);

      expect(configs[0].parts, options.parts);
      expect(configs[1].parts, template.parts);
    });

    test('slideIndex is correctly assigned', () {
      final options = DeckOptions();
      final slides = [
        const Slide(key: 'a'),
        const Slide(key: 'b'),
        const Slide(key: 'c'),
      ];

      final configs = builder.buildConfigurations(slides, options);

      expect(configs[0].slideIndex, 0);
      expect(configs[1].slideIndex, 1);
      expect(configs[2].slideIndex, 2);
    });
  });
}
