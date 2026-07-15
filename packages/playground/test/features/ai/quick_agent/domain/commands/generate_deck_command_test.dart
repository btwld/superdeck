import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/core/result.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_progress.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_trace.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_validation_issue.dart';
import 'package:playground/features/ai/quick_agent/domain/commands/generate_deck_command.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart'
    show SectionBlock, Slide, SlideOptions;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'loads accepted slides when generation returns a partial deck',
    () async {
      final plan = _plan();
      final acceptedSlide = Slide(
        key: 'accepted',
        options: SlideOptions(title: 'Accepted slide', style: 'content'),
        sections: [
          SectionBlock.text('## Accepted slide\n\nUseful grounded content.'),
        ],
      );
      final partial = DeckGenerationResult.partial(
        slides: [acceptedSlide],
        slideFailures: const [
          SlideGenerationFailure(
            slideIndex: 2,
            slideKey: 'missing',
            issues: [
              GenerationValidationIssue(
                code: GenerationValidationCode.invalidSchema,
                category: GenerationValidationCategory.schema,
                severity: GenerationValidationSeverity.blocking,
                location: GenerationValidationLocation.visibleContent,
                message: 'Slide response was not valid JSON.',
              ),
            ],
          ),
        ],
        plan: plan,
        theme: _resolvedTheme(),
      );
      final documentStore = DeckDocumentStore(markdown: '');
      final controller = DeckController(
        deckLoader: MemoryDeckLoader(),
        options: DeckOptions(),
      );
      final customizationStore = DeckCustomizationStore(controller);
      final command = GenerateDeckCommand(
        documentStore: documentStore,
        customizationStore: customizationStore,
        service: _StubDeckGeneratorService(partial),
      );
      addTearDown(command.dispose);
      addTearDown(customizationStore.dispose);
      addTearDown(controller.dispose);
      addTearDown(documentStore.dispose);

      final result = await command.action(
        const DeckGenerationRequest(userIntent: 'Test deck', slideCount: 2),
      );

      expect(result, isA<Ok<void>>());
      expect(documentStore.markdown, contains('Accepted slide'));
      expect(command.completionNotice, contains('Generated 1 of 2 slides'));
    },
  );
}

final class _StubDeckGeneratorService extends DeckGeneratorService {
  _StubDeckGeneratorService(this.result) : super(apiKey: 'test-key');

  final DeckGenerationResult result;

  @override
  Future<DeckGenerationResult> generate(
    DeckGenerationRequest request, {
    GenerationProgressCallback? onProgress,
    GenerationTraceCallback? onTrace,
    bool Function()? isCancelled,
  }) async => result;
}

DeckPlanType _plan() => DeckPlanType.parse({
  'topic': 'Partial deck',
  'story': 'Keep accepted work when one slide fails.',
  'theme': {'id': 'technical-paper', 'version': 1, 'density': 'balanced'},
  'sections': [
    {
      'key': 'main',
      'title': 'Main',
      'purpose': 'Explain the partial result.',
      'transition': 'Finish the story.',
      'slideKeys': ['accepted', 'missing'],
    },
  ],
  'slides': [_planSlide('accepted'), _planSlide('missing')],
});

Map<String, Object?> _planSlide(String key) => {
  'key': key,
  'title': key,
  'purpose': 'Advance $key.',
  'sectionKey': 'main',
  'assertion': '$key matters.',
  'contentUnits': ['$key evidence'],
  'narrativeRole': 'evidence',
  'contentBrief': 'Use concrete content.',
  'continuity': 'Connect the story.',
  'composition': 'content',
  'treatment': 'content',
  'density': 'balanced',
};

ResolvedPresentationTheme _resolvedTheme() {
  final themes = PresentationThemeCatalog.withDefaults();
  return themes.resolve(
    id: 'technical-paper',
    version: 1,
    density: 'balanced',
    typographyCatalog: PresentationTypographyCatalog.withDefaults(),
  );
}
