import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_ai/core/ai/prompts/image_style_prompts.dart';

void main() {
  group('ImageStyle', () {
    group('values', () {
      test('has expected number of styles', () {
        expect(ImageStyle.values.length, 6);
      });

      test('contains all expected styles', () {
        expect(
          ImageStyle.values,
          containsAll([
            ImageStyle.watercolor,
            ImageStyle.minimalist,
            ImageStyle.gradient,
            ImageStyle.retro,
            ImageStyle.geometric,
            ImageStyle.flatDesign,
          ]),
        );
      });
    });

    group('properties', () {
      test('each style has non-empty title', () {
        for (final style in ImageStyle.values) {
          expect(
            style.title,
            isNotEmpty,
            reason: 'Style ${style.name} has empty title',
          );
        }
      });

      test('each style has non-empty description', () {
        for (final style in ImageStyle.values) {
          expect(
            style.description,
            isNotEmpty,
            reason: 'Style ${style.name} has empty description',
          );
        }
      });

      test('each style has non-empty treatment', () {
        for (final style in ImageStyle.values) {
          expect(
            style.treatment,
            isNotEmpty,
            reason: 'Style ${style.name} has empty treatment',
          );
        }
      });

      test('id returns enum name', () {
        expect(ImageStyle.watercolor.id, 'watercolor');
        expect(ImageStyle.flatDesign.id, 'flatDesign');
      });
    });

    group('buildPrompt', () {
      test('capitalizes subject', () {
        final result = ImageStyle.watercolor.buildPrompt(
          'runner crossing finish line',
        );

        expect(result, startsWith('Runner'));
      });

      test('includes treatment', () {
        final result = ImageStyle.watercolor.buildPrompt('test subject');

        expect(result, contains(ImageStyle.watercolor.treatment));
      });

      test('combines subject and treatment with comma', () {
        final result = ImageStyle.minimalist.buildPrompt('mountain landscape');

        expect(result, startsWith('Mountain landscape, '));
      });

      test('handles empty subject', () {
        final result = ImageStyle.gradient.buildPrompt('');

        // Should still include treatment
        expect(result, contains(ImageStyle.gradient.treatment));
      });

      test('handles single character subject', () {
        final result = ImageStyle.retro.buildPrompt('a');

        expect(result, startsWith('A, '));
      });

      test('preserves rest of subject after capitalizing first letter', () {
        final result = ImageStyle.geometric.buildPrompt('iPhone on desk');

        expect(result, startsWith('IPhone on desk, '));
      });

      test('each style produces unique prompt for same subject', () {
        const subject = 'abstract art';
        final prompts = ImageStyle.values
            .map((s) => s.buildPrompt(subject))
            .toSet();

        // All prompts should be unique
        expect(prompts.length, ImageStyle.values.length);
      });
    });

    group('fromId', () {
      test('returns style for valid ID', () {
        expect(ImageStyle.fromId('watercolor'), ImageStyle.watercolor);
        expect(ImageStyle.fromId('minimalist'), ImageStyle.minimalist);
        expect(ImageStyle.fromId('gradient'), ImageStyle.gradient);
        expect(ImageStyle.fromId('retro'), ImageStyle.retro);
        expect(ImageStyle.fromId('geometric'), ImageStyle.geometric);
        expect(ImageStyle.fromId('flatDesign'), ImageStyle.flatDesign);
      });

      test('returns null for invalid ID', () {
        expect(ImageStyle.fromId('nonexistent'), isNull);
        expect(ImageStyle.fromId(''), isNull);
        expect(ImageStyle.fromId('WATERCOLOR'), isNull); // Case sensitive
      });

      test('returns correct style for all values', () {
        for (final style in ImageStyle.values) {
          expect(ImageStyle.fromId(style.id), style);
        }
      });
    });

    group('ids', () {
      test('has correct count', () {
        final ids = ImageStyle.values.map((s) => s.name).toList();
        expect(ids.length, ImageStyle.values.length);
      });

      test('contains all style IDs', () {
        expect(
          ImageStyle.values.map((s) => s.name).toList(),
          containsAll([
            'watercolor',
            'minimalist',
            'gradient',
            'retro',
            'geometric',
            'flatDesign',
          ]),
        );
      });

      test('each ID can be resolved', () {
        for (final id in ImageStyle.values.map((s) => s.name)) {
          expect(
            ImageStyle.fromId(id),
            isNotNull,
            reason: 'ID $id should resolve',
          );
        }
      });
    });

    group('schemaDescription', () {
      test('includes all style names', () {
        final desc = ImageStyle.schemaDescription();
        for (final style in ImageStyle.values) {
          expect(desc, contains(style.name), reason: 'Missing ${style.name}');
        }
      });

      test('includes descriptions', () {
        final desc = ImageStyle.schemaDescription();
        for (final style in ImageStyle.values) {
          expect(
            desc,
            contains(style.description),
            reason: 'Missing description for ${style.name}',
          );
        }
      });

      test('default count=1 uses "Choose one from"', () {
        expect(ImageStyle.schemaDescription(), contains('Choose one from'));
      });

      test('count=3 uses "Select 3 styles"', () {
        expect(
          ImageStyle.schemaDescription(count: 3),
          contains('Select 3 styles'),
        );
      });
    });

    group('specific styles', () {
      test('watercolor treatment mentions watercolor painting', () {
        expect(
          ImageStyle.watercolor.treatment,
          contains('watercolor painting'),
        );
      });

      test('minimalist treatment mentions negative space', () {
        expect(ImageStyle.minimalist.treatment, contains('negative space'));
      });

      test('gradient treatment mentions gradients', () {
        expect(ImageStyle.gradient.treatment, contains('gradients'));
      });

      test('retro treatment mentions vintage', () {
        expect(ImageStyle.retro.treatment, contains('vintage'));
      });

      test('geometric treatment mentions angular shapes', () {
        expect(ImageStyle.geometric.treatment, contains('angular shapes'));
      });

      test('flatDesign treatment mentions flat design', () {
        expect(ImageStyle.flatDesign.treatment, contains('flat design'));
      });
    });
  });
}
