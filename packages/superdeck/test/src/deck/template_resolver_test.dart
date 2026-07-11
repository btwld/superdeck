import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/src/deck/template_resolver.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('TemplateResolver', () {
    group('No template', () {
      test(
        'no template, no style — returns defaultSlideStyle merged with options.baseStyle',
        () {
          final baseStyle = SlideStyle();
          final options = DeckOptions(baseStyle: baseStyle);
          final resolver = TemplateResolver(options);

          final result = resolver.resolve(null);

          expect(result.usingTemplate, isFalse);
          expect(result.parts, options.parts);
          expect(result.style, defaultSlideStyle.merge(baseStyle).merge(null));
        },
      );

      test(
        'no template, no style, null slideOptions — returns defaultSlideStyle merged with baseStyle',
        () {
          final options = DeckOptions();
          final resolver = TemplateResolver(options);

          final result = resolver.resolve(null);

          expect(result.usingTemplate, isFalse);
          expect(result.style, defaultSlideStyle.merge(null).merge(null));
          expect(result.parts, options.parts);
        },
      );

      test(
        'no template, with style — resolves style from options.styles map',
        () {
          final namedStyle = SlideStyle();
          final options = DeckOptions(styles: {'dark': namedStyle});
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(style: 'dark');

          final result = resolver.resolve(slideOptions);

          expect(result.usingTemplate, isFalse);
          expect(result.style, defaultSlideStyle.merge(null).merge(namedStyle));
        },
      );

      test(
        'merge order is defaultSlideStyle -> baseStyle -> named style (last wins)',
        () {
          // Concrete last-wins check: named style overrides baseStyle fields.
          final baseStyle = SlideStyle(
            strong: const TextStyle(color: Color(0xFFFF0000)),
            link: const TextStyle(color: Color(0xFF00FF00)),
          );
          final namedStyle = SlideStyle(
            strong: const TextStyle(color: Color(0xFF0000FF)),
          );
          final options = DeckOptions(
            baseStyle: baseStyle,
            styles: {'accent': namedStyle},
          );
          final resolver = TemplateResolver(options);

          final result = resolver.resolve(SlideOptions(style: 'accent'));

          final expected = defaultSlideStyle
              .merge(baseStyle)
              .merge(namedStyle);
          expect(result.style, expected);
          // Named strong replaces base strong; link from base remains.
          expect(result.style, isNot(defaultSlideStyle.merge(baseStyle)));
          expect(result.style, isNot(defaultSlideStyle.merge(namedStyle)));
        },
      );

      test('no template, unknown style — throws ArgumentError', () {
        final options = DeckOptions(styles: {'light': SlideStyle()});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(style: 'nonexistent');

        expect(
          () => resolver.resolve(slideOptions),
          throwsA(isA<ArgumentError>()),
        );
      });

      test(
        'no template, unknown style — exception message includes "in deck" and style name',
        () {
          final options = DeckOptions(
            styles: {'light': SlideStyle(), 'dark': SlideStyle()},
          );
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(style: 'missing');

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<ArgumentError>().having(
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
      test('valid template — uses template baseStyle and parts', () {
        final templateBaseStyle = SlideStyle();
        final template = SlideTemplate(baseStyle: templateBaseStyle);
        final options = DeckOptions(templates: {'hero': template});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 'hero');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(result.parts, template.parts);
        expect(
          result.style,
          defaultSlideStyle.merge(templateBaseStyle).merge(null),
        );
      });

      test('template with no baseStyle — uses defaultSlideStyle only', () {
        final template = SlideTemplate();
        final options = DeckOptions(templates: {'blank': template});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 'blank');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(result.style, defaultSlideStyle.merge(null).merge(null));
      });

      test('template + style — uses template styles map', () {
        final templateStyle = SlideStyle();
        final template = SlideTemplate(styles: {'accent': templateStyle});
        final options = DeckOptions(templates: {'branded': template});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 'branded', style: 'accent');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(
          result.style,
          defaultSlideStyle.merge(null).merge(templateStyle),
        );
      });

      test('template, unknown style — throws ArgumentError', () {
        final template = SlideTemplate(styles: {'known': SlideStyle()});
        final options = DeckOptions(templates: {'myTemplate': template});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(
          template: 'myTemplate',
          style: 'unknown',
        );

        expect(
          () => resolver.resolve(slideOptions),
          throwsA(isA<ArgumentError>()),
        );
      });

      test(
        'template, unknown style — exception message includes template name and style name',
        () {
          final template = SlideTemplate(styles: {'valid': SlideStyle()});
          final options = DeckOptions(templates: {'corporate': template});
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(
            template: 'corporate',
            style: 'bogus',
          );

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                allOf(contains('bogus'), contains('corporate')),
              ),
            ),
          );
        },
      );

      test('unknown template name — throws ArgumentError', () {
        final options = DeckOptions(templates: {'existing': SlideTemplate()});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 'doesNotExist');

        expect(
          () => resolver.resolve(slideOptions),
          throwsA(isA<ArgumentError>()),
        );
      });

      test(
        'unknown template name — exception message references the unknown template name',
        () {
          final options = DeckOptions(templates: {'real': SlideTemplate()});
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(template: 'phantom');

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<ArgumentError>().having(
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
          final options = DeckOptions();
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(template: 'phantom');

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<ArgumentError>().having(
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
        final options = DeckOptions(defaultTemplate: defaultTemplate);
        final resolver = TemplateResolver(options);

        final result = resolver.resolve(null);

        expect(result.usingTemplate, isTrue);
        expect(result.parts, defaultTemplate.parts);
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

        final options = DeckOptions(
          defaultTemplate: defaultTemplate,
          templates: {'explicit': explicitTemplate},
        );
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 'explicit');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(result.parts, explicitTemplate.parts);
        expect(
          result.style,
          defaultSlideStyle.merge(explicitTemplateStyle).merge(null),
        );
      });

      test('slide with no template field uses defaultTemplate when set', () {
        final defaultTemplate = SlideTemplate();
        final options = DeckOptions(defaultTemplate: defaultTemplate);
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(title: 'No template');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
        expect(result.parts, defaultTemplate.parts);
      });

      test('template: "none" opts out of defaultTemplate', () {
        final defaultTemplate = SlideTemplate(baseStyle: SlideStyle());
        final baseStyle = SlideStyle();
        final options = DeckOptions(
          defaultTemplate: defaultTemplate,
          baseStyle: baseStyle,
        );
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 'none');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isFalse);
        expect(result.parts, options.parts);
        expect(result.style, defaultSlideStyle.merge(baseStyle).merge(null));
      });

      test('template: "none" uses deck-level styles, not template styles', () {
        final deckStyle = SlideStyle();
        final templateStyle = SlideStyle();
        final options = DeckOptions(
          defaultTemplate: SlideTemplate(baseStyle: templateStyle),
          styles: {'accent': deckStyle},
        );
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 'none', style: 'accent');

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
          final options = DeckOptions(defaultTemplate: defaultTemplate);
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(style: 'unknown');

          expect(
            () => resolver.resolve(slideOptions),
            throwsA(
              isA<ArgumentError>().having(
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
            DeckOptions(
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
          final options = DeckOptions(
            baseStyle: baseStyle,
            styles: {'variant': namedStyle},
          );
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(style: 'variant');

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
          final options = DeckOptions(templates: {'themed': template});
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(
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
          final options = DeckOptions(templates: {'simple': template});
          final resolver = TemplateResolver(options);
          final slideOptions = SlideOptions(template: 'simple');

          final result = resolver.resolve(slideOptions);

          final expected = defaultSlideStyle.merge(templateBase).merge(null);

          expect(result.style, expected);
        },
      );

      test('options.baseStyle is not applied when a named template is used', () {
        final optionsBaseStyle = SlideStyle();
        final templateBase = SlideStyle();
        final template = SlideTemplate(baseStyle: templateBase);
        final options = DeckOptions(
          baseStyle: optionsBaseStyle,
          templates: {'t': template},
        );
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 't');

        final result = resolver.resolve(slideOptions);

        // Template path: usingTemplate=true, parts from template (not options)
        expect(result.usingTemplate, isTrue);
        expect(result.parts, template.parts);

        // Without template: options.parts would be used
        final noTemplateResult = TemplateResolver(
          DeckOptions(baseStyle: optionsBaseStyle),
        ).resolve(null);
        expect(noTemplateResult.usingTemplate, isFalse);
        expect(noTemplateResult.parts, options.parts);
      });
    });

    group('usingTemplate flag', () {
      test('is false when no template and no defaultTemplate', () {
        final options = DeckOptions();
        final resolver = TemplateResolver(options);

        final result = resolver.resolve(null);

        expect(result.usingTemplate, isFalse);
      });

      test('is true when explicit template is resolved', () {
        final options = DeckOptions(templates: {'t': SlideTemplate()});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 't');

        final result = resolver.resolve(slideOptions);

        expect(result.usingTemplate, isTrue);
      });

      test('is true when defaultTemplate is used', () {
        final options = DeckOptions(defaultTemplate: SlideTemplate());
        final resolver = TemplateResolver(options);

        final result = resolver.resolve(null);

        expect(result.usingTemplate, isTrue);
      });
    });

    group('Parts resolution', () {
      test('returns options.parts when no template is used', () {
        final options = DeckOptions();
        final resolver = TemplateResolver(options);

        final result = resolver.resolve(null);

        expect(result.parts, options.parts);
      });

      test('returns template.parts when template is used', () {
        final template = SlideTemplate();
        final options = DeckOptions(templates: {'t': template});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 't');

        final result = resolver.resolve(slideOptions);

        expect(result.parts, template.parts);
      });

      test('template.parts differs from options.parts', () {
        final template = SlideTemplate();
        final options = DeckOptions(templates: {'t': template});
        final resolver = TemplateResolver(options);
        final slideOptions = SlideOptions(template: 't');

        final withTemplate = resolver.resolve(slideOptions);
        final withoutTemplate = resolver.resolve(null);

        // When using a template, parts come from the template, not options
        expect(withTemplate.parts, template.parts);
        expect(withoutTemplate.parts, options.parts);
      });
    });

    group('Fullscreen layout', () {
      void expectFullscreenChrome(
        TemplateResolutionResult result, {
        required Widget background,
        required bool usingTemplate,
      }) {
        expect(result.usingTemplate, usingTemplate);
        expect(result.parts.header, isNull);
        expect(result.parts.footer, isNull);
        expect(result.parts.background, same(background));
      }

      test('layout normal behaves like omitted layout', () {
        final baseStyle = SlideStyle();
        final options = DeckOptions(baseStyle: baseStyle);
        final resolver = TemplateResolver(options);

        final omitted = resolver.resolve(null);
        final normal = resolver.resolve(
          SlideOptions(layout: SlideLayout.normal),
        );

        expect(normal.usingTemplate, omitted.usingTemplate);
        expect(normal.parts, same(omitted.parts));
        expect(normal.style, omitted.style);
      });

      test(
        'suppresses deck-level header and footer while preserving background',
        () {
          const background = ColoredBox(color: Color(0xFF123456));
          final options = DeckOptions(
            parts: const SlideParts(background: background),
          );
          final resolver = TemplateResolver(options);

          expectFullscreenChrome(
            resolver.resolve(SlideOptions(layout: SlideLayout.fullscreen)),
            background: background,
            usingTemplate: false,
          );
        },
      );

      test(
        'suppresses template header and footer while preserving background',
        () {
          const background = ColoredBox(color: Color(0xFF654321));
          final template = SlideTemplate(
            parts: const SlideParts(background: background),
          );
          final options = DeckOptions(templates: {'cover': template});
          final resolver = TemplateResolver(options);

          expectFullscreenChrome(
            resolver.resolve(
              SlideOptions(template: 'cover', layout: SlideLayout.fullscreen),
            ),
            background: background,
            usingTemplate: true,
          );
        },
      );

      test(
        'suppresses defaultTemplate header and footer while preserving background',
        () {
          const background = ColoredBox(color: Color(0xFF112233));
          final options = DeckOptions(
            defaultTemplate: SlideTemplate(
              parts: const SlideParts(background: background),
            ),
          );
          final resolver = TemplateResolver(options);

          expectFullscreenChrome(
            resolver.resolve(SlideOptions(layout: SlideLayout.fullscreen)),
            background: background,
            usingTemplate: true,
          );
        },
      );

      test(
        'template: none remains deck-level with fullscreen chrome removal',
        () {
          const background = ColoredBox(color: Color(0xFFABCDEF));
          final options = DeckOptions(
            defaultTemplate: SlideTemplate(),
            parts: const SlideParts(background: background),
          );
          final resolver = TemplateResolver(options);

          expectFullscreenChrome(
            resolver.resolve(
              SlideOptions(template: 'none', layout: SlideLayout.fullscreen),
            ),
            background: background,
            usingTemplate: false,
          );
        },
      );

      test('preserves resolved style without layout-specific overrides', () {
        final baseStyle = SlideStyle(
          blockContainer: BlockStyler(
            padding: EdgeInsetsGeometryMix.all(32),
            margin: EdgeInsetsGeometryMix.all(16),
          ),
        );
        final options = DeckOptions(baseStyle: baseStyle);
        final resolver = TemplateResolver(options);

        final normal = resolver.resolve(null);
        final fullscreen = resolver.resolve(
          SlideOptions(layout: SlideLayout.fullscreen),
        );

        expect(fullscreen.style, normal.style);
      });
    });
  });
}
