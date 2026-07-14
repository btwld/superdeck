import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/features/ai/quick_agent/core/engine/prompts/prompt_registry.dart';
import 'package:playground/features/ai/quick_agent/core/env_config.dart';
import 'package:playground/features/ai/quick_agent/domain/commands/generate_deck_command.dart';
import 'package:playground/features/ai/wizard/core/ai/services/prompt_builder.dart';
import 'package:playground/features/ai/wizard/core/ai/wizard_context.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'generates a parseable deck from real Wizard content',
    () async {
      expect(
        EnvConfig.hasGeminiApiKey,
        isTrue,
        reason:
            'Run this live test with '
            '--dart-define-from-file=../../.env.',
      );

      PromptRegistry.instance.loadForTest(
        prompts: {
          'outline_system': await File(
            'assets/ai_prompts/outline_system.prompt',
          ).readAsString(),
          'deck_system': await File(
            'assets/ai_prompts/deck_system.prompt',
          ).readAsString(),
        },
        partials: {
          'deck_templates': await File(
            'assets/ai_prompts/partials/_deck_templates.prompt',
          ).readAsString(),
        },
      );
      addTearDown(PromptRegistry.instance.reset);

      const requestedSlideCount = 6;
      const context = WizardContext(
        topic: 'SuperDeck adoption plan for a product engineering team',
        audience: 'Engineering leaders evaluating presentation tooling',
        approach: 'Data-driven and practical',
        emphasis: [
          'Markdown authoring workflow',
          'Maintainability and developer experience',
          'Adoption risks and rollout plan',
        ],
        slideCount: requestedSlideCount,
        style: 'Clean and technical',
        colors: ['#F8FAFC', '#0F766E', '#334155'],
        headlineFont: 'poppins',
        bodyFont: 'lato',
      );
      final prompt = buildPromptFromWizardContext(context);
      final documentStore = DeckDocumentStore(markdown: '');
      final deckLoader = MemoryDeckLoader();
      final deckController = DeckController(
        deckLoader: deckLoader,
        options: DeckOptions(),
      );
      final customizationStore = DeckCustomizationStore(deckController);
      var styleNotifications = 0;
      customizationStore.addListener(() => styleNotifications++);
      final command = GenerateDeckCommand(
        documentStore: documentStore,
        customizationStore: customizationStore,
      );
      addTearDown(command.dispose);
      addTearDown(customizationStore.dispose);
      addTearDown(deckController.dispose);
      addTearDown(deckLoader.dispose);
      addTearDown(documentStore.dispose);

      await command(prompt);

      expect(command.completed, isTrue, reason: command.result.toString());
      expect(documentStore.markdown, isNotEmpty);
      expect(
        styleNotifications,
        1,
        reason: 'The generated global style should be applied atomically.',
      );

      final rawSlides = const MarkdownParser().parse(documentStore.markdown);
      expect(rawSlides, hasLength(requestedSlideCount));

      for (final slide in rawSlides) {
        final sections = const SectionParser().parse(slide.content);
        expect(
          sections,
          isNotEmpty,
          reason: 'Every generated slide must contain a parseable section.',
        );
        expect(
          sections.expand((section) => section.blocks),
          isNotEmpty,
          reason: 'Every generated slide must contain visible content.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
