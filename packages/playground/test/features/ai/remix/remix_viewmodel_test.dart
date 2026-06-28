import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playground/features/ai/chat/view/widgets/model_select.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';
import 'package:playground/features/ai/remix/remix_viewmodel.dart';

import '../../../helpers/fake_superdeck_agent_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSuperdeckAgentClient agent;

  SuperdeckAgentClient fakeAgentFactory({
    required String apiKey,
    required String modelName,
    required List<dartantic.Tool> tools,
  }) {
    agent.capturedModelName = modelName;
    return agent;
  }

  setUp(() {
    dotenv.loadFromString(envString: 'GOOGLE_AI_API_KEY=test_api_key');
    PromptRegistry.instance.loadForTest(
      prompts: {'remix_system': 'Test remix prompt'},
    );
    agent = FakeSuperdeckAgentClient();
  });

  tearDown(() {
    PromptRegistry.instance.reset();
  });

  group('RemixViewModel', () {
    test('has expected initial state', () {
      final viewModel = RemixViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      expect(viewModel.surfaceIds.value, isEmpty);
      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(viewModel.messages.value, isEmpty);
      expect(viewModel.isThinking.value, isFalse);
    });

    test('starts conversation and sends user message', () async {
      agent = FakeSuperdeckAgentClient(chunks: const ['Done']);
      final viewModel = RemixViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      viewModel.sendMessage('Build a settings panel');
      await pumpEventQueue();

      expect(viewModel.hasConversationStarted.value, isTrue);
      expect(agent.prompts, ['Build a settings panel']);
      expect(
        agent.histories.single.first.role,
        dartantic.ChatMessageRole.system,
      );
      expect(
        dartanticMessageText(agent.histories.single.first),
        contains('Test remix prompt'),
      );
      expect(
        (viewModel.messages.value.first as SuperdeckUserMessage).text,
        'Build a settings panel',
      );
      expect(
        (viewModel.messages.value.last as SuperdeckAiMessage).text,
        'Done',
      );
    });

    test('loads real asset prompt when conversation starts', () async {
      PromptRegistry.instance.reset();
      final viewModel = RemixViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      viewModel.sendMessage('Build a settings panel');
      await pumpEventQueue();

      expect(PromptRegistry.instance.isLoaded, isTrue);
      expect(viewModel.hasConversationStarted.value, isTrue);
      expect(agent.prompts, ['Build a settings panel']);
      final systemPrompt = dartanticMessageText(agent.histories.single.first);
      expect(systemPrompt, contains('Remix UI component builder'));
    });

    test('restart clears session and disposes agent', () async {
      final viewModel = RemixViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      viewModel.sendMessage('Hello');
      await pumpEventQueue();
      expect(viewModel.hasConversationStarted.value, isTrue);

      viewModel.restartConversation();

      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(viewModel.messages.value, isEmpty);
      expect(agent.disposed, isTrue);
    });

    test('restart ignores delayed chunks from previous request', () async {
      final responseController =
          StreamController<SuperdeckAgentResponseChunk>();
      agent = FakeSuperdeckAgentClient(
        responseStream: responseController.stream,
      );
      final viewModel = RemixViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);
      addTearDown(responseController.close);

      viewModel.sendMessage('Hello');
      await pumpEventQueue();
      expect(viewModel.hasConversationStarted.value, isTrue);

      viewModel.restartConversation();
      responseController.add(const SuperdeckAgentResponseChunk(text: 'Late'));
      await pumpEventQueue();
      await responseController.close();

      expect(viewModel.messages.value, isEmpty);
      expect(viewModel.isThinking.value, isFalse);
    });

    test('serializes overlapping user requests', () async {
      final queuedAgent = QueuedSuperdeckAgentClient();
      final viewModel = RemixViewModel(
        agentClientFactory:
            ({
              required String apiKey,
              required String modelName,
              required List<dartantic.Tool> tools,
            }) {
              return queuedAgent;
            },
      );
      addTearDown(viewModel.dispose);

      viewModel.sendMessage('First');
      await pumpEventQueue();
      expect(queuedAgent.prompts, ['First']);

      viewModel.sendMessage('Second');
      await pumpEventQueue();
      expect(queuedAgent.prompts, ['First']);
      expect(queuedAgent.maxActiveInvocations, 1);

      queuedAgent.completeNext();
      await pumpEventQueue();
      expect(queuedAgent.prompts, ['First', 'Second']);
      expect(queuedAgent.maxActiveInvocations, 1);

      queuedAgent.completeNext();
      await pumpEventQueue();
      expect(queuedAgent.activeInvocations, 0);
    });

    test('allows model selection before conversation starts', () {
      final viewModel = RemixViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      viewModel.model.value = GeminiModels.gemini25Pro;

      expect(viewModel.model.value, GeminiModels.gemini25Pro);
    });
  });
}
