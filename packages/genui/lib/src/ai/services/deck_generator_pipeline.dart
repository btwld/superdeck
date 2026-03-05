part of 'deck_generator_service.dart';

extension _DeckGeneratorPipeline on DeckGeneratorService {
  /// Generates a lightweight presentation outline.
  ///
  /// Returns the outline JSON or null on failure.
  Future<Map<String, dynamic>?> _generateOutline(
    google_ai.GenerativeService service,
    String prompt,
  ) async {
    final adapter = GoogleSchemaAdapter();
    final adaptResult = adapter.adapt(outlineSchema.toJsonSchemaBuilder());

    if (adaptResult.schema == null) {
      debugLog.error(
        'DECK_GEN',
        'Failed to adapt outline schema: ${adaptResult.errors}',
      );
      return null;
    }

    final systemPrompt = PromptRegistry.instance.render('outline_system');
    debugLog.log(
      'DECK_GEN',
      'Outline system prompt (${systemPrompt.length} chars)',
    );

    return _runJsonGeneration(
      service: service,
      modelName: outlineModelName,
      prompt: prompt,
      schema: adaptResult.schema!,
      systemPrompt: systemPrompt,
      phase: 'outline',
    );
  }

  /// Extracts image requirements from the outline.
  List<_ImageRequirement> _extractImageRequirements(
    Map<String, dynamic> outline,
  ) {
    final requirements = <_ImageRequirement>[];
    final slides = outline['slides'] as List?;
    if (slides == null) return requirements;

    for (final entry in slides.asMap().entries) {
      final sourceSlideIndex = entry.key;
      final slide = entry.value;
      if (slide is! Map) continue;

      final key = slide['key']?.toString();
      if (key == null || key.isEmpty) continue;

      final imageReq = slide['imageRequirement'] as Map?;
      if (imageReq == null) continue;

      final subject = imageReq['subject']?.toString();
      if (subject == null || subject.isEmpty) continue;

      requirements.add(
        _ImageRequirement(
          slideKey: key,
          subject: subject,
          sourceSlideIndex: sourceSlideIndex,
        ),
      );
    }

    return requirements.take(3).toList();
  }

  /// Generates images from outline requirements in parallel batches.
  Future<_ImageGenerationResults> _generateImagesFromRequirements(
    List<_ImageRequirement> requirements,
    String imageStyleId, {
    String? backgroundColor,
    void Function(int completed, int failed)? onProgress,
  }) async {
    final style = ImageStyle.fromId(imageStyleId);
    debugLog.log(
      'IMG',
      'Image style: ${style?.name ?? 'none'} (id=$imageStyleId)',
    );
    final successes = <String, String>{};
    final failures = <String, String>{};
    var completed = 0;
    var failed = 0;

    final assetsDir = Directory(Paths.superdeckAssetsPath);
    await assetsDir.create(recursive: true);

    // Portrait ratio for images displayed in their own column
    final imageService = ImageGeneratorService(
      apiKey: apiKey,
      aspectRatio: '3:4',
    );
    debugLog.log('IMG', 'ImageService: aspectRatio=3:4 (portrait)');

    // Process in batches of 3 to avoid rate limits
    const batchSize = 3;
    try {
      for (var i = 0; i < requirements.length; i += batchSize) {
        final batch = requirements.skip(i).take(batchSize).toList();
        debugLog.log(
          'IMG',
          'Processing batch ${i ~/ batchSize + 1}: '
              '${batch.map((r) => r.slideKey).join(', ')}',
        );

        await Future.wait(
          batch.map((req) async {
            final safeKey = _fileSafeKey(req.slideKey, req.sourceSlideIndex);
            final filename = 'slide-$safeKey-illustration.png';
            final outputPath = p.join(Paths.superdeckAssetsPath, filename);

            try {
              final basePrompt = style != null
                  ? style.buildPrompt(req.subject)
                  : req.subject;
              final prompt = ImageGeneratorService.buildPrompt(
                basePrompt,
                backgroundColor: backgroundColor,
              );
              debugLog.log(
                'IMG',
                '[${req.slideKey}] Generating with prompt '
                    '(${prompt.length} chars):\n$prompt',
              );

              final imgStart = DateTime.now();
              final result = await imageService.generateImage(prompt);
              final imgMs = DateTime.now().difference(imgStart).inMilliseconds;

              if (result.success && result.bytes != null) {
                final bytes = result.bytes as Uint8List;
                await File(outputPath).writeAsBytes(bytes, flush: true);
                successes[req.slideKey] = '.superdeck/assets/$filename';
                completed++;
                debugLog.log(
                  'IMG',
                  '[${req.slideKey}] OK in ${imgMs}ms - '
                      '${bytes.length} bytes → $outputPath',
                );
              } else {
                failures[req.slideKey] = result.error ?? 'Unknown error';
                failed++;
                debugLog.log(
                  'IMG',
                  '[${req.slideKey}] FAILED in ${imgMs}ms: ${result.error}',
                );
              }
            } catch (e, stack) {
              failures[req.slideKey] = e.toString();
              failed++;
              debugLog.error(
                'IMG',
                '[${req.slideKey}] EXCEPTION: ${e.runtimeType}',
                stack,
              );
            }

            onProgress?.call(completed, failed);
          }),
        );
      }
    } finally {
      imageService.dispose();
    }
    return _ImageGenerationResults(successes: successes, failures: failures);
  }

  /// Generates the final deck with available images context.
  Future<Map<String, dynamic>?> _generateFinalDeck(
    google_ai.GenerativeService service,
    String prompt,
    Map<String, dynamic> outline,
    Map<String, String> availableImages,
  ) async {
    final adapter = GoogleSchemaAdapter();
    final adaptResult = adapter.adapt(
      slideGenerationSchema.toJsonSchemaBuilder(),
    );

    if (adaptResult.schema == null) {
      debugLog.error(
        'DECK_GEN',
        'Failed to adapt deck schema: ${adaptResult.errors}',
      );
      return null;
    }

    final systemPrompt = _buildFinalDeckPrompt(outline, availableImages);
    debugLog.log(
      'DECK_GEN',
      'Final deck system prompt (${systemPrompt.length} chars)',
    );
    debugLog.log(
      'DECK_GEN',
      'Final deck thinking budget: ${thinkingBudget > 0 ? thinkingBudget : 'disabled'}',
    );

    return _runJsonGeneration(
      service: service,
      modelName: modelName,
      prompt: prompt,
      schema: adaptResult.schema!,
      systemPrompt: systemPrompt,
      phase: 'deck',
      thinkingConfig: thinkingBudget > 0
          ? google_ai.ThinkingConfig(thinkingBudget: thinkingBudget)
          : null,
      timeout: const Duration(minutes: 3),
    );
  }

  /// Builds the system prompt for Phase 3 with outline and available images.
  String _buildFinalDeckPrompt(
    Map<String, dynamic> outline,
    Map<String, String> availableImages,
  ) {
    final basePrompt = PromptRegistry.instance.render(
      'deck_system',
      input: {
        'examples': ExamplesLoader.instance.formatForPrompt(),
        'availableImages': buildAvailableImagesContext(availableImages),
      },
    );
    final fieldGuidance = getSlideGenerationGuidance();
    final outlineContext = _formatOutlineForPrompt(outline);

    return '''
$basePrompt

$fieldGuidance

## Presentation Outline (follow this structure)

$outlineContext
''';
  }

  /// Formats the outline as human-readable context for the final deck prompt.
  String _formatOutlineForPrompt(Map<String, dynamic> outline) {
    final slides = outline['slides'] as List?;
    if (slides == null || slides.isEmpty) {
      return 'No outline available.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Topic: ${outline['topic'] ?? 'Unknown'}');
    buffer.writeln('');

    for (final slide in slides) {
      if (slide is! Map) continue;
      buffer.writeln('- **${slide['key']}**: ${slide['title']}');
      buffer.writeln('  Layout: ${slide['layoutHint']}');
      buffer.writeln('  Purpose: ${slide['purpose']}');
      if (slide['imageRequirement'] case Map imageReq) {
        buffer.writeln('  Image: ${imageReq['subject']}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Future<Map<String, dynamic>?> _runJsonGeneration({
    required google_ai.GenerativeService service,
    required String modelName,
    required String prompt,
    required google_ai.Schema schema,
    required String systemPrompt,
    required String phase,
    google_ai.ThinkingConfig? thinkingConfig,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final request = google_ai.GenerateContentRequest(
      model: modelName,
      contents: [
        google_ai.Content(
          role: 'user',
          parts: [google_ai.Part(text: prompt)],
        ),
      ],
      generationConfig: google_ai.GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        thinkingConfig: thinkingConfig,
      ),
      systemInstruction: google_ai.Content(
        parts: [google_ai.Part(text: systemPrompt)],
      ),
    );

    debugLog.log('DECK_GEN', 'Sending $phase request to $modelName...');
    final response = await retryPolicy.run(
      () => service
          .generateContent(request)
          .timeout(
            timeout,
            onTimeout: () => throw TimeoutException(
              '${phase[0].toUpperCase()}${phase.substring(1)} generation timed out',
            ),
          ),
    );
    debugLog.log(
      'DECK_GEN',
      '$phase response: ${response.candidates.length} candidates',
    );
    return _parseJsonResponse(response, phase);
  }

  /// Parses JSON from a Gemini response.
  Map<String, dynamic>? _parseJsonResponse(
    google_ai.GenerateContentResponse response,
    String context,
  ) {
    if (response.candidates.isEmpty) {
      debugLog.error('DECK_GEN', 'No candidates in $context response');
      return null;
    }

    final candidate = response.candidates.first;
    final textParts =
        candidate.content?.parts
            .where((p) => p.text != null)
            .map((p) => p.text!)
            .toList() ??
        [];

    if (textParts.isEmpty) {
      debugLog.error('DECK_GEN', 'No text content in $context response');
      return null;
    }

    final jsonText = textParts.join('');

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        debugLog.error(
          'DECK_GEN',
          'Expected JSON map for $context, got ${decoded.runtimeType}',
        );
        return null;
      }
      return decoded;
    } catch (e) {
      debugLog.error('DECK_GEN', 'JSON parse failed for $context: $e');
      return null;
    }
  }

  /// Ensures required directories exist.
  Future<void> _ensureDirectoriesExist() async {
    await Directory(Paths.superdeckDir).create(recursive: true);
    await Directory(Paths.superdeckAssetsPath).create(recursive: true);
  }
}
