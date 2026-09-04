import 'dart:convert';

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:googleai_dart/googleai_dart.dart' as modern_google_ai;

import '../../constants/gemini_models.dart';

/// Boundary around the model transport used by deck generation.
///
/// The pipeline keeps the provider request/response types at this boundary so
/// tests can supply deterministic responses without starting an HTTP client.
abstract interface class GenerationModelClient {
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  );

  void close();
}

/// Creates a model client for one deck-generation run.
typedef GenerationModelClientFactory =
    GenerationModelClient Function(String apiKey);

/// Production client backed by Google Generative Language.
final class GoogleGenerationModelClient implements GenerationModelClient {
  final modern_google_ai.GoogleAIClient _client;

  GoogleGenerationModelClient.fromApiKey(String apiKey)
    : _client = modern_google_ai.GoogleAIClient(
        config: modern_google_ai.GoogleAIConfig.googleAI(
          authProvider: modern_google_ai.ApiKeyProvider(apiKey),
          retryPolicy: const modern_google_ai.RetryPolicy(maxRetries: 0),
        ),
      );

  @override
  void close() => _client.close();

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) async {
    final adapted = adaptGenerationRequest(request);
    final response = await _client.models.generateContent(
      model: adapted.model,
      request: adapted.request,
    );

    return google_ai.GenerateContentResponse.fromJson(response.toJson());
  }
}

/// A request prepared for the current Gemini Developer API transport.
typedef AdaptedGenerationRequest = ({
  String model,
  modern_google_ai.GenerateContentRequest request,
});

/// Converts the generated v1beta request types used by the schema adapter to
/// the current transport types, including Gemini 3 thinking levels.
///
/// The generated client does not yet expose `thinkingLevel`, while Gemini 3.7
/// rejects the legacy `thinkingBudget` setting. Keeping the conversion here
/// lets the deck pipeline retain its strongly typed schemas without sending a
/// stale request shape to Google.
AdaptedGenerationRequest adaptGenerationRequest(
  google_ai.GenerateContentRequest request,
) {
  final json = jsonDecode(jsonEncode(request.toJson())) as Map<String, dynamic>;
  json.remove('model');

  final generationConfig = switch (json['generationConfig']) {
    final Map<String, dynamic> value => value,
    _ => <String, dynamic>{},
  };
  final thinkingLevel = switch (request.model) {
    GeminiModelNames.gemini37Flash => 'LOW',
    GeminiModelNames.gemini35FlashLite => 'MINIMAL',
    _ => null,
  };
  if (thinkingLevel != null) {
    generationConfig['thinkingConfig'] = {'thinkingLevel': thinkingLevel};
  }
  json['generationConfig'] = generationConfig;

  return (
    model: request.model.replaceFirst(RegExp(r'^models/'), ''),
    request: modern_google_ai.GenerateContentRequest.fromJson(json),
  );
}
