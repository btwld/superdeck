import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/wizard/core/ai/prompts/prompt_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled deck-edit prompt renders the seven keyless tool contracts',
    () async {
      PromptRegistry.instance.reset();
      addTearDown(PromptRegistry.instance.reset);

      await PromptRegistry.instance.load();
      final prompt = PromptRegistry.instance.render('deck_edit_system');

      for (final name in [
        'getDeck',
        'createSlide',
        'updateSlide',
        'deleteSlide',
        'moveSlide',
        'readSlide',
        'updateStyle',
      ]) {
        expect(prompt, contains(name));
      }
      expect(prompt, contains('DeckToolSlide is keyless'));
    },
  );
}
