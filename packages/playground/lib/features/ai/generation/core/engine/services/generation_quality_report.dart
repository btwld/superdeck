import 'dart:math' as math;

import 'package:superdeck_core/superdeck_core.dart';

import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../../../core/domain/design/presentation_typography_catalog.dart';
import '../schemas/outline_schema.dart';
import 'deck_generation_request.dart';
import 'deck_plan_validator.dart';
import 'deck_theme_resolution.dart';
import 'design_quality_metrics.dart';
import 'generation_trace.dart';
import 'generation_validation_issue.dart';

/// One deterministic quality failure with a stable rule identifier.
final class GenerationQualityIssue {
  const GenerationQualityIssue({
    required this.rule,
    required this.message,
    this.slideKey,
    this.severity = GenerationValidationSeverity.blocking,
    this.sourceCode,
  });

  final String rule;
  final String message;
  final String? slideKey;
  final GenerationValidationSeverity severity;
  final GenerationValidationCode? sourceCode;

  Map<String, Object?> toJson() => {
    'rule': rule,
    if (slideKey != null) 'slideKey': slideKey,
    'severity': severity.name,
    if (sourceCode != null) 'sourceCode': sourceCode!.name,
    'message': message,
  };
}

/// Machine-readable quality evidence for one complete generation and capture.
final class GenerationQualityReport {
  final List<GenerationQualityIssue> issues;
  final Map<String, int> counts;
  final Map<String, int> compositionDistribution;
  final Map<String, int> treatmentDistribution;
  final Map<String, int> densityDistribution;
  final Map<String, int> modelRequests;
  final List<Map<String, Object?>> contentDensity;
  final Map<String, double> contrastRatios;
  final Map<String, int> plannedElements;
  final Map<String, int> generatedElements;
  final Map<String, Object?> fonts;
  final Map<String, Object?> theme;
  final int generationElapsedMs;
  final int captureElapsedMs;
  final int sectionCount;
  final int distinctCompositionCount;
  final int maxCompositionRun;
  final int maxTreatmentRun;

  const GenerationQualityReport._({
    required this.issues,
    required this.counts,
    required this.compositionDistribution,
    required this.treatmentDistribution,
    required this.densityDistribution,
    required this.modelRequests,
    required this.contentDensity,
    required this.contrastRatios,
    required this.plannedElements,
    required this.generatedElements,
    required this.fonts,
    required this.theme,
    required this.generationElapsedMs,
    required this.captureElapsedMs,
    required this.sectionCount,
    required this.distinctCompositionCount,
    required this.maxCompositionRun,
    required this.maxTreatmentRun,
  });

  factory GenerationQualityReport.evaluate({
    required DeckGenerationRequest request,
    required DeckPlan plan,
    required List<Slide> slides,
    required List<GenerationTraceEvent> traces,
    required int replayedSlideCount,
    required int capturedSlideCount,
    required Set<String> resolvedFontFamilies,
    PresentationThemeCatalog? themeCatalog,
    PresentationTypographyCatalog? typographyCatalog,
    Duration captureElapsed = Duration.zero,
    Set<String> knownGeneratedAssetKeys = const {},
  }) {
    final issues = <GenerationQualityIssue>[];
    final themes = themeCatalog ?? PresentationThemeCatalog.withDefaults();
    final typography =
        typographyCatalog ?? PresentationTypographyCatalog.withDefaults();
    ResolvedPresentationTheme? resolvedTheme;
    try {
      resolvedTheme = resolveDeckThemeReference(
        plan.theme,
        themeCatalog: themes,
        typographyCatalog: typography,
      );
    } catch (error) {
      issues.add(
        GenerationQualityIssue(
          rule: 'theme.resolution',
          message: error.toString(),
          severity: .blocking,
          sourceCode: .themeResolution,
        ),
      );
    }
    final counts = <String, int>{
      'requested': request.slideCount,
      'planned': plan.slides.length,
      'generated': slides.length,
      'replayed': replayedSlideCount,
      'captured': capturedSlideCount,
    };
    for (final entry in counts.entries) {
      if (entry.value != request.slideCount) {
        issues.add(
          GenerationQualityIssue(
            rule: 'count.${entry.key}',
            message:
                '${entry.key} slide count is ${entry.value}; expected '
                '${request.slideCount}.',
          ),
        );
      }
    }

    for (final issue in validateDeckPlanIssues(
      plan,
      typographyCatalog: typography,
      themeCatalog: themes,
      request: request,
      knownGeneratedAssetKeys: knownGeneratedAssetKeys,
    )) {
      issues.add(
        GenerationQualityIssue(
          rule: 'plan.${issue.code.name}',
          message: issue.message,
          slideKey: issue.slideKey,
          severity: issue.severity,
          sourceCode: issue.code,
        ),
      );
    }

    final planKeys = plan.slides.map((slide) => slide.key).toList();
    final generatedKeys = slides.map((slide) => slide.key).toList();
    if (!_sameOrder(planKeys, generatedKeys)) {
      issues.add(
        GenerationQualityIssue(
          rule: 'deck.slide_order',
          message:
              'Generated slide keys do not exactly match the planned order.',
        ),
      );
    }
    if (generatedKeys.toSet().length != generatedKeys.length) {
      issues.add(
        const GenerationQualityIssue(
          rule: 'deck.unique_keys',
          message: 'Generated slide keys are not unique.',
        ),
      );
    }

    final contentDensity = <Map<String, Object?>>[];
    for (final (index, slide) in slides.indexed) {
      final planSlide = index < plan.slides.length ? plan.slides[index] : null;
      final characters = countVisibleMarkdownCharacters([
        for (final section in slide.sections)
          for (final block in section.blocks)
            if (block case final ContentBlock content) content.content,
      ]);
      final density = planSlide?.density ?? plan.theme.density;
      final maximum = visibleCharacterLimit(
        density,
        composition: planSlide?.composition,
      );
      contentDensity.add({
        'slideKey': slide.key,
        'density': density,
        'visibleCharacters': characters,
        'maximumCharacters': maximum,
      });
      if (characters > maximum) {
        issues.add(
          GenerationQualityIssue(
            rule: 'slide.content_density',
            message:
                'Slide "${slide.key}" has $characters visible characters; '
                '$density allows at most $maximum.',
            slideKey: slide.key,
            severity:
                isHardContentDensityOverage(
                  visibleCharacters: characters,
                  characterLimit: maximum,
                )
                ? .blocking
                : .diagnostic,
          ),
        );
      }
      if (planSlide != null && slide.options?.style != planSlide.treatment) {
        final actualTreatment = slide.options?.style ?? '<none>';
        issues.add(
          GenerationQualityIssue(
            rule: 'slide.treatment',
            slideKey: slide.key,
            message:
                'Slide "${slide.key}" uses treatment '
                '"$actualTreatment"; expected '
                '"${planSlide.treatment}".',
          ),
        );
      }
    }

    final expectedFonts = {
      ?resolvedTheme?.headlineFamily,
      ?resolvedTheme?.bodyFamily,
    };
    for (final font in expectedFonts) {
      if (!resolvedFontFamilies.contains(font)) {
        final role = font == resolvedTheme?.headlineFamily
            ? 'headline'
            : 'body';
        issues.add(
          GenerationQualityIssue(
            rule: 'font.$role',
            message:
                'Selected $role font "$font" was not resolved for capture.',
          ),
        );
      }
    }

    final requestEvents = traces.where(
      (event) => event.kind == GenerationTraceKind.request,
    );
    final outlineRequests = requestEvents
        .where((event) => event.phase == GenerationTracePhase.outline)
        .length;
    final slideRequests = requestEvents
        .where((event) => event.phase == GenerationTracePhase.slide)
        .length;
    final outlineRepairRequests = requestEvents
        .where(
          (event) =>
              event.phase == GenerationTracePhase.outline && event.attempt > 1,
        )
        .length;
    final slideRepairRequests = requestEvents
        .where(
          (event) =>
              event.phase == GenerationTracePhase.slide && event.attempt > 1,
        )
        .length;
    final lastElapsed = traces.isEmpty
        ? Duration.zero
        : traces
              .map((event) => event.elapsed)
              .reduce((first, second) => first > second ? first : second);

    final compositions = plan.slides.map((slide) => slide.composition).toList();
    final treatments = plan.slides.map((slide) => slide.treatment).toList();
    final colors = resolvedTheme?.palette;
    final plannedElements = _distribution(
      plan.slides.expand(
        (slide) => slide.elements?.map((element) => element.type) ?? const [],
      ),
    );
    final generatedElements = _distribution(
      slides.expand(_generatedElementTypes),
    );
    if (!_sameDistribution(plannedElements, generatedElements)) {
      issues.add(
        GenerationQualityIssue(
          rule: 'deck.element_cardinality',
          message:
              'Generated element totals $generatedElements do not match '
              'planned totals $plannedElements.',
        ),
      );
    }

    return GenerationQualityReport._(
      issues: List.unmodifiable(issues),
      counts: Map.unmodifiable(counts),
      compositionDistribution: Map.unmodifiable(_distribution(compositions)),
      treatmentDistribution: Map.unmodifiable(_distribution(treatments)),
      densityDistribution: Map.unmodifiable(
        _distribution(plan.slides.map((slide) => slide.density)),
      ),
      modelRequests: Map.unmodifiable({
        'total': outlineRequests + slideRequests,
        'outline': outlineRequests,
        'slides': slideRequests,
        'outlineRepairs': outlineRepairRequests,
        'slideRepairs': slideRepairRequests,
        'repairs': outlineRepairRequests + slideRepairRequests,
      }),
      contentDensity: List.unmodifiable(contentDensity),
      contrastRatios: Map.unmodifiable({
        if (colors != null) ...{
          'headingOnBackground': calculateContrastRatio(
            colors.heading,
            colors.background,
          ),
          'bodyOnBackground': calculateContrastRatio(
            colors.body,
            colors.background,
          ),
          'bodyOnSurface': calculateContrastRatio(colors.body, colors.surface),
          'accentContrast': calculateContrastRatio(
            colors.accentContrast,
            colors.accent,
          ),
        },
      }),
      plannedElements: Map.unmodifiable(plannedElements),
      generatedElements: Map.unmodifiable(generatedElements),
      fonts: Map.unmodifiable({
        'headline': ?resolvedTheme?.headlineFamily,
        'body': ?resolvedTheme?.bodyFamily,
        'resolved': resolvedFontFamilies.toList()..sort(),
      }),
      theme: Map.unmodifiable({
        'id': plan.theme.id,
        'version': plan.theme.version,
        'density': plan.theme.density,
        'resolved': resolvedTheme != null,
      }),
      generationElapsedMs: lastElapsed.inMilliseconds,
      captureElapsedMs: captureElapsed.inMilliseconds,
      sectionCount: plan.sections.length,
      distinctCompositionCount: compositions.toSet().length,
      maxCompositionRun: _maxRun(compositions),
      maxTreatmentRun: _maxRun(treatments),
    );
  }

  bool get passed => issues.every((issue) => issue.severity != .blocking);

  Map<String, Object?> toJson() => {
    'passed': passed,
    'issues': issues.map((issue) => issue.toJson()).toList(),
    'counts': counts,
    'plan': {
      'sectionCount': sectionCount,
      'distinctCompositionCount': distinctCompositionCount,
      'maxCompositionRun': maxCompositionRun,
      'maxTreatmentRun': maxTreatmentRun,
    },
    'distributions': {
      'composition': compositionDistribution,
      'treatment': treatmentDistribution,
      'density': densityDistribution,
    },
    'contentDensity': contentDensity,
    'contrastRatios': contrastRatios.map(
      (key, value) => MapEntry(key, double.parse(value.toStringAsFixed(2))),
    ),
    'elements': {'planned': plannedElements, 'generated': generatedElements},
    'fonts': fonts,
    'theme': theme,
    'modelRequests': modelRequests,
    'timings': {
      'generationElapsedMs': generationElapsedMs,
      'captureElapsedMs': captureElapsedMs,
    },
  };
}

Map<String, int> _distribution(Iterable<String> values) {
  final result = <String, int>{};
  for (final value in values) {
    result.update(value, (count) => count + 1, ifAbsent: () => 1);
  }
  return result;
}

Iterable<String> _generatedElementTypes(Slide slide) sync* {
  for (final section in slide.sections) {
    for (final block in section.blocks) {
      if (block case final WidgetBlock widget) {
        yield switch (widget.name) {
          'image' || 'webview' || 'dartpad' => widget.name,
          _ => 'custom',
        };
      }
    }
  }
}

int _maxRun(List<String> values) {
  if (values.isEmpty) return 0;
  var maximum = 1;
  var current = 1;
  for (var index = 1; index < values.length; index++) {
    current = values[index] == values[index - 1] ? current + 1 : 1;
    maximum = math.max(maximum, current);
  }
  return maximum;
}

bool _sameOrder(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

bool _sameDistribution(Map<String, int> first, Map<String, int> second) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (second[entry.key] != entry.value) return false;
  }
  return true;
}
