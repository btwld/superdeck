import 'dart:convert';

import '../../../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../../../core/domain/design/presentation_typography_catalog.dart';
import '../schemas/outline_schema.dart';
import 'deck_generation_request.dart';
import 'deck_theme_resolution.dart';
import 'generation_validation_issue.dart';
import 'source_grounding.dart';
import 'theme_json_serializer.dart';

/// Returns semantic errors that are not expressible in the deck-plan schema.
List<String> validateDeckPlan(
  DeckPlan plan, {
  int? expectedSlideCount,
  PresentationTypographyCatalog? typographyCatalog,
  PresentationImageStyleCatalog? imageStyleCatalog,
  PresentationThemeCatalog? themeCatalog,
  DeckGenerationRequest? request,
  Set<String> knownGeneratedAssetKeys = const {},
}) => validateDeckPlanIssues(
  plan,
  expectedSlideCount: expectedSlideCount,
  typographyCatalog: typographyCatalog,
  imageStyleCatalog: imageStyleCatalog,
  themeCatalog: themeCatalog,
  request: request,
  knownGeneratedAssetKeys: knownGeneratedAssetKeys,
).messages;

/// Returns typed semantic issues for pipeline decisions and diagnostics.
List<GenerationValidationIssue> validateDeckPlanIssues(
  DeckPlan plan, {
  int? expectedSlideCount,
  PresentationTypographyCatalog? typographyCatalog,
  PresentationImageStyleCatalog? imageStyleCatalog,
  PresentationThemeCatalog? themeCatalog,
  DeckGenerationRequest? request,
  Set<String> knownGeneratedAssetKeys = const {},
}) {
  final issues = GenerationValidationCollector();
  final usedKeys = <String>{};
  final catalog =
      typographyCatalog ?? PresentationTypographyCatalog.withDefaults();
  final themes = themeCatalog ?? PresentationThemeCatalog.withDefaults();
  final imageStyles =
      imageStyleCatalog ?? PresentationImageStyleCatalog.withDefaults();
  final exactSlideCount = request?.slideCount ?? expectedSlideCount;

  if (exactSlideCount != null && plan.slides.length != exactSlideCount) {
    issues
        .scoped(code: GenerationValidationCode.slideCount)
        .add(
          'Deck plan has ${plan.slides.length} slides; '
          'expected exactly $exactSlideCount.',
        );
  }

  if (plan.slides.isEmpty) {
    issues
        .scoped(code: GenerationValidationCode.slideCount)
        .add('Deck plan has no slides.');
    return issues.issues.uniqueIssues;
  }

  for (final (index, slide) in plan.slides.indexed) {
    final slideIssues = issues.scoped(
      code: GenerationValidationCode.planStructure,
      location: GenerationValidationLocation.planSlide,
      slideKey: slide.key,
    );
    final key = slide.key.trim();
    if (key.isEmpty) {
      slideIssues.add('Slide ${index + 1} has an empty key.');
      continue;
    }
    if (!usedKeys.add(key)) {
      slideIssues.add('Duplicate slide key "$key".');
    }
    if (slide.assertion.trim().isEmpty) {
      slideIssues
          .scoped(locallyRepairable: true)
          .add('Slide "$key" has an empty assertion.');
    }
    if (slide.contentUnits.isEmpty ||
        slide.contentUnits.every((unit) => unit.trim().isEmpty)) {
      slideIssues
          .scoped(locallyRepairable: true)
          .add('Slide "$key" has no concrete content units.');
    }
  }

  _validateSections(
    plan,
    issues.scoped(code: GenerationValidationCode.planStructure),
  );
  _validateTheme(
    plan,
    themes,
    catalog,
    request,
    issues.scoped(code: .themeResolution, category: .structure),
  );
  _validateElementGrounding(
    plan,
    request,
    knownGeneratedAssetKeys,
    issues.scoped(
      code: GenerationValidationCode.elementGrounding,
      category: GenerationValidationCategory.grounding,
    ),
  );
  _validateGeneratedImageIntent(
    plan,
    request,
    imageStyles,
    issues.scoped(
      code: GenerationValidationCode.elementGrounding,
      category: GenerationValidationCategory.grounding,
    ),
  );
  _validateVisibleSourceGrounding(
    plan,
    request,
    issues.scoped(
      code: GenerationValidationCode.visibleSourceGrounding,
      category: GenerationValidationCategory.grounding,
    ),
  );
  _validateNumericClaimGrounding(
    plan,
    request,
    issues.scoped(
      code: GenerationValidationCode.numericGrounding,
      category: GenerationValidationCategory.factual,
      severity: GenerationValidationSeverity.diagnostic,
    ),
  );
  _validateNumericClaimContext(
    plan,
    request,
    issues.scoped(
      code: GenerationValidationCode.numericMeaning,
      category: GenerationValidationCategory.factual,
      severity: GenerationValidationSeverity.diagnostic,
    ),
  );
  _validateMetricIntent(
    plan,
    request,
    issues.scoped(
      code: GenerationValidationCode.metricIntent,
      category: GenerationValidationCategory.factual,
    ),
  );
  _validateCommitmentGrounding(
    plan,
    request,
    issues.scoped(
      code: GenerationValidationCode.commitmentGrounding,
      category: GenerationValidationCategory.factual,
    ),
  );
  _validateTreatmentIntent(
    plan,
    issues.scoped(
      code: GenerationValidationCode.treatmentIntent,
      category: GenerationValidationCategory.quality,
      severity: GenerationValidationSeverity.diagnostic,
    ),
  );
  _validateDesignRhythm(
    plan,
    issues.scoped(
      code: GenerationValidationCode.designRhythm,
      category: GenerationValidationCategory.quality,
      severity: GenerationValidationSeverity.diagnostic,
    ),
  );

  return issues.issues.uniqueIssues;
}

void _validateGeneratedImageIntent(
  DeckPlan plan,
  DeckGenerationRequest? request,
  PresentationImageStyleCatalog imageStyleCatalog,
  GenerationValidationCollector errors,
) {
  var generatedImageCount = 0;
  final hasImageStyle = _hasResolvedImageStyle(
    request,
    imageStyleCatalog,
    errors,
  );

  for (final slide in plan.slides) {
    final slideErrors = errors.scoped(
      location: GenerationValidationLocation.planSlide,
      slideKey: slide.key,
    );
    final elements = slide.elements ?? const <DeckPlanElement>[];
    final imageCount = elements
        .where((element) => element.type == 'image')
        .length;
    if (imageCount > 1) {
      slideErrors.add(
        'Slide "${slide.key}" plans $imageCount image elements; '
        'image compositions support one.',
      );
    }

    for (final element in elements) {
      final source = element.source?.trim();
      final prompt = element.generationPrompt?.trim();
      final hasSource = source != null && source.isNotEmpty;
      final hasPrompt = prompt != null && prompt.isNotEmpty;

      if (element.type != 'image') {
        if (hasPrompt) {
          slideErrors.add(
            'Slide "${slide.key}" uses generationPrompt on non-image '
            'element type "${element.type}".',
          );
        }
        continue;
      }

      if (hasSource == hasPrompt) {
        slideErrors.add(
          'Slide "${slide.key}" image element must provide exactly one of '
          'source or generationPrompt.',
        );
        continue;
      }
      if (!hasPrompt) continue;

      generatedImageCount++;
      if (!hasImageStyle) {
        slideErrors.add(
          'Slide "${slide.key}" requests a generated image without an exact '
          'image-style reference.',
        );
      }
    }
  }

  final budget = request?.maxGeneratedImages ?? 0;
  if (generatedImageCount > budget) {
    errors.add(
      'Deck plan requests $generatedImageCount generated images; the configured '
      'maximum is $budget.',
    );
  }
}

bool _hasResolvedImageStyle(
  DeckGenerationRequest? request,
  PresentationImageStyleCatalog imageStyleCatalog,
  GenerationValidationCollector errors,
) {
  if (request == null ||
      (request.imageStyleId == null && request.imageStyleVersion == null)) {
    return false;
  }
  try {
    request.resolveImageStyle(imageStyleCatalog);
    return true;
  } on ArgumentError catch (error) {
    errors.add(
      error
          .toString()
          .replaceFirst('Invalid argument(s): ', '')
          .replaceFirst('Invalid argument: ', ''),
    );

    return false;
  }
}

void _validateMetricIntent(
  DeckPlan plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  if (request == null) return;
  for (final slide in plan.slides) {
    if (slide.composition != 'metric') continue;
    final metrics = extractAudienceNumericClaims([
      slide.title,
      slide.assertion,
      ...slide.contentUnits,
      slide.contentBrief,
    ]);
    if (metrics.isEmpty) {
      final slideErrors = errors.scoped(
        location: GenerationValidationLocation.planSlide,
        slideKey: slide.key,
        locallyRepairable: true,
      );
      slideErrors.add(
        'Slide "${slide.key}" selects composition "metric" without an '
        'explicit audience-facing numeric fact. Put the exact grounded value '
        'and what it measures in contentUnits, or choose a non-metric '
        'composition.',
      );
    }
  }
}

void _validateNumericClaimContext(
  DeckPlan plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  if (request == null) return;
  for (final slide in plan.slides) {
    final mismatches = findNumericContextMismatches(
      values: _audienceFacingPlanCopy(slide),
      userIntent: request.userIntent,
      allowSlideContextFallback: true,
    );
    if (mismatches.isNotEmpty) {
      final slideErrors = errors.scoped(
        location: GenerationValidationLocation.planSlide,
        slideKey: slide.key,
        locallyRepairable: true,
      );
      slideErrors.add(
        'Slide "${slide.key}" changes the supplied meaning of numeric '
        'claim(s) ${mismatches.join(', ')}. Preserve each claim\'s original '
        'unit, comparison, and subject.',
      );
    }
  }
}

void _validateCommitmentGrounding(
  DeckPlan plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  if (request == null) return;
  final narrativeUnsupported = findUnsupportedCommitmentPhrases(
    values: [
      plan.topic,
      plan.story,
      for (final section in plan.sections) ...[
        section.title,
        section.purpose,
        section.transition,
      ],
    ],
    userIntent: request.userIntent,
    inspectMetricCausality: false,
  );
  if (narrativeUnsupported.isNotEmpty) {
    errors
        .scoped(
          severity: hasBlockingCommitmentClaim(narrativeUnsupported)
              ? .blocking
              : GenerationValidationSeverity.diagnostic,
        )
        .add(
          'Deck narrative introduces unsupported commitment claim(s): '
          '${narrativeUnsupported.join(', ')}. Remove them unless userIntent '
          'supplied the exact claim.',
        );
  }
  for (final slide in plan.slides) {
    final unsupported = findUnsupportedCommitmentPhrases(
      values: _audienceFacingPlanCopy(slide),
      userIntent: request.userIntent,
    );
    if (unsupported.isNotEmpty) {
      final slideErrors = errors.scoped(
        severity: hasBlockingCommitmentClaim(unsupported)
            ? .blocking
            : GenerationValidationSeverity.diagnostic,
        location: GenerationValidationLocation.planSlide,
        slideKey: slide.key,
        locallyRepairable: true,
      );
      slideErrors.add(
        'Slide "${slide.key}" introduces unsupported commitment claim(s): '
        '${unsupported.join(', ')}. Remove them unless userIntent supplied '
        'the exact claim.',
      );
    }
  }
}

void _validateNumericClaimGrounding(
  DeckPlan plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  if (request == null) return;
  final groundedClaims = extractGroundedNumericClaims([request.userIntent]);
  for (final slide in plan.slides) {
    final ungrounded = findUnsupportedNumericClaims(
      values: _audienceFacingPlanCopy(slide),
      groundedClaims: groundedClaims,
    );
    if (ungrounded.isNotEmpty) {
      final slideErrors = errors.scoped(
        location: GenerationValidationLocation.planSlide,
        slideKey: slide.key,
        locallyRepairable: true,
      );
      slideErrors.add(
        'Slide "${slide.key}" uses numeric claim(s) '
        '${ungrounded.join(', ')} that are not present in userIntent. '
        '${unsupportedNumericClaimRepairGuidance(ungrounded)}',
      );
    }
  }
}

void _validateTreatmentIntent(
  DeckPlan plan,
  GenerationValidationCollector errors,
) {
  for (final slide in plan.slides) {
    final allowed = switch (slide.treatment) {
      'hero' => const {'title'},
      'section' => const {'title', 'titleLeft'},
      'quote' => const {'quote'},
      'closing' => const {'title', 'titleLeft', 'quote'},
      'data' => const {'metric', 'table', 'twoColumn', 'threeColumn'},
      _ => null,
    };
    if (allowed != null && !allowed.contains(slide.composition)) {
      final slideErrors = errors.scoped(
        location: GenerationValidationLocation.planSlide,
        slideKey: slide.key,
      );
      slideErrors.add(
        'Slide "${slide.key}" pairs treatment "${slide.treatment}" with '
        'composition "${slide.composition}"; allowed compositions are '
        '${allowed.join(', ')}.',
      );
    }
  }
}

void _validateVisibleSourceGrounding(
  DeckPlan plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  if (request == null) return;
  final allowedDomains = extractReferencedDomains([
    request.userIntent,
    for (final element in request.groundedElements) element.source,
  ]);
  for (final slide in plan.slides) {
    final slideErrors = errors.scoped(
      location: GenerationValidationLocation.planSlide,
      slideKey: slide.key,
      locallyRepairable: true,
    );
    final referencedDomains = extractReferencedDomains([
      ..._audienceFacingPlanCopy(slide),
    ]);
    for (final domain in referencedDomains.difference(allowedDomains)) {
      slideErrors.add(
        'Slide "${slide.key}" introduces ungrounded visible domain '
        '"$domain". Use only domains supplied in userIntent or '
        'groundedElements.',
      );
    }
  }
}

List<String> _audienceFacingPlanCopy(DeckPlanSlide slide) => [
  slide.title,
  slide.assertion,
  ...slide.contentUnits,
];

void _validateSections(DeckPlan plan, GenerationValidationCollector errors) {
  if (plan.sections.isEmpty) {
    errors.add('Deck plan has no narrative sections.');
    return;
  }

  final planKeys = plan.slides.map((slide) => slide.key).toList();
  final knownPlanKeys = planKeys.toSet();
  final sectionKeys = <String>{};
  final membership = <String>[];

  for (final section in plan.sections) {
    if (!sectionKeys.add(section.key)) {
      errors.add('Duplicate deck section key "${section.key}".');
    }
    if (section.slideKeys.isEmpty) {
      errors.add('Deck section "${section.key}" has no slides.');
    }
    for (final slideKey in section.slideKeys) {
      if (!knownPlanKeys.contains(slideKey)) {
        errors.add(
          'Deck section "${section.key}" references unknown slide "$slideKey".',
        );
      }
      if (membership.contains(slideKey)) {
        errors.add('Slide "$slideKey" belongs to more than one section.');
      }
      membership.add(slideKey);
    }
  }

  if (!_sameOrder(membership, planKeys)) {
    errors.add(
      'Section slideKeys must partition all deck slides in presentation order.',
    );
  }

  final sectionBySlide = <String, String>{
    for (final section in plan.sections)
      for (final slideKey in section.slideKeys) slideKey: section.key,
  };
  for (final slide in plan.slides) {
    final expectedSection = sectionBySlide[slide.key];
    if (expectedSection != null && slide.sectionKey != expectedSection) {
      errors.add(
        'Slide "${slide.key}" declares section "${slide.sectionKey}"; '
        'expected "$expectedSection".',
      );
    }
  }
}

void _validateTheme(
  DeckPlan plan,
  PresentationThemeCatalog themeCatalog,
  PresentationTypographyCatalog typographyCatalog,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  try {
    final resolved = resolveDeckThemeReference(
      plan.theme,
      themeCatalog: themeCatalog,
      typographyCatalog: typographyCatalog,
    );
    if (request == null) return;
    if (request.themeId case final explicitTheme?
        when explicitTheme != plan.theme.id) {
      errors.add(
        'Deck plan changed requested theme "$explicitTheme" to '
        '"${plan.theme.id}".',
      );
    }
    final expected = buildDeckThemeReference(
      descriptor: resolved.descriptor,
      request: request,
      typographyCatalog: typographyCatalog,
    );
    resolveDeckThemeMap(
      expected,
      themeCatalog: themeCatalog,
      typographyCatalog: typographyCatalog,
    );
    final actual = serializeDeckThemeReference(plan.theme);
    if (jsonEncode(actual) != jsonEncode(expected)) {
      errors.add(
        'Deck theme reference does not exactly preserve the requested '
        'density, palette, and typography overrides.',
      );
    }
  } catch (error) {
    errors.add(
      error
          .toString()
          .replaceFirst('Invalid argument(s): ', '')
          .replaceFirst('Invalid argument: ', ''),
    );
  }
}

void _validateElementGrounding(
  DeckPlan plan,
  DeckGenerationRequest? request,
  Set<String> knownGeneratedAssetKeys,
  GenerationValidationCollector errors,
) {
  for (final slide in plan.slides) {
    final requiredType = switch (slide.composition) {
      'imageLeft' || 'imageRight' || 'imageFullBleed' => 'image',
      'webview' => 'webview',
      'dartpad' => 'dartpad',
      'custom' => 'custom',
      _ => null,
    };
    if (requiredType != null &&
        !(slide.elements ?? const <DeckPlanElement>[]).any(
          (element) => element.type == requiredType,
        )) {
      final slideErrors = errors.scoped(
        location: GenerationValidationLocation.planSlide,
        slideKey: slide.key,
      );
      slideErrors.add(
        'Slide "${slide.key}" uses composition "${slide.composition}" but '
        'does not plan the required $requiredType element.',
      );
    }
  }

  if (request == null) return;
  final structuredSources = request.groundedElements
      .map((element) => element.source)
      .toSet();
  for (final slide in plan.slides) {
    final slideErrors = errors.scoped(
      location: GenerationValidationLocation.planSlide,
      slideKey: slide.key,
    );
    for (final element in slide.elements ?? const <DeckPlanElement>[]) {
      final source = element.source;
      if (source == null || source.trim().isEmpty) continue;
      if (knownGeneratedAssetKeys.contains(source)) continue;
      if (!structuredSources.contains(source) &&
          !request.userIntent.contains(source)) {
        slideErrors.add(
          'Slide "${slide.key}" uses ungrounded ${element.type} source '
          '"$source".',
        );
      }
      GroundedGenerationElement? groundedElement;
      for (final candidate in request.groundedElements) {
        if (candidate.type == element.type &&
            candidate.source == source &&
            candidate.widgetName == element.widgetName) {
          groundedElement = candidate;
          break;
        }
      }
      if (groundedElement == null) continue;
      if (element.purpose.trim() != groundedElement.purpose.trim()) {
        slideErrors.add(
          'Slide "${slide.key}" changes the supplied ${element.type} purpose. '
          'Copy it exactly as "${groundedElement.purpose}".',
        );
      }
      if (!_isAudienceHandoffElement(element.type)) continue;
      final missingTerms = findMissingGroundedPurposeTerms(
        purpose: groundedElement.purpose,
        values: [
          slide.title,
          slide.purpose,
          slide.assertion,
          ...slide.contentUnits,
          slide.contentBrief,
          slide.continuity,
        ],
      );
      if (missingTerms.isNotEmpty) {
        slideErrors
            .scoped(
              code: GenerationValidationCode.handoffPurpose,
              locallyRepairable: true,
            )
            .add(
              'Slide "${slide.key}" ${element.type} handoff omits grounded '
              'purpose term(s): ${missingTerms.join(', ')}. Preserve the supplied '
              'destination or experience identity in audience-facing copy.',
            );
      }
    }
  }
}

bool _isAudienceHandoffElement(String type) =>
    type == 'webview' || type == 'dartpad' || type == 'custom';

void _validateDesignRhythm(
  DeckPlan plan,
  GenerationValidationCollector errors,
) {
  _rejectLongRuns(
    values: plan.slides.map((slide) => slide.composition).toList(),
    label: 'composition',
    errors: errors,
  );

  final requiredFamilies = switch (plan.slides.length) {
    >= 20 => 7,
    >= 15 => 6,
    >= 10 => 5,
    _ => 0,
  };
  final actualFamilies = plan.slides
      .map((slide) => slide.composition)
      .toSet()
      .length;
  if (actualFamilies < requiredFamilies) {
    errors.add(
      '${plan.slides.length}-slide plan uses $actualFamilies composition '
      'families; expected at least $requiredFamilies.',
    );
  }
}

void _rejectLongRuns({
  required List<String> values,
  required String label,
  required GenerationValidationCollector errors,
}) {
  var run = 1;
  for (var index = 1; index < values.length; index++) {
    run = values[index] == values[index - 1] ? run + 1 : 1;
    if (run == 4) {
      errors.add(
        'Deck plan repeats $label "${values[index]}" '
        'more than three times consecutively.',
      );
    }
  }
}

bool _sameOrder(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
