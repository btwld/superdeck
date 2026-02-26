part of 'deck_generator_service.dart';

void _logPipelineConfig(
  DeckGeneratorService owner, {
  required String prompt,
  required String? imageStyleId,
  required String? backgroundColor,
}) {
  debugLog.section('Deck Generation Pipeline');
  debugLog.log(
    'DECK_GEN',
    'Config: outlineModel=${owner.outlineModelName}, '
        'deckModel=${owner.modelName}, '
        'thinkingBudget=${owner.thinkingBudget}, '
        'imageStyle=$imageStyleId, bgColor=$backgroundColor',
  );
  debugLog.log('DECK_GEN', 'Prompt (${prompt.length} chars):\n$prompt');
}

Future<Map<String, dynamic>?> _runOutlinePhase(
  DeckGeneratorService owner, {
  required google_ai.GenerativeService service,
  required String prompt,
  required GenerationProgressCallback? onProgress,
}) async {
  debugLog.section('Phase 1: Generate Outline');
  onProgress?.call(GenerationPhase.generatingOutline, null);
  final outlineStart = DateTime.now();
  final outline = await owner._generateOutline(service, prompt);
  final outlineMs = DateTime.now().difference(outlineStart).inMilliseconds;

  if (outline == null) {
    debugLog.error(
      'DECK_GEN',
      'Phase 1 FAILED after ${outlineMs}ms - no outline returned',
    );
    return null;
  }

  final outlineSlides = (outline['slides'] as List?)?.length ?? 0;
  debugLog.log(
    'DECK_GEN',
    'Phase 1 COMPLETE in ${outlineMs}ms - '
        'topic: "${outline['topic']}", slides: $outlineSlides',
  );
  return outline;
}

Future<_ImagePhaseData> _runImagePhase(
  DeckGeneratorService owner, {
  required Map<String, dynamic> outline,
  required String? imageStyleId,
  required String? backgroundColor,
  required GenerationProgressCallback? onProgress,
}) async {
  debugLog.section('Phase 2: Generate Images');
  final imageRequirements = owner._extractImageRequirements(outline);
  debugLog.log(
    'DECK_GEN',
    'Extracted ${imageRequirements.length} image requirements: '
        '${imageRequirements.map((r) => '${r.slideKey} → "${r.subject}"').join(', ')}',
  );

  final availableImages = <String, String>{};
  Map<String, String>? imageFailures;

  if (imageRequirements.isNotEmpty && imageStyleId != null) {
    debugLog.log(
      'DECK_GEN',
      'Starting image generation: style=$imageStyleId, '
          'aspectRatio=3:4 (portrait), bgColor=$backgroundColor',
    );
    onProgress?.call(
      GenerationPhase.generatingImages,
      ImageGenerationProgress(completed: 0, total: imageRequirements.length),
    );

    final imageStart = DateTime.now();
    final results = await owner._generateImagesFromRequirements(
      imageRequirements,
      imageStyleId,
      backgroundColor: backgroundColor,
      onProgress: (completed, failed) => onProgress?.call(
        GenerationPhase.generatingImages,
        ImageGenerationProgress(
          completed: completed,
          total: imageRequirements.length,
          failed: failed,
        ),
      ),
    );
    final imageMs = DateTime.now().difference(imageStart).inMilliseconds;

    availableImages.addAll(results.successes);
    if (results.failures.isNotEmpty) {
      imageFailures = results.failures;
    }
    debugLog.log(
      'DECK_GEN',
      'Phase 2 COMPLETE in ${imageMs}ms - '
          '${results.successes.length} succeeded, '
          '${results.failures.length} failed',
    );
    for (final entry in results.successes.entries) {
      debugLog.log('DECK_GEN', '  OK: ${entry.key} → ${entry.value}');
    }
    for (final entry in results.failures.entries) {
      debugLog.log('DECK_GEN', '  FAIL: ${entry.key} → ${entry.value}');
    }
  } else {
    debugLog.log(
      'DECK_GEN',
      'Skipping image generation: '
          'requirements=${imageRequirements.length}, '
          'imageStyleId=$imageStyleId',
    );
  }

  return _ImagePhaseData(
    availableImages: availableImages,
    imageFailures: imageFailures,
  );
}

Future<Map<String, dynamic>?> _runFinalDeckPhase(
  DeckGeneratorService owner, {
  required google_ai.GenerativeService service,
  required String prompt,
  required Map<String, dynamic> outline,
  required Map<String, String> availableImages,
  required GenerationProgressCallback? onProgress,
}) async {
  debugLog.section('Phase 3: Generate Final Deck');
  debugLog.log('DECK_GEN', 'Available images for final deck: $availableImages');
  onProgress?.call(GenerationPhase.generatingFinalDeck, null);
  final deckStart = DateTime.now();
  final deckJson = await owner._generateFinalDeck(
    service,
    prompt,
    outline,
    availableImages,
  );
  final deckMs = DateTime.now().difference(deckStart).inMilliseconds;

  if (deckJson == null) {
    debugLog.error(
      'DECK_GEN',
      'Phase 3 FAILED after ${deckMs}ms - no deck JSON returned',
    );
    return null;
  }

  final deckSlides = (deckJson['slides'] as List?)?.length ?? 0;
  debugLog.log(
    'DECK_GEN',
    'Phase 3 COMPLETE in ${deckMs}ms - $deckSlides raw slides',
  );
  return deckJson;
}

Future<DeckGenerationResult> _finalizeDeck(
  DeckGeneratorService owner, {
  required Map<String, dynamic> deckJson,
  required Map<String, String> availableImages,
  required Map<String, String>? imageFailures,
  required DateTime pipelineStart,
  required GenerationProgressCallback? onProgress,
}) async {
  debugLog.section('Finalize');
  onProgress?.call(GenerationPhase.finalizing, null);

  final slides = _extractSlidesWithKeys(deckJson);

  debugLog.log('DECK_GEN', 'Pre-sanitize: ${slides.length} slides');
  final sanitizedSlides = _sanitizeSlides(slides);
  debugLog.log(
    'DECK_GEN',
    'Post-sanitize: ${sanitizedSlides.length} slides '
        '(${slides.length - sanitizedSlides.length} removed)',
  );

  if (sanitizedSlides.isEmpty) {
    debugLog.error('DECK_GEN', 'No slides survived sanitization');
    return DeckGenerationResult.failure('No slides generated');
  }

  final styleData = _extractStyleData(deckJson);
  final deck = {
    'slides': sanitizedSlides,
    if (styleData.styleJson case final styleJson?) 'style': styleJson,
  };

  await owner._ensureDirectoriesExist();

  final file = File(Paths.deckJsonPath);
  final jsonString = const JsonEncoder.withIndent('  ').convert(deck);
  await file.writeAsString(jsonString);
  debugLog.log(
    'DECK_GEN',
    'Wrote deck to ${file.path} (${jsonString.length} chars)',
  );

  await _cleanupStaleAssets(sanitizedSlides);

  final totalMs = DateTime.now().difference(pipelineStart).inMilliseconds;
  debugLog.log(
    'DECK_GEN',
    'Pipeline COMPLETE in ${totalMs}ms - '
        '${sanitizedSlides.length} slides, '
        '${availableImages.length} images',
  );

  return DeckGenerationResult.success(
    path: file.absolute.path,
    slideCount: sanitizedSlides.length,
    style: styleData.style,
    imageFailures: imageFailures,
  );
}

List<Map<String, dynamic>> _extractSlidesWithKeys(
  Map<String, dynamic> deckJson,
) {
  return (deckJson['slides'] as List?)?.asMap().entries.map((entry) {
        final index = entry.key;
        final slide = Map<String, dynamic>.from(entry.value as Map);
        final existingKey = slide['key']?.toString();
        if (existingKey == null || existingKey.isEmpty) {
          slide['key'] = generateSlideKey(slide, index);
          debugLog.log(
            'DECK_GEN',
            'Generated key for slide $index: ${slide['key']}',
          );
        }
        return slide;
      }).toList() ??
      [];
}

_StyleData _extractStyleData(Map<String, dynamic> deckJson) {
  final rawStyle = deckJson['style'];
  final style = DeckStyleType.safeParse(rawStyle).getOrNull();
  final styleJson = style != null ? serializeDeckStyleForJson(style) : null;
  debugLog.log(
    'DECK_GEN',
    'Style: ${style != null ? 'parsed OK' : 'invalid/omitted'} → $styleJson',
  );
  return _StyleData(style: style, styleJson: styleJson);
}
