import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

typedef SuperdeckAgentClientFactory =
    SuperdeckAgentClient Function({
      required String apiKey,
      required String modelName,
      required List<dartantic.Tool> tools,
    });

abstract interface class SuperdeckAgentClient {
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  });

  void dispose();
}

class SuperdeckAgentResponseChunk {
  const SuperdeckAgentResponseChunk({this.text = '', this.messages = const []});

  final String text;
  final List<dartantic.ChatMessage> messages;
}

class DartanticSuperdeckAgentClient implements SuperdeckAgentClient {
  DartanticSuperdeckAgentClient({
    required String apiKey,
    required String modelName,
    required List<dartantic.Tool> tools,
  }) : _agent = dartantic.Agent.forProvider(
         dartantic.GoogleProvider(apiKey: apiKey),
         chatModelName: normalizeGeminiModelName(modelName),
         tools: tools,
       );

  final dartantic.Agent _agent;

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    await for (final result in _agent.sendStream(prompt, history: history)) {
      if (result.output.isNotEmpty || result.messages.isNotEmpty) {
        yield SuperdeckAgentResponseChunk(
          text: result.output,
          messages: result.messages,
        );
      }
    }
  }

  @override
  void dispose() {}
}

String normalizeGeminiModelName(String modelName) {
  const prefix = 'models/';
  if (!modelName.startsWith(prefix)) {
    return modelName;
  }

  return modelName.substring(prefix.length);
}
