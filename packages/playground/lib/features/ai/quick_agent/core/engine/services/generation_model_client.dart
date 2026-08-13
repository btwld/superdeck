import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;

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
  GoogleGenerationModelClient.fromApiKey(String apiKey)
    : _service = google_ai.GenerativeService.fromApiKey(apiKey);

  final google_ai.GenerativeService _service;

  @override
  void close() => _service.close();

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) => _service.generateContent(request);
}
