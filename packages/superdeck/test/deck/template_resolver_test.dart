import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/presentation/template_resolver.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  group('TemplateResolver', () {
    group('No template', () {
      test(
        'no template, no style — returns defaultSlideStyle merged with options.baseStyle',
        () {
          final baseStyle = SlideStyle();
          final options = DeckTheme(baseStyle: baseStyle);
          final resolver = TemplateResolver(options);

          final result = resolver.resolve(null);

          expect(result.usingTemplate, isFalse);
          expect(result.frame, options.frame);
          expect(result.style, defaultSlideStyle.merge(baseStyle).merge(null));
        },
      );

      test(
        'no template, no style, null slideOptions — returns defaultSlideStyle merged with baseStyle',
        () {
          final options = DeckTheme();
          final resolver = TemplateResolver(options);

          final result = resolver.resolve(null);

          expect(result.usingTemplate, isFalse);
          expect(result.style, defaultSlideStyle.merge(null).merge(null));
          expect(result.frame, options.frame);
        },
      );

      test(
        'no template, with style — resolves style from options.styles map',
        () {
          final namedStyle = SlideStyle();
          final options = DeckTheme(styles: {'dark': namedStyle});
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(style: 'dark');

          final result = resolver.resolve(slideOptions);

          expect(result.usingTemplate, isFalse);
          expect(result.style, defaultSlideStyle.merge(null).merge(namedStyle));
        },
      );

      test('no template, unknown style — throws TemplateException', () {
        final options = DeckTheme(styles: {'light': SlideStyle()});
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(style: 'nonexistent');

        expect(
          () => resolver.resolve(slideOptions),
          throwsA(isA<TemplateException>()),
        );
      });

      test(
        'no template, unknown style — exception message includes "in deck" and style name',
        () {
          final options = DeckTheme(
            styles: {'light': SlideStyle(), 'dark': SlideStyle()},
          );
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(style: 'missing');

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<TemplateException>().having(
                (e) => e.message,
                'message',
                allOf(contains('missing'), contains('in deck')),
              ),
            ),
          );
        },
      );
    });

    group('With template', () {
      test('valid template — uses template baseStyle and frame', () {
        final templateBaseStyle = SlideStyle();
        final template = SlideTemplate(baseStyle: templateBaseStyle);
        final options = DeckTheme(templates: {'hero': template});
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 'hero');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(result.frame, template.frame);
        expect(
          result.style,
          defaultSlideStyle.merge(templateBaseStyle).merge(null),
        );
      });

      test('template with no baseStyle — uses defaultSlideStyle only', () {
        final template = SlideTemplate();
        final options = DeckTheme(templates: {'blank': template});
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 'blank');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(result.style, defaultSlideStyle.merge(null).merge(null));
      });

      test('template + style — uses template styles map', () {
        final templateStyle = SlideStyle();
        final template = SlideTemplate(styles: {'accent': templateStyle});
        final options = DeckTheme(templates: {'branded': template});
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 'branded', style: 'accent');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(
          result.style,
          defaultSlideStyle.merge(null).merge(templateStyle),
        );
      });

      test('template, unknown style — throws TemplateException', () {
        final template = SlideTemplate(styles: {'known': SlideStyle()});
        final options = DeckTheme(templates: {'myTemplate': template});
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(
          template: 'myTemplate',
          style: 'unknown',
        );

        expect(
          () => resolver.resolve(slideOptions),
          throwsA(isA<TemplateException>()),
        );
      });

      test(
        'template, unknown style — exception message includes template name and style name',
        () {
          final template = SlideTemplate(styles: {'valid': SlideStyle()});
          final options = DeckTheme(templates: {'corporate': template});
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(
            template: 'corporate',
            style: 'bogus',
          );

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<TemplateException>().having(
                (e) => e.message,
                'message',
                allOf(contains('bogus'), contains('corporate')),
              ),
            ),
          );
        },
      );

      test('unknown template name — throws TemplateException', () {
        final options = DeckTheme(
          templates: {'existing': SlideTemplate()},
        );
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 'doesNotExist');

        expect(
          () => resolver.resolve(slideOptions),
          throwsA(isA<TemplateException>()),
        );
      });

      test(
        'unknown template name — exception message references the unknown template name',
        () {
          final options = DeckTheme(
            templates: {'real': SlideTemplate()},
          );
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(template: 'phantom');

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<TemplateException>().having(
                (e) => e.message,
                'message',
                contains('phantom'),
              ),
            ),
          );
        },
      );

      test(
        'unknown template name — no registered templates message is explicit',
        () {
          final options = DeckTheme();
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(template: 'phantom');

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<TemplateException>().having(
                (e) => e.message,
                'message',
                allOf(
                  contains('phantom'),
                  contains('No templates are registered in this deck.'),
                ),
              ),
            ),
          );
        },
      );
    });

    group('defaultTemplate', () {
      test('defaultTemplate used when slide has no explicit template', () {
        final templateBaseStyle = SlideStyle();
        final defaultTemplate = SlideTemplate(baseStyle: templateBaseStyle);
        final options = DeckTheme(defaultTemplate: defaultTemplate);
        final resolver = TemplateResolver(options);

        final result = resolver.resolve(null);

        expect(result.usingTemplate, isTrue);
        expect(result.frame, defaultTemplate.frame);
        expect(
          result.style,
          defaultSlideStyle.merge(templateBaseStyle).merge(null),
        );
      });

      test('explicit template overrides defaultTemplate', () {
        final defaultTemplateStyle = SlideStyle();
        final explicitTemplateStyle = SlideStyle();

        final defaultTemplate = SlideTemplate(baseStyle: defaultTemplateStyle);
        final explicitTemplate = SlideTemplate(
          baseStyle: explicitTemplateStyle,
        );

        final options = DeckTheme(
          defaultTemplate: defaultTemplate,
          templates: {'explicit': explicitTemplate},
        );
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 'explicit');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(result.frame, explicitTemplate.frame);
        expect(
          result.style,
          defaultSlideStyle.merge(explicitTemplateStyle).merge(null),
        );
      });

      test('slide with no template field uses defaultTemplate when set', () {
        final defaultTemplate = SlideTemplate();
        final options = DeckTheme(defaultTemplate: defaultTemplate);
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(title: 'No template');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(result.frame, defaultTemplate.frame);
      });

      test('template: "none" opts out of defaultTemplate', () {
        final defaultTemplate = SlideTemplate(baseStyle: SlideStyle());
        final baseStyle = SlideStyle();
        final options = DeckTheme(
          defaultTemplate: defaultTemplate,
          baseStyle: baseStyle,
        );
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 'none');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isFalse);
        expect(result.frame, options.frame);
        expect(result.style, defaultSlideStyle.merge(baseStyle).merge(null));
      });

      test('template: "none" uses deck-level styles, not template styles', () {
        final deckStyle = SlideStyle();
        final templateStyle = SlideStyle();
        final options = DeckTheme(
          defaultTemplate: SlideTemplate(baseStyle: templateStyle),
          styles: {'accent': deckStyle},
        );
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 'none', style: 'accent');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isFalse);
        expect(result.style, defaultSlideStyle.merge(null).merge(deckStyle));
      });

      test(
        'defaultTemplate unknown style message identifies defaultTemplate',
        () {
          final defaultTemplate = SlideTemplate(
            styles: {'known': SlideStyle()},
          );
          final options = DeckTheme(defaultTemplate: defaultTemplate);
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(style: 'unknown');

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<TemplateException>().having(
                (e) => e.message,
                'message',
                allOf(contains('defaultTemplate'), contains('unknown')),
              ),
            ),
          );
        },
      );
    });

    group('Reserved template name', () {
      test('throws when deck registers reserved "none" template name', () {
        expect(
          () => TemplateResolver(
            DeckTheme(
              templates: {TemplateResolver.noneTemplate: SlideTemplate()},
            ),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Style merge order', () {
      test(
        'without template: defaultSlideStyle → options.baseStyle → options.styles[style]',
        () {
          final baseStyle = SlideStyle();
          final namedStyle = SlideStyle();
          final options = DeckTheme(
            baseStyle: baseStyle,
            styles: {'variant': namedStyle},
          );
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(style: 'variant');

          final result = resolver.resolve(slideOptions);

          final expected = defaultSlideStyle.merge(baseStyle).merge(namedStyle);

          expect(result.style, expected);
        },
      );

      test(
        'with template: defaultSlideStyle → template.baseStyle → template.styles[style]',
        () {
          final templateBase = SlideStyle();
          final templateVariant = SlideStyle();
          final template = SlideTemplate(
            baseStyle: templateBase,
            styles: {'highlight': templateVariant},
          );
          final options = DeckTheme(templates: {'themed': template});
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(
            template: 'themed',
            style: 'highlight',
          );

          final result = resolver.resolve(slideOptions);

          final expected = defaultSlideStyle
              .merge(templateBase)
              .merge(templateVariant);

          expect(result.style, expected);
        },
      );

      test(
        'with template and no style variant: defaultSlideStyle → template.baseStyle',
        () {
          final templateBase = SlideStyle();
          final template = SlideTemplate(baseStyle: templateBase);
          final options = DeckTheme(templates: {'simple': template});
          final resolver = TemplateResolver(options);
          const slideOptions = SlideOptions(template: 'simple');

          final result = resolver.resolve(slideOptions);

          final expected = defaultSlideStyle.merge(templateBase).merge(null);

          expect(result.style, expected);
        },
      );

      test('options.baseStyle is not applied when a named template is used', () {
        final optionsBaseStyle = SlideStyle();
        final templateBase = SlideStyle();
        final template = SlideTemplate(baseStyle: templateBase);
        final options = DeckTheme(
          baseStyle: optionsBaseStyle,
          templates: {'t': template},
        );
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 't');

        final result = resolver.resolve(slideOptions);

        // Template path: usingTemplate=true, frame from template (not options)
        expect(result.usingTemplate, isTrue);
        expect(result.frame, template.frame);

        // Without template: options.frame would be used
        final noTemplateResult = TemplateResolver(
          DeckTheme(baseStyle: optionsBaseStyle),
        ).resolve(null);
        expect(noTemplateResult.usingTemplate, isFalse);
        expect(noTemplateResult.frame, options.frame);
      });
    });

    group('usingTemplate flag', () {
      test('is false when no template and no defaultTemplate', () {
        final options = DeckTheme();
        final resolver = TemplateResolver(options);

        final result = resolver.resolve(null);

        expect(result.usingTemplate, isFalse);
      });

      test('is true when explicit template is resolved', () {
        final options = DeckTheme(templates: {'t': SlideTemplate()});
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 't');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
      });

      test('is true when defaultTemplate is used', () {
        final options = DeckTheme(defaultTemplate: SlideTemplate());
        final resolver = TemplateResolver(options);

        final result = resolver.resolve(null);

        expect(result.usingTemplate, isTrue);
      });
    });

    group('Frame resolution', () {
      test('returns options.frame when no template is used', () {
        final options = DeckTheme();
        final resolver = TemplateResolver(options);

        final result = resolver.resolve(null);

        expect(result.frame, options.frame);
      });

      test('returns template.frame when template is used', () {
        final template = SlideTemplate();
        final options = DeckTheme(templates: {'t': template});
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 't');

        final result = resolver.resolve(slideOptions);

        expect(result.frame, template.frame);
      });

      test('template.frame differs from options.frame', () {
        final template = SlideTemplate();
        final options = DeckTheme(templates: {'t': template});
        final resolver = TemplateResolver(options);
        const slideOptions = SlideOptions(template: 't');

        final withTemplate = resolver.resolve(slideOptions);
        final withoutTemplate = resolver.resolve(null);

        // When using a template, frame comes from the template, not options
        expect(withTemplate.frame, template.frame);
        expect(withoutTemplate.frame, options.frame);
      });
    });
  });
}
