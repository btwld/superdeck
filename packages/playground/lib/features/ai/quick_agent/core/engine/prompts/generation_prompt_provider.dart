import 'dart:convert';

import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';
import '../services/theme_json_serializer.dart';
import '../services/design_quality_metrics.dart';
import '../services/generation_element_catalog.dart';
import '../services/generation_validation_issue.dart';
import '../services/source_grounding.dart';
import 'composition_example_library.dart';
import 'prompt_registry.dart';

/// Supplies fully rendered prompts to the deck-generation pipeline.
abstract interface class GenerationPromptProvider {
  Future<void> load();

  String buildOutlinePrompt({
    required List<PresentationThemeDescriptor> themeCandidates,
    List<GenerationValidationIssue> validationIssues = const [],
    Map<String, Object?>? invalidPlan,
  });

  String buildSlidePrompt({
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required Map<String, Object?>? previousSlide,
    required DeckPlanSlideType? next,
    required GenerationElementCatalog elementCatalog,
    List<GenerationValidationIssue> validationIssues = const [],
    Map<String, Object?>? invalidSlide,
  });

  String buildSectionPrompt({
    required DeckPlanType plan,
    required DeckPlanSectionType section,
    required List<DeckPlanSlideType> slides,
    required DeckPlanSlideType? previous,
    required DeckPlanSlideType? next,
    required GenerationElementCatalog elementCatalog,
  });

  String buildOutlineSlideRepairPrompt({
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required List<GenerationValidationIssue> validationIssues,
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
    required List<PresentationThemeDescriptor> themeCandidates,
    List<GenerationValidationIssue> validationIssues = const [],
    Map<String, Object?>? invalidPlan,
  }) {
    if (validationIssues.isNotEmpty) {
      return _buildOutlineRepairPrompt(
        themeCandidates: themeCandidates,
        validationIssues: validationIssues,
        invalidPlan: invalidPlan,
      );
    }

    return '''
${_promptRegistry.render('outline_system')}

## Eligible presentation themes

Choose exactly one `theme.id` from the compact candidates below. Return only
that ID inside the theme object. Never return a version, palette, font family,
brand override, or runtime styling token; the application owns those values.

${const JsonEncoder.withIndent('  ').convert(themeCandidates.map((theme) => theme.toModelCandidate()).toList())}
''';
  }

  String _buildOutlineRepairPrompt({
    required List<PresentationThemeDescriptor> themeCandidates,
    required List<GenerationValidationIssue> validationIssues,
    required Map<String, Object?>? invalidPlan,
  }) {
    const encoder = JsonEncoder.withIndent(' ');
    final literalRepairChecklist = _outlineLiteralRepairChecklist(
      validationIssues,
    );
    return '''
You repair one SuperDeck deck plan. Return one complete replacement deck-plan
JSON object matching the response schema—no commentary or Markdown fence.

The original typed user message is the only authority for facts, numbers,
domains, supplied elements, evidence status, availability, security/compliance,
and commercial commitments. Use the invalid plan as the repair base. Fix every
blocking issue below while preserving all valid keys, ordering, narrative,
content, facts, theme choice, and design decisions. Do not redesign the deck.

Hard contract:
- preserve the requested slide count, slide order, unique keys, section
  membership, and exact supported composition/treatment values
- keep audience-facing claims grounded in the original request
- keep each planned element's exact type, source, purpose, and cardinality
- choose one eligible theme ID; never author palette, font, or runtime tokens
- return the complete plan, including every valid unchanged section and slide

## Eligible theme IDs

${encoder.convert(themeCandidates.map((theme) => theme.id).toList())}

## Invalid plan

${invalidPlan == null ? 'No parseable plan was returned.' : encoder.convert(invalidPlan)}

## Blocking issues

${validationIssues.map((issue) => '- ${issue.message}').join('\n')}
$literalRepairChecklist

The blocking list is cumulative. Before returning JSON, re-check every item and
preserve any correction already present in the repair base. Return only the
complete corrected deck-plan object.
''';
  }

  @override
  String buildSlidePrompt({
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required Map<String, Object?>? previousSlide,
    required DeckPlanSlideType? next,
    required GenerationElementCatalog elementCatalog,
    List<GenerationValidationIssue> validationIssues = const [],
    Map<String, Object?>? invalidSlide,
  }) {
    if (validationIssues.isNotEmpty) {
      return buildSingleSlideRepairPrompt(
        plan: plan,
        current: current,
        previousSlide: previousSlide,
        next: next,
        validationIssues: validationIssues,
        invalidSlide: invalidSlide,
        elementCatalog: elementCatalog,
      );
    }
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
      validationIssues: validationIssues,
      invalidSlide: invalidSlide,
      elementCatalog: elementCatalog,
      compositionExample: compositionExample,
    );
  }

  @override
  String buildSectionPrompt({
    required DeckPlanType plan,
    required DeckPlanSectionType section,
    required List<DeckPlanSlideType> slides,
    required DeckPlanSlideType? previous,
    required DeckPlanSlideType? next,
    required GenerationElementCatalog elementCatalog,
  }) {
    if (slides.isEmpty) {
      throw ArgumentError.value(slides, 'slides', 'Section cannot be empty.');
    }
    if (slides.any((slide) => slide.sectionKey != section.key)) {
      throw ArgumentError('Every slide must belong to section ${section.key}.');
    }

    const encoder = JsonEncoder.withIndent('  ');
    final plannedElements = [for (final slide in slides) ...?slide.elements];
    final numericUnits = <String, List<String>>{
      for (final slide in slides)
        slide.key: [
          for (final unit in [slide.assertion, ...slide.contentUnits])
            if (extractNumericClaims([unit]).isNotEmpty) unit,
        ],
    }..removeWhere((_, units) => units.isEmpty);
    final budgets = [
      for (final slide in slides)
        {
          'key': slide.key,
          'maximumVisibleCharacters':
              (visibleCharacterLimit(
                    slide.density,
                    composition: slide.composition,
                  ) *
                  3) ~/
              4,
          'maximumVisibleWords':
              ((visibleCharacterLimit(
                        slide.density,
                        composition: slide.composition,
                      ) *
                      3) ~/
                  4) ~/
              8,
        },
    ];
    final shapeExamples = <Map<String, Object?>>[];
    final exampleCompositions = <String>{};
    for (final slide in slides) {
      if (!exampleCompositions.add(slide.composition)) continue;
      final example = _exampleLibrary.buildFor(
        current: slide,
        elementCatalog: elementCatalog,
      );
      example['key'] = 'example-${slide.composition}';
      shapeExamples.add(example);
    }

    return '''
${_promptRegistry.render('section_system')}

## Deck context

Topic: ${plan.topic}
Story: ${plan.story}
Theme: ${encoder.convert(serializeDeckThemeForSlidePrompt(plan.theme))}

## Current narrative section

${encoder.convert(Map<String, Object?>.from(section))}

## Ordered slide plans

${encoder.convert(slides.map(Map<String, Object?>.from).toList())}

## Boundary context

Previous plan item: ${previous == null ? 'None.' : encoder.convert(Map<String, Object?>.from(previous))}
Next plan item: ${next == null ? 'None.' : encoder.convert(Map<String, Object?>.from(next))}

## Per-slide visible-content budgets

${encoder.convert(budgets)}

These are hard output maxima, not suggestions. Count every heading, label,
bullet, table cell, and paragraph. Remove secondary explanation until each slide
fits its own maximum; never borrow another slide's budget.

## Canonical shape examples

The objects below are valid individual slide shapes, one per composition used
in this section. Follow their section/block structure, but never return an
`example-*` key or copy their generic wording. The ordered plans remain the
authority for content, treatment, density, elements, and slide keys.

${encoder.convert(shapeExamples)}

## Numeric copy contract

${numericUnits.isEmpty ? 'No numeric unit is planned in this section.' : '''For the units grouped by slide key below, copy each complete unit verbatim into that slide or omit its number. Never shorten, relabel, calculate from, move to another slide, or paraphrase a number. Preserve every explicit planned, proposed, projected, target, or illustrative qualifier in the same visible line.

${encoder.convert(numericUnits)}'''}

## Available elements

${plannedElements.isEmpty ? 'No elements are planned in this section.' : elementCatalog.formatForPrompt()}

## Final task

Return one `slides` array containing exactly ${slides.length} slides with keys,
in order: ${slides.map((slide) => '`${slide.key}`').join(', ')}. Fulfill each
plan item without borrowing facts or elements from another slide.
''';
  }

  @override
  String buildOutlineSlideRepairPrompt({
    required DeckPlanType plan,
    required DeckPlanSlideType current,
    required List<GenerationValidationIssue> validationIssues,
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

${validationIssues.map((issue) => '- ${issue.message}').join('\n')}

Return only the corrected single-slide plan object.
''';
  }
}

String buildSingleSlideRepairPrompt({
  required DeckPlanType plan,
  required DeckPlanSlideType current,
  required Map<String, Object?>? previousSlide,
  required DeckPlanSlideType? next,
  required List<GenerationValidationIssue> validationIssues,
  required Map<String, Object?>? invalidSlide,
  required GenerationElementCatalog elementCatalog,
}) {
  const encoder = JsonEncoder.withIndent('  ');
  final contentBudget = visibleCharacterLimit(
    current.density,
    composition: current.composition,
  );
  final requiresElementContext = validationIssues.any(
    (issue) =>
        issue.code == GenerationValidationCode.elementGrounding ||
        issue.code == GenerationValidationCode.widgetArguments ||
        issue.code == GenerationValidationCode.handoffPurpose,
  );
  final requiresNumericContext = validationIssues.any(
    (issue) =>
        issue.code == GenerationValidationCode.numericGrounding ||
        issue.code == GenerationValidationCode.numericMeaning ||
        issue.code == GenerationValidationCode.metricIntent,
  );
  final hasCommentIssue = validationIssues.any(
    (issue) => issue.location == GenerationValidationLocation.speakerComments,
  );
  final targetedGuidance = [
    if (requiresNumericContext)
      'For numeric errors, use the original user request and its '
          '`groundedNumericFacts` as authority. Preserve the complete subject, '
          'unit, comparison, and time period somewhere on this slide; delete or '
          'visibly qualify unsupported values.',
    if (hasCommentIssue)
      'Speaker comments are optional. Delete an offending comment instead of '
          'rewriting valid visible content.',
    if (requiresElementContext)
      'Preserve planned widget names, exact sources, purposes, and cardinality. '
          'Do not invent or substitute an element.',
  ];

  return '''
You repair one SuperDeck slide. Return one complete canonical slide JSON object
matching the response schema—no deck wrapper, commentary, or Markdown fence.

The original typed user message is the only factual authority. Use the invalid
draft as the repair base. Fix every blocking issue below while preserving valid
copy, layout, sources, and comments. Do not redesign the slide.

Hard invariants:
- key: `${current.key}`
- options.style: `${current.treatment}`
- planned composition: `${current.composition}`
- visible content budget: at most $contentBudget characters
- one or two sections, 1–3 blocks per section, supported fields only
- no invented facts, numbers, URLs, domains, elements, capabilities, evidence
  status, security/compliance claims, availability, or commercial commitments

## Current slide plan
${encoder.convert(Map<String, Object?>.from(current))}

## Neighbor context
Previous accepted slide:
${previousSlide == null ? 'None.' : encoder.convert(previousSlide)}

Next plan item:
${next == null ? 'None.' : encoder.convert(Map<String, Object?>.from(next))}

## Invalid draft
${invalidSlide == null ? 'No parseable draft was returned.' : encoder.convert(invalidSlide)}

## Blocking issues
${validationIssues.map((issue) => '- ${issue.message}').join('\n')}

${targetedGuidance.join('\n')}
${requiresElementContext ? '\n## Available elements\n${elementCatalog.formatForPrompt()}' : ''}

Return only the corrected slide object.
''';
}

String _outlineLiteralRepairChecklist(
  List<GenerationValidationIssue> validationIssues,
) {
  final sections = <String>[];
  if (validationIssues.any(
    (issue) => issue.code == GenerationValidationCode.numericGrounding,
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
  if (validationIssues.any(
    (issue) => issue.code == GenerationValidationCode.commitmentGrounding,
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
  if (validationIssues.any(
    (issue) => issue.code == GenerationValidationCode.handoffPurpose,
  )) {
    sections.add('''
## Mandatory grounded-handoff sweep

For every handoff error, copy the supplied element's destination or experience
identity into an audience-facing `contentUnits` item on that exact slide. In
particular, a SuperDeck QR destination must visibly say `SuperDeck`; the deck's
fictional product name is not a substitute.
''');
  }
  if (validationIssues.any(
    (issue) => issue.code == GenerationValidationCode.numericMeaning,
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

String buildSingleSlidePrompt({
  required String basePrompt,
  required String fieldGuidance,
  required DeckPlanType plan,
  required DeckPlanSlideType current,
  required Map<String, Object?>? previousSlide,
  required DeckPlanSlideType? next,
  required GenerationElementCatalog elementCatalog,
  required Map<String, Object?> compositionExample,
  List<GenerationValidationIssue> validationIssues = const [],
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
  final previousContext = previousSlide == null
      ? null
      : _compactPreviousSlideContext(previousSlide);
  final elementContext = current.elements == null || current.elements!.isEmpty
      ? 'None planned for this slide.'
      : elementCatalog.formatForPrompt();
  final numericPlanUnits = {
    for (final unit in [current.assertion, ...current.contentUnits])
      if (extractNumericClaims([unit]).isNotEmpty) unit,
  };
  final hypotheticalNumericUnits = [
    for (final unit in numericPlanUnits)
      if (hasProjectionQualifier(unit)) unit,
  ];
  final groundedNumericUnits = [
    for (final unit in numericPlanUnits)
      if (!hasProjectionQualifier(unit)) unit,
  ];
  final numericCopyContract = numericPlanUnits.isEmpty
      ? ''
      : '''

## Numeric copy contract

For each grounded numeric unit below, copy the complete unit verbatim into one
visible line or omit its number. Do not shorten, split, relabel, or paraphrase
its subject, unit, comparison, or time period.

${groundedNumericUnits.isEmpty ? 'No grounded numeric unit is required.' : encoder.convert(groundedNumericUnits)}

For any hypothetical numeric unit below, preserve its explicit hypothetical label
(`planned`, `proposed`, `projected`, `target`, or `illustrative`) in the same
visible line and in any speaker comment that repeats the value.

${hypotheticalNumericUnits.isEmpty ? 'No hypothetical numeric unit is required.' : encoder.convert(hypotheticalNumericUnits)}
''';
  final speakerCommentRepairChecklist =
      validationIssues.any(
        (issue) =>
            issue.location == GenerationValidationLocation.speakerComments,
      )
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
      validationIssues.any(
        (issue) => issue.code == GenerationValidationCode.numericMeaning,
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
  final repairSection = validationIssues.isEmpty
      ? ''
      : '''
## Invalid slide draft to repair

Use this draft as the repair base and return a complete replacement slide. Make
only the edits needed to satisfy the cumulative constraints below. Preserve
every other valid planned field and never reintroduce a resolved violation.

${invalidSlide == null ? 'No parseable draft was returned.' : encoder.convert(invalidSlide)}

## Current and prior validation constraints
${validationIssues.map((issue) => '- ${issue.message}').join('\n')}
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
Deck theme reference: ${encoder.convert(serializeDeckThemeForSlidePrompt(plan.theme))}

## Current narrative section
${encoder.convert(Map<String, Object?>.from(currentSection))}

## Recent design ledger
${recentLedger.isEmpty ? 'None (this is the first planned slide).' : encoder.convert(recentLedger)}

## Current slide plan
${encoder.convert(Map<String, Object?>.from(current))}
$numericCopyContract

## Neighbor context
Previous canonical slide:
${previousContext == null ? 'None (this is the first slide).' : encoder.convert(previousContext)}

Next plan item:
${next == null ? 'None (this is the final slide).' : encoder.convert(Map<String, Object?>.from(next))}

## Available elements
$elementContext

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
elements while preserving continuity. Treat the composition as visual guidance, not factual authority.
Never invent a quotation, metric, or table data just to
match its visual device; preserve grounded, useful content in the nearest clear
layout when the supplied material cannot support that device. Keep all visible Markdown at or below
$contentBudget characters and no more than $wordBudget visible words for the
`${current.density}` density. Count headings, labels, and table cells in both
limits. Synthesize the planned content units instead of expanding each into a
separate paragraph. $compositionBudgetGuidance Do not repeat the previous slide
or generate future slides.
''';
}

Map<String, Object?> _compactPreviousSlideContext(
  Map<String, Object?> previousSlide,
) {
  const visibleLimit = 700;
  final visibleParts = <String>[];
  final rawSections = previousSlide['sections'];
  if (rawSections is List) {
    for (final rawSection in rawSections) {
      if (rawSection is! Map) continue;
      final rawBlocks = rawSection['blocks'];
      if (rawBlocks is! List) continue;
      for (final rawBlock in rawBlocks) {
        if (rawBlock is! Map) continue;
        final content = rawBlock['content'];
        if (content is String && content.trim().isNotEmpty) {
          visibleParts.add(content.trim());
          continue;
        }
        final name = rawBlock['name'];
        if (name is String && name.trim().isNotEmpty) {
          visibleParts.add('[${name.trim()} widget]');
        }
      }
    }
  }
  final visibleText = visibleParts.join('\n\n');
  final options = previousSlide['options'];
  final compactOptions = options is Map
      ? {
          if (options['title'] case final String title) 'title': title,
          if (options['style'] case final String style) 'style': style,
        }
      : const <String, Object?>{};

  return {
    if (previousSlide['key'] case final String key) 'key': key,
    if (compactOptions.isNotEmpty) 'options': compactOptions,
    if (visibleText.isNotEmpty)
      'visibleContent': visibleText.length <= visibleLimit
          ? visibleText
          : '${visibleText.substring(0, visibleLimit).trimRight()}…',
  };
}
