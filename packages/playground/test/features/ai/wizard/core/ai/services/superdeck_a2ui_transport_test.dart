import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:playground/features/ai/wizard/core/ai/services/superdeck_a2ui_transport.dart';
import 'package:playground/features/ai/wizard/core/ai/services/superdeck_agent_client.dart';

void main() {
  test(
    'retries an empty model response and emits the recovered text',
    () async {
      final client = _EmptyThenSuccessfulAgentClient();
      final transport = SuperdeckA2uiTransport(
        apiKey: 'test-key',
        modelName: 'test-model',
        systemPrompt: 'test-system-prompt',
        tools: const [],
        agentClientFactory:
            ({required apiKey, required modelName, required tools}) => client,
      );
      addTearDown(transport.dispose);

      final recoveredText = transport.incomingText.first;
      await transport.sendRequest(genui.ChatMessage.user('Build a pitch deck'));

      expect(
        await recoveredText.timeout(const Duration(milliseconds: 200)),
        'Recovered response',
      );
      expect(client.attempts, 2);
    },
  );

  test('throws after two empty model responses', () async {
    final client = _AlwaysEmptyAgentClient();
    final transport = SuperdeckA2uiTransport(
      apiKey: 'test-key',
      modelName: 'test-model',
      systemPrompt: 'test-system-prompt',
      tools: const [],
      agentClientFactory:
          ({required apiKey, required modelName, required tools}) => client,
    );
    addTearDown(transport.dispose);

    await expectLater(
      transport.sendRequest(genui.ChatMessage.user('Build a pitch deck')),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('empty response'),
        ),
      ),
    );
    expect(client.attempts, 2);
  });

  test('delivers parsed A2UI before sendRequest completes', () async {
    final transport = SuperdeckA2uiTransport(
      apiKey: 'test-key',
      modelName: 'test-model',
      systemPrompt: 'test-system-prompt',
      tools: const [],
      agentClientFactory:
          ({required apiKey, required modelName, required tools}) =>
              _A2uiAgentClient(),
    );
    addTearDown(transport.dispose);
    var receivedMessage = false;
    final subscription = transport.incomingMessages.listen((_) {
      receivedMessage = true;
    });
    addTearDown(subscription.cancel);

    await transport.sendRequest(genui.ChatMessage.user('Build a pitch deck'));

    expect(receivedMessage, isTrue);
  });
}

final class _EmptyThenSuccessfulAgentClient implements SuperdeckAgentClient {
  var attempts = 0;

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    attempts++;
    yield SuperdeckAgentResponseChunk(
      messages: [dartantic.ChatMessage.user(prompt)],
    );

    if (attempts == 1) {
      yield SuperdeckAgentResponseChunk(
        messages: [dartantic.ChatMessage.model('')],
      );
      return;
    }

    yield const SuperdeckAgentResponseChunk(text: 'Recovered response');
    yield SuperdeckAgentResponseChunk(
      messages: [dartantic.ChatMessage.model('Recovered response')],
    );
  }

  @override
  void dispose() {}
}

final class _AlwaysEmptyAgentClient implements SuperdeckAgentClient {
  var attempts = 0;

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    attempts++;
    yield SuperdeckAgentResponseChunk(
      messages: [dartantic.ChatMessage.user(prompt)],
    );
    yield SuperdeckAgentResponseChunk(
      messages: [dartantic.ChatMessage.model('')],
    );
  }

  @override
  void dispose() {}
}

final class _A2uiAgentClient implements SuperdeckAgentClient {
  @override
  void dispose() {}

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    yield const SuperdeckAgentResponseChunk(
      text:
          '{"version":"v0.9","createSurface":{"surfaceId":"wizard",'
          '"catalogId":"test","sendDataModel":false}}',
    );
  }
}
