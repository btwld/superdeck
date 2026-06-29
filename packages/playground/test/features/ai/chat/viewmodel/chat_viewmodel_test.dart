import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;

import 'package:playground/features/ai/chat/chat_conversation_profile.dart';
import 'package:playground/features/ai/chat/chat_message.dart';
import 'package:playground/features/ai/chat/view/widgets/model_select.dart';
import 'package:playground/features/ai/core/ai/catalog/catalog.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/ai_conversation_viewmodel.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';

import '../../../../helpers/fake_superdeck_agent_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSuperdeckAgentClient agent;
  late List<dartantic.Tool> capturedTools;

  SuperdeckAgentClient fakeAgentFactory({
    required String apiKey,
    required String modelName,
    required List<dartantic.Tool> tools,
  }) {
    capturedTools = tools;
    agent.capturedApiKey = apiKey;
    agent.capturedModelName = modelName;
    return agent;
  }

  setUp(() {
    dotenv.loadFromString(envString: 'GOOGLE_AI_API_KEY=test_api_key');
    PromptRegistry.instance.loadForTest(
      prompts: {'wizard_system': 'Test wizard prompt'},
    );
    agent = FakeSuperdeckAgentClient();
    capturedTools = const [];
  });

  tearDown(() {
    PromptRegistry.instance.reset();
  });

  group('AiConversationViewModel chat profile', () {
    test('normalizes Gemini model paths for Dartantic', () {
      expect(
        normalizeGeminiModelName('models/gemini-3-flash-preview'),
        'gemini-3-flash-preview',
      );
      expect(normalizeGeminiModelName('gemini-2.5-flash'), 'gemini-2.5-flash');
    });

    test('has expected initial state', () {
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: fakeAgentFactory,
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.surfaceIds.value, isEmpty);
      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(viewModel.messages.value, isEmpty);
      expect(viewModel.isThinking.value, isFalse);
    });

    test('ignores empty messages', () async {
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: fakeAgentFactory,
      );
      addTearDown(viewModel.dispose);

      await viewModel.sendMessage('   ');

      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(viewModel.messages.value, isEmpty);
    });

    test(
      'streams chunks into one AI bubble and owns system prompt history',
      () async {
        agent = FakeSuperdeckAgentClient(chunks: const ['Hel', 'lo']);
        final viewModel = AiConversationViewModel(
          profile: chatConversationProfile(),
          agentClientFactory: fakeAgentFactory,
        );
        addTearDown(viewModel.dispose);

        await viewModel.sendMessage('Hello');
        await pumpEventQueue();

        expect(viewModel.hasConversationStarted.value, isTrue);
        expect(agent.prompts, ['Hello']);
        expect(
          agent.histories.single.first.role,
          dartantic.ChatMessageRole.system,
        );
        expect(
          dartanticMessageText(agent.histories.single.first),
          contains('Test wizard prompt'),
        );
        expect(capturedTools, isEmpty);
        expect(agent.capturedApiKey, 'test_api_key');
        expect(agent.capturedModelName, GeminiModels.defaultValue.modelPath);

        final messages = viewModel.messages.value;
        expect(messages, hasLength(2));
        expect((messages.first as SuperdeckUserMessage).text, 'Hello');
        expect((messages.last as SuperdeckAiMessage).text, 'Hello');
      },
    );

    test('v0.9 UI action adds user bubble and forwards interaction', () async {
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: fakeAgentFactory,
      );
      addTearDown(viewModel.dispose);

      expect(await viewModel.ensureConversationStarted(), isTrue);
      viewModel.controller!.handleUiEvent(
        genui.UserActionEvent(
          name: 'submit_answer',
          sourceComponentId: 'root',
          context: {'message': 'Picked option', 'value': 1},
        ),
      );
      await pumpEventQueue();

      expect(
        viewModel.messages.value.whereType<SuperdeckUserMessage>().single.text,
        'Picked option',
      );
      expect(agent.prompts.single, contains('"version":"v0.9"'));
      expect(agent.prompts.single, contains('"action"'));
    });

    test(
      'surface add update and remove keep surfaceIds synchronized',
      () async {
        final viewModel = AiConversationViewModel(
          profile: chatConversationProfile(),
          agentClientFactory: fakeAgentFactory,
        );
        addTearDown(viewModel.dispose);

        expect(await viewModel.ensureConversationStarted(), isTrue);
        final controller = viewModel.controller!;

        controller.handleMessage(
          genui.CreateSurface(
            surfaceId: 'surface-1',
            catalogId: chatCatalog.catalogId!,
          ),
        );
        await pumpEventQueue();
        expect(viewModel.surfaceIds.value, ['surface-1']);

        controller.handleMessage(
          genui.UpdateComponents(
            surfaceId: 'surface-1',
            components: const [
              genui.Component(
                id: 'root',
                type: 'AskUserText',
                properties: {
                  'question': 'Topic?',
                  'action': {'name': 'submit_answer', 'context': []},
                },
              ),
            ],
          ),
        );
        await pumpEventQueue();
        expect(viewModel.surfaceIds.value, ['surface-1']);

        controller.handleMessage(
          const genui.DeleteSurface(surfaceId: 'surface-1'),
        );
        await pumpEventQueue();
        expect(viewModel.surfaceIds.value, isEmpty);
      },
    );

    test('missing prompt emits safe user-facing message', () async {
      PromptRegistry.instance.loadForTest();
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: fakeAgentFactory,
      );
      addTearDown(viewModel.dispose);

      await viewModel.sendMessage('Hello');

      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(
        (viewModel.messages.value.single as SuperdeckAiMessage).text,
        'Unable to load conversation prompts. Please restart the app.',
      );
    });

    test('loads asset prompts when conversation starts', () async {
      PromptRegistry.instance.reset();
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: fakeAgentFactory,
      );
      addTearDown(viewModel.dispose);

      await viewModel.sendMessage('Hello');

      expect(PromptRegistry.instance.isLoaded, isTrue);
      expect(viewModel.hasConversationStarted.value, isTrue);
      expect(agent.prompts, ['Hello']);
    });

    test('missing API key emits safe user-facing message', () async {
      dotenv.loadFromString(envString: '', isOptional: true);
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: fakeAgentFactory,
      );
      addTearDown(viewModel.dispose);

      await viewModel.sendMessage('Hello');

      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(
        (viewModel.messages.value.single as SuperdeckAiMessage).text,
        'Unable to start conversation. Please check your API key configuration.',
      );
    });

    test('restart ignores delayed chunks from previous request', () async {
      final responseController =
          StreamController<SuperdeckAgentResponseChunk>();
      agent = FakeSuperdeckAgentClient(
        responseStream: responseController.stream,
      );
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: fakeAgentFactory,
      );
      addTearDown(viewModel.dispose);
      addTearDown(responseController.close);

      unawaited(viewModel.sendMessage('Hello'));
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
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
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

      unawaited(viewModel.sendMessage('First'));
      await pumpEventQueue();
      expect(queuedAgent.prompts, ['First']);

      unawaited(viewModel.sendMessage('Second'));
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
      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: fakeAgentFactory,
      );
      addTearDown(viewModel.dispose);

      viewModel.model.value = GeminiModels.gemini25Pro;

      expect(viewModel.model.value, GeminiModels.gemini25Pro);
    });
  });
}
