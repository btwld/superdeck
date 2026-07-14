part of 'deck_generator_service.dart';

extension _DeckGeneratorPipeline on DeckGeneratorService {
  // ===========================================================================
  // PHASE 1: Generate Outline
  // ===========================================================================

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
    final request = google_ai.GenerateContentRequest(
      model: outlineModelName,
      contents: [
        google_ai.Content(
          role: 'user',
          parts: [google_ai.Part(text: prompt)],
        ),
      ],
      generationConfig: google_ai.GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: adaptResult.schema,
        thinkingConfig: google_ai.ThinkingConfig(
          thinkingBudget: thinkingBudget,
        ),
      ),
      systemInstruction: google_ai.Content(
        parts: [google_ai.Part(text: systemPrompt)],
      ),
    );

    debugLog.log('DECK_GEN', 'Sending outline request to $outlineModelName...');
    final response = await retryPolicy.run(
      () => service
          .generateContent(request)
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw TimeoutException('Outline generation timed out');
            },
          ),
    );
    debugLog.log(
      'DECK_GEN',
      'Outline response: ${response.candidates.length} candidates',
    );

    return _parseJsonResponse(response, 'outline');
  }

  // ===========================================================================
  // PHASE 2: Generate Final Deck
  // ===========================================================================

  /// Generates the final deck from the outline.
  Future<Map<String, dynamic>?> _generateFinalDeck(
    google_ai.GenerativeService service,
    String prompt,
    Map<String, dynamic> outline,
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

    final systemPrompt = _buildFinalDeckPrompt(outline);
    debugLog.log(
      'DECK_GEN',
      'Final deck system prompt (${systemPrompt.length} chars)',
    );
    debugLog.log(
      'DECK_GEN',
      'Final deck thinking budget: ${thinkingBudget > 0 ? thinkingBudget : 'disabled'}',
    );

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
        responseSchema: adaptResult.schema,
        thinkingConfig: google_ai.ThinkingConfig(
          thinkingBudget: thinkingBudget,
        ),
      ),
      systemInstruction: google_ai.Content(
        parts: [google_ai.Part(text: systemPrompt)],
      ),
    );

    debugLog.log('DECK_GEN', 'Sending final deck request to $modelName...');
    final response = await retryPolicy.run(
      () => service
          .generateContent(request)
          .timeout(
            const Duration(minutes: 3),
            onTimeout: () {
              throw TimeoutException('Final deck generation timed out');
            },
          ),
    );
    debugLog.log(
      'DECK_GEN',
      'Final deck response: ${response.candidates.length} candidates',
    );

    return _parseJsonResponse(response, 'deck');
  }

  /// Builds the system prompt for the final deck phase from the outline.
  String _buildFinalDeckPrompt(Map<String, dynamic> outline) {
    final basePrompt = PromptRegistry.instance.render('deck_system');
    final outlineContext = _formatOutlineForPrompt(outline);

    return '''
$basePrompt

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
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

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
      return jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (e) {
      debugLog.error('DECK_GEN', 'JSON parse failed for $context: $e');
      return null;
    }
  }
}
