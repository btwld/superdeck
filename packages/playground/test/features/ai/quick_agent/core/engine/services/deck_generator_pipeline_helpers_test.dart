import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_pipeline_helpers.dart';
import 'package:superdeck_core/superdeck_core.dart' show Slide;

void main() {
  group('sanitizeGeneratedSlides', () {
    test('preserves spacing, padding, and margin for the canonical parser', () {
      final sanitized = sanitizeGeneratedSlides([
        {
          'key': 'slide-layout',
          'sections': [
            {
              'type': 'section',
              'spacing': 24,
              'blocks': [
                {
                  'type': 'block',
                  'content': '# Hello',
                  'padding': {'top': 12, 'right': 24, 'bottom': 12, 'left': 24},
                  'margin': {'top': 8, 'right': 8, 'bottom': 8, 'left': 8},
                },
              ],
            },
          ],
        },
      ]);

      expect(sanitized, hasLength(1));
      final parsed = Slide.parse(Map<String, Object?>.from(sanitized.single));
      final section = parsed.sections.single;
      expect(section.spacing, 24);
      expect(section.blocks.single.padding?.left, 24);
      expect(section.blocks.single.margin?.top, 8);
    });

    test('drops empty blocks and sections but keeps usable ones', () {
      final sanitized = sanitizeGeneratedSlides([
        {
          'key': 'slide-partial',
          'sections': [
            {
              'blocks': [
                {'type': 'block', 'content': ''},
              ],
            },
            {
              'blocks': [
                {'type': 'block', 'content': 'Kept'},
              ],
            },
          ],
        },
      ]);

      expect(sanitized, hasLength(1));
      expect(sanitized.single['sections'], hasLength(1));
    });

    test('flattens generation-only widget args into canonical payloads', () {
      final sanitized = sanitizeGeneratedSlides([
        {
          'key': 'widget-slide',
          'sections': [
            {
              'blocks': [
                {
                  'type': 'widget',
                  'name': 'image',
                  'args': {'src': 'assets/example.png', 'fit': 'contain'},
                },
              ],
            },
          ],
        },
      ]);

      final block =
          (sanitized.single['sections'] as List).single['blocks'].single as Map;
      expect(block, containsPair('src', 'assets/example.png'));
      expect(block, containsPair('fit', 'contain'));
      expect(block, isNot(contains('args')));
    });

    test('repairs double-escaped line breaks in generated Markdown', () {
      final sanitized = sanitizeGeneratedSlides([
        {
          'key': 'escaped-markdown',
          'sections': [
            {
              'blocks': [
                {
                  'type': 'block',
                  'content': r'### Signal\nOne concrete supporting sentence.',
                },
              ],
            },
          ],
        },
      ]);

      Slide.parse(Map<String, Object?>.from(sanitized.single));
      final block =
          (sanitized.single['sections'] as List).single['blocks'].single as Map;
      expect(block['content'], '### Signal\nOne concrete supporting sentence.');
    });
  });
}
