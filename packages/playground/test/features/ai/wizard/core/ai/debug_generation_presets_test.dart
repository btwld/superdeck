import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/wizard/core/ai/debug_generation_presets.dart';
import 'package:playground/features/ai/wizard/core/ai/services/prompt_builder.dart';

void main() {
  test('debug presets produce three complete generation prompts', () {
    expect(debugGenerationPresets, hasLength(3));
    expect(
      debugGenerationPresets.map((preset) => preset.label).toSet(),
      hasLength(3),
    );

    for (final preset in debugGenerationPresets) {
      final context = preset.context;
      final prompt = buildPromptFromWizardContext(context);

      expect(context.topic, isNotEmpty);
      expect(context.slideCount, inInclusiveRange(5, 20));
      expect(context.colors, hasLength(3));
      expect(prompt, contains('Topic: ${context.topic}'));
      expect(prompt, contains('Number of Slides: ${context.slideCount}'));
      expect(prompt, isNot(contains('Layout Guidance:')));
    }
  });
}
