import 'package:superdeck_core/superdeck_core.dart';

import '../schemas/outline_schema.dart';
import 'deck_generation_request.dart';
import 'deck_generator_pipeline_helpers.dart';
import 'design_quality_metrics.dart';
import 'generation_element_catalog.dart';
import 'generation_validation_issue.dart';
import 'source_grounding.dart';

/// Applies renderer-safe mechanical normalization without rewriting content.
///
/// Models occasionally introduce H1 while repairing another heading rule. The
/// planned treatment already determines whether H1 is legal, so demoting that
/// marker to H2 is deterministic and avoids spending another model request.
Map<String, dynamic> normalizeGeneratedSlideForPlan({
  required Map<String, dynamic> rawSlide,
  required DeckPlanSlideType planSlide,
}) {
  final normalized = Map<String, dynamic>.of(rawSlide);
  final rawOptions = rawSlide['options'];
  normalized['options'] = {
    if (rawOptions is Map) ...Map<String, dynamic>.from(rawOptions),
    'style': planSlide.treatment,
  };
  final rawSections = rawSlide['sections'];
  if (rawSections is! List) return normalized;
  normalized['sections'] = [
    for (final rawSection in rawSections)
      if (rawSection is Map)
        {
          ...Map<String, dynamic>.from(rawSection),
          if (rawSection['blocks'] case final List rawBlocks)
            'blocks': [
              for (final rawBlock in rawBlocks)
                if (rawBlock is Map)
                  _normalizeBlockForPlan(
                    Map<String, dynamic>.from(rawBlock),
                    planSlide,
                  )
                else
                  rawBlock,
            ],
        }
      else
        rawSection,
  ];

  return _normalizeImageSplitFlex(
    _normalizeImplicitVerticalAlignment(normalized, planSlide),
    planSlide,
  );
}

Map<String, dynamic> _normalizeImageSplitFlex(
  Map<String, dynamic> slide,
  DeckPlanSlideType planSlide,
) {
  if (planSlide.composition != 'imageLeft' &&
      planSlide.composition != 'imageRight') {
    return slide;
  }
  final sections = slide['sections'];
  if (sections is! List || sections.length != 1) return slide;
  final section = sections.single;
  if (section is! Map) return slide;
  final blocks = section['blocks'];
  if (blocks is! List || blocks.length != 2) return slide;
  final hasImage = blocks.whereType<Map>().any(
    (block) => block['type'] == WidgetBlock.key && block['name'] == 'image',
  );
  final hasContent = blocks.whereType<Map>().any(
    (block) => block['type'] == ContentBlock.key,
  );
  if (!hasImage || !hasContent) return slide;
  for (final block in blocks.whereType<Map>()) {
    block['flex'] = 1;
  }
  return slide;
}

Map<String, dynamic> _normalizeBlockForPlan(
  Map<String, dynamic> block,
  DeckPlanSlideType planSlide,
) {
  var normalized = _planPermitsH1(planSlide)
      ? block
      : _normalizeBlockHeading(block);
  if (planSlide.composition == 'title') {
    normalized = _flattenTitleListMarkers(normalized);
  }

  return normalized;
}

Map<String, dynamic> _flattenTitleListMarkers(Map<String, dynamic> block) {
  if (block['type'] != ContentBlock.key || block['content'] is! String) {
    return block;
  }
  block['content'] = (block['content'] as String).replaceAllMapped(
    RegExp(r'^(\s*)(?:[-+*]|\d+[.)])\s+', multiLine: true),
    (match) => match.group(1)!,
  );
  return block;
}

/// Removes optional speaker comments whenever their content is invalid.
///
/// Speaker notes never affect the rendered slide contract. Dropping them is a
/// deterministic, loss-minimizing fallback that avoids discarding valid visible
/// content or asking a repair request to fix optional commentary alongside a
/// visible issue. The remaining visible errors are validated independently.
Map<String, dynamic> removeInvalidOptionalSpeakerComments({
  required Map<String, dynamic> rawSlide,
  required List<GenerationValidationIssue> validationIssues,
}) {
  if (validationIssues.isEmpty ||
      !validationIssues.any(
        (issue) =>
            issue.location == GenerationValidationLocation.speakerComments,
      )) {
    return rawSlide;
  }
  final comments = rawSlide['comments'];
  if (comments is! List || comments.isEmpty) return rawSlide;
  return {...rawSlide, 'comments': <String>[]};
}

Map<String, dynamic> _normalizeImplicitVerticalAlignment(
  Map<String, dynamic> slide,
  DeckPlanSlideType planSlide,
) {
  const supportedCompositions = {
    'content',
    'table',
    'twoColumn',
    'threeColumn',
  };
  if (!supportedCompositions.contains(planSlide.composition)) return slide;
  final sections = slide['sections'];
  if (sections is! List || sections.length != 2) return slide;
  final titleSection = sections.first;
  final bodySection = sections.last;
  if (titleSection is! Map || bodySection is! Map) return slide;
  final titleBlocks = titleSection['blocks'];
  final bodyBlocks = bodySection['blocks'];
  if (titleBlocks is! List || titleBlocks.length != 1 || bodyBlocks is! List) {
    return slide;
  }
  final titleBlock = titleBlocks.single;
  if (titleBlock is! Map ||
      titleBlock['type'] != ContentBlock.key ||
      titleBlock['content'] is! String ||
      !RegExp(
        r'^\s*#{1,2}\s+\S',
        multiLine: true,
      ).hasMatch(titleBlock['content'] as String)) {
    return slide;
  }
  final titleContent = titleBlock['content'] as String;
  final hasSupportingCopy = titleContent
      .split('\n')
      .any(
        (line) => line.trim().isNotEmpty && !line.trimLeft().startsWith('#'),
      );
  final titleFlex = titleSection['flex'];
  final bodyFlex = bodySection['flex'];
  if (hasSupportingCopy &&
      (titleFlex == null || titleFlex == 1) &&
      (bodyFlex == null || bodyFlex == 3)) {
    titleSection['flex'] = 1;
    bodySection['flex'] = 2;
  }
  titleBlock.putIfAbsent(
    'align',
    () => hasSupportingCopy ? 'topLeft' : 'bottomLeft',
  );
  for (final bodyBlock in bodyBlocks.whereType<Map>()) {
    if (bodyBlock['type'] == ContentBlock.key) {
      bodyBlock.putIfAbsent('align', () => 'topLeft');
    }
  }
  return slide;
}

Map<String, dynamic> _normalizeBlockHeading(Map<String, dynamic> block) {
  if (block['type'] != ContentBlock.key || block['content'] is! String) {
    return block;
  }
  final content = block['content'] as String;
  block['content'] = content
      .split('\n')
      .map(
        (line) => RegExp(r'^\s*#\s+\S').hasMatch(line)
            ? line.replaceFirstMapped(
                RegExp(r'^(\s*)#(\s+)'),
                (match) => '${match.group(1)!}##${match.group(2)!}',
              )
            : line,
      )
      .join('\n');
  return block;
}

/// Validates one generated slide before it becomes context for the next slide.
List<String> validateGeneratedSlide({
  required String expectedKey,
  required Map<String, dynamic> rawSlide,
  required GenerationElementCatalog elementCatalog,
  DeckPlanSlideType? planSlide,
  DeckGenerationRequest? request,
}) => validateGeneratedSlideIssues(
  expectedKey: expectedKey,
  rawSlide: rawSlide,
  elementCatalog: elementCatalog,
  planSlide: planSlide,
  request: request,
).messages;

/// Returns typed issues for one generated slide draft.
List<GenerationValidationIssue> validateGeneratedSlideIssues({
  required String expectedKey,
  required Map<String, dynamic> rawSlide,
  required GenerationElementCatalog elementCatalog,
  DeckPlanSlideType? planSlide,
  DeckGenerationRequest? request,
}) {
  final issues = GenerationValidationCollector(
    location: GenerationValidationLocation.visibleContent,
    slideKey: expectedKey,
  );
  if (rawSlide['key'] != expectedKey) {
    issues
        .scoped(code: GenerationValidationCode.slideIdentity)
        .add('Slide key must be exactly "$expectedKey".');
  }
  issues
      .scoped(code: GenerationValidationCode.slideStructure)
      .addAll(_validateRawDraftStructure(rawSlide));

  final sanitized = sanitizeGeneratedSlides([rawSlide]);
  if (sanitized.isEmpty) {
    issues
        .scoped(code: GenerationValidationCode.slideStructure)
        .add(
          'Slide must contain at least one usable section and content block.',
        );
    return issues.issues.uniqueIssues;
  }

  try {
    final slide = Slide.parse(Map<String, Object?>.from(sanitized.single));
    if (planSlide != null) {
      issues.issues.addAll(_validatePlanFulfillment(slide, planSlide, request));
    }
    for (final section in slide.sections) {
      for (final block in section.blocks) {
        if (block is WidgetBlock) {
          issues
              .scoped(code: GenerationValidationCode.widgetArguments)
              .addAll(elementCatalog.validate(block.name, block.args));
        } else if (block is ContentBlock) {
          issues
              .scoped(code: GenerationValidationCode.markdownContract)
              .addAll(_validateMarkdownSeparators(block.content));
          issues
              .scoped(code: GenerationValidationCode.markdownContract)
              .addAll(_validateMarkdownTables(block.content));
        }
      }
    }
  } catch (error) {
    issues
        .scoped(
          code: GenerationValidationCode.invalidSchema,
          category: GenerationValidationCategory.schema,
        )
        .add('Slide does not match the canonical contract: $error');
  }
  return issues.issues.uniqueIssues;
}

List<String> _validateRawDraftStructure(Map<String, dynamic> rawSlide) {
  final errors = <String>[];
  final rawSections = rawSlide['sections'];
  if (rawSections is! List) return errors;
  if (rawSections.length > 4) {
    errors.add(
      'Slide must contain at most 4 sections; found ${rawSections.length}.',
    );
  }

  for (final (sectionIndex, rawSection) in rawSections.indexed) {
    if (rawSection is! Map) continue;
    final rawBlocks = rawSection['blocks'];
    if (rawBlocks is! List) continue;
    if (rawBlocks.length > 3) {
      errors.add(
        'Section ${sectionIndex + 1} must contain at most 3 blocks; '
        'found ${rawBlocks.length}.',
      );
    }
    for (final (blockIndex, rawBlock) in rawBlocks.indexed) {
      if (rawBlock is! Map || rawBlock['type'] != ContentBlock.key) continue;
      final content = rawBlock['content'];
      if (content is! String || content.trim().isEmpty) {
        errors.add(
          'Content block in section ${sectionIndex + 1}, block '
          '${blockIndex + 1} must contain non-empty Markdown.',
        );
      }
    }
  }
  return errors;
}

List<GenerationValidationIssue> _validatePlanFulfillment(
  Slide slide,
  DeckPlanSlideType planSlide,
  DeckGenerationRequest? request,
) {
  final errors = GenerationValidationCollector(
    code: GenerationValidationCode.planFulfillment,
    location: GenerationValidationLocation.visibleContent,
    slideKey: planSlide.key,
  );
  final compositionGuidance = errors.scoped(
    category: GenerationValidationCategory.quality,
    severity: .diagnostic,
  );
  if (slide.sections.length > 2) {
    compositionGuidance.add(
      'Composition "${planSlide.composition}" supports at most 2 sections; '
      'found ${slide.sections.length}. Simplify the slide instead of stacking '
      'another content row.',
    );
  }
  if (planSlide.composition == 'title' && slide.sections.length != 1) {
    compositionGuidance.add(
      'Composition "title" must use exactly 1 section so the display heading '
      'has enough vertical room; found ${slide.sections.length}. Put the H1 '
      'and optional short support copy in one content block.',
    );
  }
  if (slide.options?.style != planSlide.treatment) {
    errors.add(
      'Slide style must be exactly the planned treatment '
      '"${planSlide.treatment}".',
    );
  }
  final contentBlocks = <ContentBlock>[];
  final widgetCounts = <String, int>{};
  for (final section in slide.sections) {
    for (final block in section.blocks) {
      switch (block) {
        case ContentBlock():
          contentBlocks.add(block);
        case WidgetBlock():
          widgetCounts.update(
            block.name,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
      }
    }
  }

  final expectedWidgetCounts = <String, int>{};
  for (final element in planSlide.elements ?? const <DeckPlanElementType>[]) {
    final name = element.type == 'custom' ? element.widgetName : element.type;
    if (name == null || name.trim().isEmpty) continue;
    expectedWidgetCounts.update(name, (count) => count + 1, ifAbsent: () => 1);
  }
  for (final entry in expectedWidgetCounts.entries) {
    final actual = widgetCounts[entry.key] ?? 0;
    if (actual != entry.value) {
      errors.add(
        'Expected exactly ${entry.value} "${entry.key}" widget; found $actual.',
      );
    }
  }
  for (final actualName in widgetCounts.keys) {
    if (!expectedWidgetCounts.containsKey(actualName)) {
      errors.add('Widget "$actualName" was not planned for this slide.');
    }
  }

  final markdown = contentBlocks.map((block) => block.content).join('\n\n');
  errors
      .scoped(
        code: GenerationValidationCode.handoffPurpose,
        category: GenerationValidationCategory.grounding,
      )
      .addAll(_validateHandoffPurpose(markdown, planSlide));
  errors
      .scoped(
        code: GenerationValidationCode.visibleSourceGrounding,
        category: GenerationValidationCategory.grounding,
      )
      .addAll(
        _validateVisibleSourceGrounding(
          [markdown],
          planSlide,
          label: 'Visible content',
        ),
      );
  errors
      .scoped(
        code: GenerationValidationCode.numericGrounding,
        category: GenerationValidationCategory.factual,
        severity: .diagnostic,
      )
      .addAll(
        _validateNumericClaimGrounding(
          [markdown],
          request,
          label: 'Visible content',
        ),
      );
  errors
      .scoped(
        code: GenerationValidationCode.numericMeaning,
        category: GenerationValidationCategory.factual,
        severity: .diagnostic,
      )
      .addAll(
        _validateNumericClaimContext(
          [markdown],
          request,
          label: 'Visible content',
        ),
      );
  final visibleCommitment = _validateCommitmentGrounding(
    [markdown],
    request,
    label: 'Visible content',
  );
  errors
      .scoped(
        code: GenerationValidationCode.commitmentGrounding,
        category: GenerationValidationCategory.factual,
        severity: visibleCommitment.severity,
      )
      .addAll(visibleCommitment.messages);
  if (slide.comments.isNotEmpty) {
    final commentErrors = errors.scoped(
      location: GenerationValidationLocation.speakerComments,
    );
    commentErrors
        .scoped(
          code: GenerationValidationCode.visibleSourceGrounding,
          category: GenerationValidationCategory.grounding,
        )
        .addAll(
          _validateVisibleSourceGrounding(
            slide.comments,
            planSlide,
            label: 'Speaker comments',
          ),
        );
    commentErrors
        .scoped(
          code: GenerationValidationCode.numericGrounding,
          category: GenerationValidationCategory.factual,
          severity: .diagnostic,
        )
        .addAll(
          _validateNumericClaimGrounding(
            slide.comments,
            request,
            label: 'Speaker comments',
          ),
        );
    commentErrors
        .scoped(
          code: GenerationValidationCode.numericMeaning,
          category: GenerationValidationCategory.factual,
          severity: .diagnostic,
        )
        .addAll(
          _validateNumericClaimContext(
            slide.comments,
            request,
            label: 'Speaker comments',
          ),
        );
    final commentCommitment = _validateCommitmentGrounding(
      slide.comments,
      request,
      label: 'Speaker comments',
    );
    commentErrors
        .scoped(
          code: GenerationValidationCode.commitmentGrounding,
          category: GenerationValidationCategory.factual,
          severity: commentCommitment.severity,
        )
        .addAll(commentCommitment.messages);
  }
  errors
      .scoped(
        code: GenerationValidationCode.contentDensity,
        category: GenerationValidationCategory.quality,
        severity: .diagnostic,
      )
      .addAll(
        _validateDisplayHeadings(
          contentBlocks,
          composition: planSlide.composition,
        ),
      );
  final visibleCharacters = countVisibleMarkdownCharacters(
    contentBlocks.map((block) => block.content),
  );
  final characterLimit = visibleCharacterLimit(
    planSlide.density,
    composition: planSlide.composition,
  );
  if (visibleCharacters > characterLimit) {
    errors
        .scoped(
          code: GenerationValidationCode.contentDensity,
          category: GenerationValidationCategory.quality,
          severity:
              isHardContentDensityOverage(
                visibleCharacters: visibleCharacters,
                characterLimit: characterLimit,
              )
              ? .blocking
              : .diagnostic,
        )
        .add(
          'Slide exceeds the ${planSlide.density} content budget of '
          '$characterLimit visible characters.',
        );
  }
  final composition = planSlide.composition;
  final hasTable = _containsMarkdownTable(markdown);
  final hasList = _containsMarkdownList(markdown);
  final hasBlockquote = RegExp(
    r'^\s*>\s*\S+',
    multiLine: true,
  ).hasMatch(markdown);
  if (composition == 'title' && (hasTable || hasList || hasBlockquote)) {
    compositionGuidance.add(
      'Composition "title" must stay minimal: use display headings and at '
      'most one short supporting paragraph, without lists, tables, or quotes.',
    );
  }
  if (composition != 'table' && hasTable) {
    compositionGuidance.add(
      'Markdown tables require composition "table"; the plan selected '
      '"$composition".',
    );
  }
  switch (composition) {
    case 'title':
    case 'imageFullBleed':
    case 'webview':
    case 'dartpad':
    case 'custom':
      break;
    case 'table':
      if (!hasTable) {
        compositionGuidance.add(
          'Composition "table" requires a Markdown table.',
        );
      }
    case 'twoColumn':
      if (!slide.sections.any((section) => section.blocks.length == 2)) {
        compositionGuidance.add(
          'Composition "twoColumn" requires a two-block section.',
        );
      }
      if (!_hasSubstantiveContent(contentBlocks)) {
        compositionGuidance.add(
          'Composition "twoColumn" requires substantive content beyond a title.',
        );
      }
    case 'threeColumn':
      if (!slide.sections.any((section) => section.blocks.length == 3)) {
        compositionGuidance.add(
          'Composition "threeColumn" requires a three-block section.',
        );
      }
      if (!_hasSubstantiveContent(contentBlocks)) {
        compositionGuidance.add(
          'Composition "threeColumn" requires substantive content beyond a title.',
        );
      }
    case 'quote':
      if (!RegExp(r'^\s*>\s*\S+', multiLine: true).hasMatch(markdown)) {
        compositionGuidance.add(
          'Composition "quote" requires a Markdown blockquote.',
        );
      }
    case 'metric':
      if (!RegExp(r'\d').hasMatch(markdown)) {
        compositionGuidance.add(
          'Composition "metric" requires at least one numeric value.',
        );
      }
    case 'imageLeft':
    case 'imageRight':
      if (!_hasSubstantiveContent(contentBlocks)) {
        compositionGuidance.add(
          'Composition "$composition" requires substantive text beside the image.',
        );
      }
    default:
      if (!_hasSubstantiveContent(contentBlocks)) {
        compositionGuidance.add(
          'Composition "$composition" requires substantive content beyond a title.',
        );
      }
  }
  return errors.issues.uniqueIssues;
}

List<String> _validateHandoffPurpose(
  String markdown,
  DeckPlanSlideType planSlide,
) {
  final errors = <String>[];
  for (final element in planSlide.elements ?? const <DeckPlanElementType>[]) {
    if (!_requiresVisibleHandoffPurpose(element.type)) continue;
    final missingTerms = findMissingGroundedPurposeTerms(
      purpose: element.purpose,
      values: [markdown],
    );
    if (missingTerms.isNotEmpty) {
      errors.add(
        'Visible ${element.type} handoff omits grounded purpose term(s): '
        '${missingTerms.join(', ')}. Preserve the supplied destination or '
        'experience identity.',
      );
    }
  }
  return errors;
}

bool _requiresVisibleHandoffPurpose(String type) =>
    type == 'webview' || type == 'dartpad' || type == 'custom';

List<String> _validateNumericClaimContext(
  Iterable<String> values,
  DeckGenerationRequest? request, {
  required String label,
}) {
  if (request == null) return const [];
  final mismatches = findNumericContextMismatches(
    values: values,
    userIntent: request.userIntent,
    allowSlideContextFallback: label == 'Visible content',
  );
  if (mismatches.isEmpty) return const [];
  final verb = label == 'Speaker comments' ? 'change' : 'changes';
  return [
    '$label $verb the supplied meaning of numeric claim(s) '
        '${mismatches.join(', ')}. Preserve each claim\'s original unit, '
        'comparison, and subject.',
  ];
}

({List<String> messages, GenerationValidationSeverity severity})
_validateCommitmentGrounding(
  Iterable<String> values,
  DeckGenerationRequest? request, {
  required String label,
}) {
  if (request == null) {
    return (
      messages: const [],
      severity: GenerationValidationSeverity.diagnostic,
    );
  }
  final unsupported = findUnsupportedCommitmentPhrases(
    values: values,
    userIntent: request.userIntent,
  );
  if (unsupported.isEmpty) {
    return (
      messages: const [],
      severity: GenerationValidationSeverity.diagnostic,
    );
  }
  final verb = label == 'Speaker comments' ? 'introduce' : 'introduces';

  return (
    messages: [
      '$label $verb unsupported commitment claim(s): '
          '${unsupported.join(', ')}. Remove them unless userIntent supplied '
          'the exact claim.',
    ],
    severity: hasBlockingCommitmentClaim(unsupported)
        ? GenerationValidationSeverity.blocking
        : GenerationValidationSeverity.diagnostic,
  );
}

List<String> _validateNumericClaimGrounding(
  Iterable<String> values,
  DeckGenerationRequest? request, {
  required String label,
}) {
  if (request == null) return const [];
  final groundedClaims = extractGroundedNumericClaims([request.userIntent]);
  final ungrounded = findUnsupportedNumericClaims(
    values: values,
    groundedClaims: groundedClaims,
  );
  if (ungrounded.isEmpty) return const [];
  final verb = label == 'Speaker comments' ? 'use' : 'uses';
  return [
    '$label $verb numeric claim(s) ${ungrounded.join(', ')} that are '
        'not present in userIntent. '
        '${unsupportedNumericClaimRepairGuidance(ungrounded)}',
  ];
}

List<String> _validateVisibleSourceGrounding(
  Iterable<String> values,
  DeckPlanSlideType planSlide, {
  required String label,
}) {
  final allowedDomains = extractReferencedDomains([
    planSlide.title,
    planSlide.purpose,
    planSlide.assertion,
    ...planSlide.contentUnits,
    planSlide.contentBrief,
    planSlide.continuity,
    for (final element in planSlide.elements ?? const <DeckPlanElementType>[])
      ?element.source,
  ]);
  final ungrounded = extractReferencedDomains([
    ...values,
  ]).difference(allowedDomains);
  final verb = label == 'Speaker comments' ? 'use' : 'uses';
  return [
    for (final domain in ungrounded)
      '$label $verb ungrounded domain "$domain". Use only a URL or '
          'domain supplied by the plan.',
  ];
}

List<String> _validateDisplayHeadings(
  List<ContentBlock> blocks, {
  required String composition,
}) {
  final errors = <String>[];
  final permitsH1 = _permitsH1(composition);
  for (final block in blocks) {
    for (final line in block.content.split('\n')) {
      final match = RegExp(r'^\s*(#{1,2})\s+(.+?)\s*$').firstMatch(line);
      if (match == null) continue;
      final level = match.group(1)!.length;
      final heading = match.group(2)!;
      final wordCount = RegExp(
        r"[\p{L}\p{N}]+(?:['’\-][\p{L}\p{N}]+)*",
        unicode: true,
      ).allMatches(heading).length;
      if (wordCount > 8) {
        errors.add(
          'Display heading "$heading" has $wordCount words; use at most 8.',
        );
      }
      if (level == 1 && !permitsH1) {
        errors.add(
          'H1 is reserved for title and numeric metric compositions; use H2 '
          'for the $composition composition.',
        );
      }
    }
  }
  return errors;
}

bool _planPermitsH1(DeckPlanSlideType planSlide) =>
    _permitsH1(planSlide.composition);

bool _permitsH1(String composition) =>
    composition == 'title' || composition == 'metric';

bool _hasSubstantiveContent(List<ContentBlock> blocks) {
  for (final block in blocks) {
    for (final line in block.content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || RegExp(r'^#{1,6}\s+\S').hasMatch(trimmed)) {
        continue;
      }
      if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(trimmed)) return true;
    }
  }
  return false;
}

bool _containsMarkdownTable(String markdown) {
  final lines = markdown.split('\n');
  for (var index = 0; index + 1 < lines.length; index++) {
    if (!lines[index].trim().startsWith('|')) continue;
    final separator = lines[index + 1].trim();
    if (RegExp(
      r'^\|?\s*:?-{3,}:?(\s*\|\s*:?-{3,}:?)+\s*\|?$',
    ).hasMatch(separator)) {
      return true;
    }
  }
  return false;
}

bool _containsMarkdownList(String markdown) => RegExp(
  r'^\s*(?:[-*+]\s+|\d+[.)]\s+)\S+',
  multiLine: true,
).hasMatch(markdown);

List<String> _validateMarkdownSeparators(String markdown) {
  String? openFence;
  for (final line in markdown.split('\n')) {
    final trimmed = line.trim();
    final fence = RegExp(r'^(`{3,}|~{3,})').firstMatch(trimmed)?.group(1);
    if (fence != null) {
      if (openFence == null) {
        openFence = fence;
      } else if (fence.startsWith(openFence.substring(0, 1)) &&
          fence.length >= openFence.length) {
        openFence = null;
      }
      continue;
    }
    if (openFence == null && trimmed == '---') {
      return const [
        'Standalone "---" is reserved for slide boundaries; remove the '
            'Markdown horizontal rule.',
      ];
    }
  }
  return const [];
}

List<String> _validateMarkdownTables(String markdown) {
  final lines = markdown.split('\n');
  final tableLines = lines
      .where((line) => line.trim().startsWith('|'))
      .toList();
  if (tableLines.isEmpty) return const [];
  if (tableLines.length < 3) {
    return const ['Markdown table must include a header, separator, and row.'];
  }

  int columnCount(String line) => line
      .trim()
      .substring(1, line.trim().endsWith('|') ? line.trim().length - 1 : null)
      .split('|')
      .length;

  final columns = columnCount(tableLines.first);
  final errors = <String>[];
  final separatorCells = tableLines[1]
      .split('|')
      .map((cell) => cell.trim())
      .where((cell) => cell.isNotEmpty);
  if (separatorCells.any((cell) => !RegExp(r'^:?-{3,}:?$').hasMatch(cell))) {
    errors.add('Markdown table separator row is invalid.');
  }
  if (columns > 4) {
    errors.add('Markdown table must use at most 4 columns for readability.');
  }
  if (tableLines.length - 2 > 6) {
    errors.add('Markdown table must use at most 6 body rows.');
  }
  if (tableLines.any((line) => columnCount(line) != columns)) {
    errors.add('Markdown table rows must have a consistent column count.');
  }
  return errors;
}
