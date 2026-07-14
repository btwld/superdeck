import 'dart:convert';

import '../../../../../../core/domain/design/presentation_typography_catalog.dart';
import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';
import '../services/style_json_serializer.dart';
import '../services/design_quality_metrics.dart';
import '../services/generation_element_catalog.dart';
import 'composition_example_library.dart';
import 'prompt_registry.dart';

/// Supplies fully rendered prompts to the deck-generation pipeline.
abstract interface class GenerationPromptProvider {
  Future<void> load();

  String buildOutlinePrompt({
    required PresentationTypographyCatalog typographyCatalog,
    List<String> validationErrors = const [],
    Map<String, Object?>? invalidPlan,
  });

  String buildSlidePrompt({
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required Map<String, Object?>? previousSlide,
    required DeckPlanSlideType? next,
    required GenerationElementCatalog elementCatalog,
    List<String> validationErrors = const [],
    Map<String, Object?>? invalidSlide,
  });

  String buildOutlineSlideRepairPrompt({
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required List<String> validationErrors,
    Map<String, Object?>? invalidSlide,
  });
}

/// Flutter-asset backed prompt provider used by the production app.
final class AssetGenerationPromptProvider implements GenerationPromptProvider {
  AssetGenerationPromptProvider({
    PromptRegistry? promptRegistry,
    AssetCompositionExampleLibrary? exampleLibrary,
  }) : _promptRegistry = promptRegistry ?? PromptRegistry.instance,
       _exampleLibrary = exampleLibrary ?? AssetCompositionExampleLibrary();

  final PromptRegistry _promptRegistry;
  final AssetCompositionExampleLibrary _exampleLibrary;

  @override
  Future<void> load() =>
      Future.wait([_promptRegistry.load(), _exampleLibrary.load()]);

  @override
  String buildOutlinePrompt({
    required PresentationTypographyCatalog typographyCatalog,
    List<String> validationErrors = const [],
    Map<String, Object?>? invalidPlan,
  }) {
    final literalRepairChecklist = _outlineLiteralRepairChecklist(
      validationErrors,
    );
    final repairSection = validationErrors.isEmpty
        ? ''
        : '''

## Invalid deck plan to repair

Use this invalid plan as the repair base and return a complete replacement plan.
Make only the field edits needed to satisfy the constraints below. Preserve all
other valid keys, ordering, content, facts, and design decisions. Do not merely
explain the changes.

${const JsonEncoder.withIndent('  ').convert(invalidPlan)}

## Current and prior deck-plan validation constraints

${validationErrors.map((error) => '- $error').join('\n')}
$literalRepairChecklist

This list is cumulative. A constraint may already be fixed in the current base;
if so, preserve that fix. Mechanically re-check every constraint before returning
JSON so a repair never reintroduces an earlier factual or structural error.
''';
    return '''
${_promptRegistry.render('outline_system')}

## Registered typography catalog

Use an exact `family` value from the appropriate list. Never invent a family.

Headline families:
${_formatFonts(typographyCatalog.forRole(PresentationFontRole.headline))}

Body families:
${_formatFonts(typographyCatalog.forRole(PresentationFontRole.body))}
$repairSection
''';
  }

  @override
  String buildSlidePrompt({
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required Map<String, Object?>? previousSlide,
    required DeckPlanSlideType? next,
    required GenerationElementCatalog elementCatalog,
    List<String> validationErrors = const [],
    Map<String, Object?>? invalidSlide,
  }) {
    final basePrompt = _promptRegistry.render('slide_system');
    final compositionExample = _exampleLibrary.buildFor(
      current: current,
      elementCatalog: elementCatalog,
    );
    return buildSingleSlidePrompt(
      basePrompt: basePrompt,
      fieldGuidance: getSlideGenerationGuidance(),
      plan: plan,
      current: current,
      previousSlide: previousSlide,
      next: next,
      validationErrors: validationErrors,
      invalidSlide: invalidSlide,
      elementCatalog: elementCatalog,
      compositionExample: compositionExample,
    );
  }

  @override
  String buildOutlineSlideRepairPrompt({
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required List<String> validationErrors,
    Map<String, Object?>? invalidSlide,
  }) {
    const encoder = JsonEncoder.withIndent('  ');
    final section = plan.sections.firstWhere(
      (candidate) => candidate.key == current.sectionKey,
    );
    final index = plan.slides.indexWhere(
      (candidate) => candidate.key == current.key,
    );
    final previous = index > 0 ? plan.slides[index - 1] : null;
    final next = index + 1 < plan.slides.length ? plan.slides[index + 1] : null;
    return '''
You repair exactly one slide inside an already structured presentation plan.
Return one complete deck-plan slide JSON object matching the response schema.
Do not return the whole deck, Markdown, commentary, or a `slides` wrapper.

The user message contains the original typed generation request and is the only
authority for factual claims, numbers, domains, capabilities, evidence status,
and commitments.

## Immutable fields

Preserve these fields exactly from the repair base: `key`, `sectionKey`,
`narrativeRole`, `composition`, `treatment`, `density`, and `elements`. Repair
only `title`, `purpose`, `assertion`, `contentUnits`, `contentBrief`, and
`continuity` as needed. Preserve every valid fact and design decision.

## Repair rules

- Resolve every listed validation error in the same response.
- The returned JSON must contain zero occurrences of every unsupported phrase
  named below; do not substitute another evidence-strength, causal, absolute,
  implementation, availability, security, or commercial claim.
- Copy supplied numeric facts with their exact subject, unit, and comparison.
  The original request's `groundedNumericFacts` are authoritative; a shortened
  field in the repair base is not. For a mismatched number, either copy the
  complete matching grounded phrase or delete that occurrence. For an
  unsupported number, delete every occurrence from every returned field. Never
  calculate a complement (for example, turning 31% into 69%) or split a supplied
  time horizon into invented milestones.
- If the brief requests only a category with missing detail, mark each invented
  detail in its own field as `planned`, `proposed direction`, or `illustrative
  option`. Do not use those qualifiers to disguise claims about observed beta
  evidence.
- Keep the assertion audience-facing, concise, and consistent with the section.

## Deck context

Topic: ${plan.topic}
Story: ${plan.story}
Section: ${encoder.convert(Map<String, Object?>.from(section))}
Previous slide: ${previous == null ? 'None' : encoder.convert(Map<String, Object?>.from(previous))}
Next slide: ${next == null ? 'None' : encoder.convert(Map<String, Object?>.from(next))}

## Repair base

${encoder.convert(invalidSlide ?? Map<String, Object?>.from(current))}

## Validation errors

${validationErrors.map((error) => '- $error').join('\n')}

Return only the corrected single-slide plan object.
''';
  }
}

String _outlineLiteralRepairChecklist(List<String> validationErrors) {
  final sections = <String>[];
  if (validationErrors.any(
    (error) => error.contains('Delete every occurrence of the word zero'),
  )) {
    sections.add('''
## Mandatory literal sweep

Search the complete replacement JSON case-insensitively before returning it.
It must contain no standalone `zero`, `0`, or `0%` token anywhere, including
titles, assertions, content units, briefs, and continuity. Replace "zero to
insight" with "signals to insight"; replace "zero disruption" with the exact
supplied "no change to source-of-truth systems" fact; remove other zero idioms.
Do not preserve an invalid phrase merely because its surrounding field is valid.
''');
  }
  if (validationErrors.any(
    (error) => error.contains('unsupported commitment claim(s)'),
  )) {
    sections.add('''
## Mandatory cumulative commitment sweep

Re-read every cumulative error containing `unsupported commitment claim(s)`.
Search the complete replacement JSON for every named phrase, including phrases
from earlier attempts. Each occurrence must either be removed or carry an
explicit `planned`, `proposed`, or `illustrative option` qualifier in that same
individual field or content unit. A qualifier in a slide title, sibling bullet,
or neighboring field does not qualify it. Do not reintroduce a phrase that an
earlier repair removed. Delete evidence-strength, causal, and absolute-scope
language instead of merely swapping it for a synonym; a supplied metric does
not authorize an explanation of why it changed or a broader product claim.
''');
  }
  if (validationErrors.any((error) => error.contains('handoff omits'))) {
    sections.add('''
## Mandatory grounded-handoff sweep

For every handoff error, copy the supplied element's destination or experience
identity into an audience-facing `contentUnits` item on that exact slide. In
particular, a SuperDeck QR destination must visibly say `SuperDeck`; the deck's
fictional product name is not a substitute.
''');
  }
  if (validationErrors.any(
    (error) => error.contains('changes the supplied meaning of numeric'),
  )) {
    sections.add('''
## Mandatory metric-identity sweep

For every affected number, copy its complete matching `groundedNumericFacts`
wording into the same field or content unit, including the subject, unit, and
comparison. Do not assign a beta cohort number to the audience, onboarding
steps, future targets, or another feature.
''');
  }
  return sections.join('\n');
}

String _formatFonts(List<PresentationFontDescriptor> fonts) =>
    fonts.map((font) => '- `${font.family}`: ${font.description}').join('\n');

String buildSingleSlidePrompt({
  required String basePrompt,
  required String fieldGuidance,
  required DeckPlanType plan,
  required DeckPlanSlideType current,
  required Map<String, Object?>? previousSlide,
  required DeckPlanSlideType? next,
  required GenerationElementCatalog elementCatalog,
  required Map<String, Object?> compositionExample,
  List<String> validationErrors = const [],
  Map<String, Object?>? invalidSlide,
}) {
  const encoder = JsonEncoder.withIndent('  ');
  final currentSection = plan.sections.firstWhere(
    (section) => section.key == current.sectionKey,
  );
  final currentIndex = plan.slides.indexWhere(
    (candidate) => candidate.key == current.key,
  );
  if (currentIndex < 0) {
    throw ArgumentError.value(current.key, 'current', 'Slide is not in plan.');
  }
  final ledgerStart = currentIndex > 3 ? currentIndex - 3 : 0;
  final contentBudget = visibleCharacterLimit(
    current.density,
    composition: current.composition,
  );
  final wordBudget = contentBudget ~/ 8;
  final compositionBudgetGuidance = switch (current.composition) {
    'title' =>
      'Use exactly one section containing one content block. Put the short H1 '
          'and optional short H2 or supporting sentence in that same block so '
          'the display type has the full slide height. Do not split title and '
          'support copy into separate vertical sections.',
    'twoColumn' =>
      'Use one short H2 and one two-block content section. In each column, use '
          'one short H3 plus at most two concise bullets or one sentence. Do not '
          'add italic subtitles.',
    'threeColumn' =>
      'Use one short H2 and one three-block content section. In each column, use '
          'one short H3 plus one concise sentence.',
    'content' =>
      'Use one short H2 plus one concise paragraph or a list of at most three '
          'short bullets.',
    'table' =>
      'Use one short H2 and one compact table. Keep cells telegraphic rather '
          'than sentence-like.',
    _ => 'Prefer the smallest amount of copy that fully earns the assertion.',
  };
  final recentLedger = [
    for (final slide in plan.slides.sublist(ledgerStart, currentIndex))
      {
        'key': slide.key,
        'sectionKey': slide.sectionKey,
        'composition': slide.composition,
        'treatment': slide.treatment,
        'density': slide.density,
      },
  ];
  final speakerCommentRepairChecklist =
      validationErrors.any((error) => error.startsWith('Speaker comments '))
      ? '''

## Speaker-comment repair

The visible slide may already be valid. Fix or delete the offending speaker
comments without rewriting valid visible Markdown. A comment that mentions a
number must copy the complete matching fact from `groundedNumericFacts` in the
original user request verbatim, including its unit, comparison, and subject, or
delete the comment. A planned content unit may be a shortened narrative label;
it is not the factual authority. Do not paraphrase the metric.
'''
      : '';
  final metricIdentityRepairChecklist =
      validationErrors.any(
        (error) =>
            error.contains('changes the supplied meaning of numeric claim'),
      )
      ? '''

## Metric-identity repair

For each named number, use the original user request's `groundedNumericFacts`,
not a shortened plan field, as the factual authority. Copy the complete matching
source phrase verbatim into visible Markdown, including its subject, unit, and
comparison. Delete any second shorthand occurrence that cannot carry that same
meaning; do not repeat a number as a shortened label or bullet. Do not replace
`design partners` with customers, teams, organizations, or a generic beta
cohort. A speaker comment must either copy the same grounded source phrase or be
deleted.
'''
      : '';
  final repairSection = validationErrors.isEmpty
      ? ''
      : '''
## Invalid slide draft to repair

Use this draft as the repair base and return a complete replacement slide. Make
only the edits needed to satisfy the cumulative constraints below. Preserve
every other valid planned field and never reintroduce a resolved violation.

${invalidSlide == null ? 'No parseable draft was returned.' : encoder.convert(invalidSlide)}

## Current and prior validation constraints
${validationErrors.map((error) => '- $error').join('\n')}
$speakerCommentRepairChecklist
$metricIdentityRepairChecklist

This list is cumulative. Preserve every resolved constraint while fixing the
remaining draft.
''';
  return '''
$basePrompt

$fieldGuidance

## Deck context

Deck topic: ${plan.topic}
Deck story: ${plan.story}
Deck style: ${encoder.convert(serializeDeckStyleForJson(plan.style))}

## Current narrative section
${encoder.convert(Map<String, Object?>.from(currentSection))}

## Recent design ledger
${recentLedger.isEmpty ? 'None (this is the first planned slide).' : encoder.convert(recentLedger)}

## Current slide plan
${encoder.convert(Map<String, Object?>.from(current))}

## Neighbor context
Previous canonical slide:
${previousSlide == null ? 'None (this is the first slide).' : encoder.convert(previousSlide)}

Next plan item:
${next == null ? 'None (this is the final slide).' : encoder.convert(Map<String, Object?>.from(next))}

## Available elements
${elementCatalog.formatForPrompt()}

## Relevant composition example
Use this one example for structural guidance only. Replace its generic words
with the current assertion and content units. Its grounded source, when present,
is already exact; do not introduce another source. A metric example mirrors the
current plan's numeric token and never supplies a new factual value.

${encoder.convert(compositionExample)}
$repairSection
## Final task
Return exactly one slide object, not a deck and not a `slides` array.
The slide key must be exactly `${current.key}`. Compose only this slide. Fulfill
its assertion, content units, composition, treatment, density, and planned
elements while preserving continuity. Keep all visible Markdown at or below
$contentBudget characters and no more than $wordBudget visible words for the
`${current.density}` density. Count headings, labels, and table cells in both
limits. Synthesize the planned content units instead of expanding each into a
separate paragraph. $compositionBudgetGuidance Do not repeat the previous slide
or generate future slides.
''';
}
