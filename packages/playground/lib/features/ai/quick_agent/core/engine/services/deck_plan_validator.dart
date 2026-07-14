import '../../../../../../core/domain/design/presentation_typography_catalog.dart';
import '../schemas/outline_schema.dart';
import 'deck_generation_request.dart';
import 'design_quality_metrics.dart';
import 'generation_validation_issue.dart';
import 'source_grounding.dart';

/// Returns semantic errors that are not expressible in the deck-plan schema.
List<String> validateDeckPlan(
  DeckPlanType plan, {
  int? expectedSlideCount,
  PresentationTypographyCatalog? typographyCatalog,
  DeckGenerationRequest? request,
}) => validateDeckPlanIssues(
  plan,
  expectedSlideCount: expectedSlideCount,
  typographyCatalog: typographyCatalog,
  request: request,
).messages;

/// Returns typed semantic issues for pipeline decisions and diagnostics.
List<GenerationValidationIssue> validateDeckPlanIssues(
  DeckPlanType plan, {
  int? expectedSlideCount,
  PresentationTypographyCatalog? typographyCatalog,
  DeckGenerationRequest? request,
}) {
  final issues = GenerationValidationCollector();
  final usedKeys = <String>{};
  final catalog =
      typographyCatalog ?? PresentationTypographyCatalog.withDefaults();
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
  _validateTypography(
    plan,
    catalog,
    request,
    issues.scoped(code: GenerationValidationCode.typography),
  );
  _validatePalette(
    plan,
    request,
    issues.scoped(
      code: GenerationValidationCode.paletteContrast,
      category: GenerationValidationCategory.accessibility,
    ),
  );
  _validateElementGrounding(
    plan,
    request,
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
    ),
  );
  _validateNumericClaimContext(
    plan,
    request,
    issues.scoped(
      code: GenerationValidationCode.numericMeaning,
      category: GenerationValidationCategory.factual,
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
    issues.scoped(code: GenerationValidationCode.treatmentIntent),
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

void _validateMetricIntent(
  DeckPlanType plan,
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
  DeckPlanType plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  if (request == null) return;
  for (final slide in plan.slides) {
    final mismatches = findNumericContextMismatches(
      values: [
        slide.title,
        slide.purpose,
        slide.assertion,
        ...slide.contentUnits,
        slide.contentBrief,
        slide.continuity,
      ],
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
  DeckPlanType plan,
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
    errors.add(
      'Deck narrative introduces unsupported commitment claim(s): '
      '${narrativeUnsupported.join(', ')}. Remove them unless userIntent '
      'supplied the exact claim.',
    );
  }
  for (final slide in plan.slides) {
    final unsupported = findUnsupportedCommitmentPhrases(
      values: [
        slide.title,
        slide.purpose,
        slide.assertion,
        ...slide.contentUnits,
        slide.contentBrief,
        slide.continuity,
      ],
      userIntent: request.userIntent,
    );
    if (unsupported.isNotEmpty) {
      final slideErrors = errors.scoped(
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
  DeckPlanType plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  if (request == null) return;
  final groundedClaims = extractGroundedNumericClaims([request.userIntent]);
  for (final slide in plan.slides) {
    final ungrounded = findUnsupportedNumericClaims(
      values: [
        slide.title,
        slide.purpose,
        slide.assertion,
        ...slide.contentUnits,
        slide.contentBrief,
        slide.continuity,
      ],
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
  DeckPlanType plan,
  GenerationValidationCollector errors,
) {
  for (final slide in plan.slides) {
    final allowed = switch (slide.treatment) {
      'hero' => const {'title'},
      'section' => const {'title', 'titleLeft'},
      'quote' => const {'quote'},
      'closing' => const {'title', 'titleLeft', 'quote', 'qrcode'},
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
  DeckPlanType plan,
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
      slide.title,
      slide.purpose,
      slide.assertion,
      ...slide.contentUnits,
      slide.contentBrief,
      slide.continuity,
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

void _validateSections(
  DeckPlanType plan,
  GenerationValidationCollector errors,
) {
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

void _validateTypography(
  DeckPlanType plan,
  PresentationTypographyCatalog catalog,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  final headline = catalog.resolve(plan.style.fonts.headline);
  final body = catalog.resolve(plan.style.fonts.body);
  if (headline == null ||
      !headline.roles.contains(PresentationFontRole.headline)) {
    errors.add(
      'Headline font "${plan.style.fonts.headline}" is not registered for '
      'headline use.',
    );
  }
  if (body == null || !body.roles.contains(PresentationFontRole.body)) {
    errors.add(
      'Body font "${plan.style.fonts.body}" is not registered for body use.',
    );
  }

  _validateRequestedFont(
    role: 'headline',
    requested: request?.headlineFont,
    planned: headline,
    catalog: catalog,
    errors: errors,
  );
  _validateRequestedFont(
    role: 'body',
    requested: request?.bodyFont,
    planned: body,
    catalog: catalog,
    errors: errors,
  );
}

void _validateRequestedFont({
  required String role,
  required String? requested,
  required PresentationFontDescriptor? planned,
  required PresentationTypographyCatalog catalog,
  required GenerationValidationCollector errors,
}) {
  if (requested == null) return;
  final expected = catalog.resolve(requested);
  if (expected == null) {
    errors.add('Requested $role font "$requested" is not registered.');
    return;
  }
  if (planned != expected) {
    errors.add(
      'Deck plan changed the requested $role font from '
      '"${expected.family}" to "${planned?.family ?? 'unknown'}".',
    );
  }
}

void _validatePalette(
  DeckPlanType plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  final colors = plan.style.colors;
  _requireContrast(
    foreground: colors.heading,
    background: colors.background,
    minimum: 3,
    label: 'Heading/background',
    errors: errors,
  );
  _requireContrast(
    foreground: colors.body,
    background: colors.background,
    minimum: 4.5,
    label: 'Body/background',
    errors: errors,
  );
  _requireContrast(
    foreground: colors.body,
    background: colors.surface,
    minimum: 4.5,
    label: 'Body/surface',
    errors: errors,
  );
  _requireContrast(
    foreground: colors.accentContrast,
    background: colors.accent,
    minimum: 4.5,
    label: 'Accent contrast',
    errors: errors,
  );

  final requested = request?.colors ?? const <String>[];
  final planned = [colors.background, colors.heading, colors.body];
  for (
    var index = 0;
    index < requested.length && index < planned.length;
    index++
  ) {
    if (requested[index].toUpperCase() != planned[index].toUpperCase()) {
      errors.add(
        'Deck plan changed requested color ${index + 1} from '
        '"${requested[index]}" to "${planned[index]}".',
      );
    }
  }
}

void _validateElementGrounding(
  DeckPlanType plan,
  DeckGenerationRequest? request,
  GenerationValidationCollector errors,
) {
  for (final slide in plan.slides) {
    final requiredType = switch (slide.composition) {
      'imageLeft' || 'imageRight' || 'imageFullBleed' => 'image',
      'qrcode' => 'qrcode',
      'webview' => 'webview',
      'dartpad' => 'dartpad',
      'custom' => 'custom',
      _ => null,
    };
    if (requiredType != null &&
        !(slide.elements ?? const <DeckPlanElementType>[]).any(
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
    for (final element in slide.elements ?? const <DeckPlanElementType>[]) {
      final source = element.source;
      if (source == null || source.trim().isEmpty) continue;
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
    type == 'qrcode' ||
    type == 'webview' ||
    type == 'dartpad' ||
    type == 'custom';

void _validateDesignRhythm(
  DeckPlanType plan,
  GenerationValidationCollector errors,
) {
  _rejectLongRuns(
    values: plan.slides.map((slide) => slide.composition).toList(),
    label: 'composition',
    errors: errors,
  );
  _rejectLongRuns(
    values: plan.slides.map((slide) => slide.treatment).toList(),
    label: 'treatment',
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

void _requireContrast({
  required String foreground,
  required String background,
  required double minimum,
  required String label,
  required GenerationValidationCollector errors,
}) {
  final ratio = calculateContrastRatio(foreground, background);
  if (ratio < minimum) {
    errors.add(
      '$label contrast is ${ratio.toStringAsFixed(2)}:1; '
      'expected at least ${minimum.toStringAsFixed(1)}:1.',
    );
  }
}

bool _sameOrder(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
