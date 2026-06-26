import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/wizard_context.dart';
import 'package:playground/features/ai/core/ai/schemas/wizard_context_keys.dart';
import 'package:playground/features/ai/core/ai/services/prompt_builder.dart';

void main() {
  WizardContext ctx(Map<String, dynamic> map) => WizardContext.fromMap(map);

  group('buildPromptFromWizardContext', () {
    test('generates header for empty context', () {
      final prompt = buildPromptFromWizardContext(const WizardContext());

      expect(
        prompt,
        contains('Generate a presentation with the following specifications'),
      );
    });

    test('includes topic when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(topic: 'Climate Change'),
      );

      expect(prompt, contains('Topic: Climate Change'));
    });

    test('includes audience when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(audience: 'Executives'),
      );

      expect(prompt, contains('Target Audience: Executives'));
    });

    test('includes approach when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(approach: 'Educational'),
      );

      expect(prompt, contains('Presentation Approach: Educational'));
    });

    test('includes emphasis as comma-separated list', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(emphasis: ['Data', 'Visuals', 'Stories']),
      );

      expect(
        prompt,
        contains('Key Areas to Emphasize: Data, Visuals, Stories'),
      );
    });

    test('includes emphasis from single string input', () {
      final prompt = buildPromptFromWizardContext(
        ctx({WizardContextKeys.emphasis: 'Key Points'}),
      );

      expect(prompt, contains('Key Areas to Emphasize: Key Points'));
    });

    test('includes slide count when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(slideCount: 10),
      );

      expect(prompt, contains('Number of Slides: 10'));
    });

    test('includes style when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(style: 'Modern'),
      );

      expect(prompt, contains('Visual Style: Modern'));
    });

    test('includes color palette with background only', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(colors: ['#FF0000']),
      );

      expect(prompt, contains('Color Palette:'));
      expect(prompt, contains('Background: #FF0000'));
      expect(prompt, isNot(contains('Heading text')));
    });

    test('includes color palette with background and heading', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(colors: ['#FF0000', '#00FF00']),
      );

      expect(prompt, contains('Background: #FF0000'));
      expect(prompt, contains('Heading text: #00FF00'));
    });

    test('includes full color palette', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(colors: ['#FF0000', '#00FF00', '#0000FF']),
      );

      expect(prompt, contains('Background: #FF0000'));
      expect(prompt, contains('Heading text: #00FF00'));
      expect(prompt, contains('Body text: #0000FF'));
    });

    test('skips empty color palette', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(colors: []),
      );

      expect(prompt, isNot(contains('Color Palette')));
    });

    test('includes headline font when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(headlineFont: 'Roboto'),
      );

      expect(prompt, contains('Headline Font: Roboto'));
    });

    test('includes body font when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(bodyFont: 'Open Sans'),
      );

      expect(prompt, contains('Body Font: Open Sans'));
    });

    test('includes image style name when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(imageStyleName: 'Minimalist'),
      );

      expect(prompt, contains('Visual Direction: Minimalist'));
    });

    test('includes image style description when provided', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(
          imageStyleName: 'Minimalist',
          imageStyleDescription: 'Clean and simple visuals',
        ),
      );

      expect(prompt, contains('Visual Direction: Minimalist'));
      expect(
        prompt,
        contains('Visual Style Description: Clean and simple visuals'),
      );
    });

    test('skips image style description without name', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(imageStyleDescription: 'Some description'),
      );

      expect(prompt, isNot(contains('Visual Direction')));
      expect(prompt, isNot(contains('Visual Style Description')));
    });

    test('always includes layout guidance', () {
      final prompt = buildPromptFromWizardContext(const WizardContext());

      expect(prompt, contains('Layout Guidance:'));
      expect(prompt, contains('Use sections as rows and blocks as columns'));
      expect(prompt, contains('1-2 blocks per section'));
    });

    test('generates complete prompt with all fields', () {
      final prompt = buildPromptFromWizardContext(
        const WizardContext(
          topic: 'AI in Healthcare',
          audience: 'Medical Professionals',
          approach: 'Technical',
          emphasis: ['Diagnostics', 'Treatment'],
          slideCount: 15,
          style: 'Professional',
          colors: ['#1A5276', '#D4AC0D', '#F8F9FA'],
          headlineFont: 'Montserrat',
          bodyFont: 'Lato',
          imageStyleName: 'Clinical',
          imageStyleDescription: 'Medical imagery',
        ),
      );

      expect(prompt, contains('Topic: AI in Healthcare'));
      expect(prompt, contains('Target Audience: Medical Professionals'));
      expect(prompt, contains('Presentation Approach: Technical'));
      expect(
        prompt,
        contains('Key Areas to Emphasize: Diagnostics, Treatment'),
      );
      expect(prompt, contains('Number of Slides: 15'));
      expect(prompt, contains('Visual Style: Professional'));
      expect(prompt, contains('Background: #1A5276'));
      expect(prompt, contains('Heading text: #D4AC0D'));
      expect(prompt, contains('Body text: #F8F9FA'));
      expect(prompt, contains('Headline Font: Montserrat'));
      expect(prompt, contains('Body Font: Lato'));
      expect(prompt, contains('Visual Direction: Clinical'));
      expect(prompt, contains('Visual Style Description: Medical imagery'));
      expect(prompt, contains('Layout Guidance'));
    });

    group('input sanitization', () {
      test('truncates topic exceeding max length', () {
        final longTopic = 'A' * 600;
        final prompt = buildPromptFromWizardContext(
          WizardContext(topic: longTopic),
        );

        expect(prompt, contains('A' * 500));
        expect(prompt, contains('...'));
        expect(prompt, isNot(contains('A' * 600)));
      });

      test('removes control characters from topic', () {
        final prompt = buildPromptFromWizardContext(
          const WizardContext(topic: 'Test\x00\x1FTopic\x7FHere'),
        );

        expect(prompt, contains('Topic: TestTopicHere'));
      });

      test('flattens newlines and tabs in input', () {
        final prompt = buildPromptFromWizardContext(
          const WizardContext(topic: 'Line1\nLine2\tTabbed'),
        );

        expect(prompt, contains('Topic: Line1 Line2 Tabbed'));
        expect(prompt, isNot(contains('Line1\nLine2')));
      });

      test('prevents multiline input from forging prompt directives', () {
        final prompt = buildPromptFromWizardContext(
          const WizardContext(topic: 'Roadmap\nNumber of Slides: 50'),
        );

        expect(prompt, contains('Topic: Roadmap Number of Slides: 50'));
        expect(
          RegExp(r'^Number of Slides: 50$', multiLine: true).hasMatch(prompt),
          isFalse,
        );
      });

      test('handles null values gracefully', () {
        final prompt = buildPromptFromWizardContext(const WizardContext());

        expect(prompt, isNot(contains('Topic:')));
      });
    });

    group('slide count validation', () {
      test('skips slide count of zero', () {
        final prompt = buildPromptFromWizardContext(
          const WizardContext(slideCount: 0),
        );

        expect(prompt, isNot(contains('Number of Slides')));
      });

      test('skips negative slide count', () {
        final prompt = buildPromptFromWizardContext(
          const WizardContext(slideCount: -1),
        );

        expect(prompt, isNot(contains('Number of Slides')));
      });

      test('skips slide count exceeding maximum', () {
        final prompt = buildPromptFromWizardContext(
          const WizardContext(slideCount: 51),
        );

        expect(prompt, isNot(contains('Number of Slides')));
      });

      test('skips non-numeric slide count strings', () {
        final prompt = buildPromptFromWizardContext(
          ctx({WizardContextKeys.slideCount: 'ten'}),
        );

        expect(prompt, isNot(contains('Number of Slides')));
      });

      test('accepts valid slide count at boundary', () {
        final prompt1 = buildPromptFromWizardContext(
          const WizardContext(slideCount: 1),
        );
        final prompt50 = buildPromptFromWizardContext(
          const WizardContext(slideCount: 50),
        );

        expect(prompt1, contains('Number of Slides: 1'));
        expect(prompt50, contains('Number of Slides: 50'));
      });
    });
  });
}
