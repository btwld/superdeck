import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;

import 'package:playground/features/ai/chat/chat_viewmodel.dart';
import 'package:playground/features/ai/chat/view/widgets/model_select.dart';
import 'package:playground/features/ai/core/ai/catalog/catalog.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAgentClient agent;
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
    agent = _FakeAgentClient(chunks: const []);
    capturedTools = const [];
  });

  tearDown(() {
    PromptRegistry.instance.reset();
  });

  group('ChatViewModel', () {
    test('normalizes Gemini model paths for Dartantic', () {
      expect(
        normalizeGeminiModelName('models/gemini-3-flash-preview'),
        'gemini-3-flash-preview',
      );
      expect(normalizeGeminiModelName('gemini-2.5-flash'), 'gemini-2.5-flash');
    });

    test('has expected initial state', () {
      final viewModel = ChatViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      expect(viewModel.surfaceIds.value, isEmpty);
      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(viewModel.messages.value, isEmpty);
      expect(viewModel.isThinking.value, isFalse);
    });

    test('ignores empty messages', () {
      final viewModel = ChatViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      viewModel.sendMessage('   ');

      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(viewModel.messages.value, isEmpty);
    });

    test(
      'streams chunks into one AI bubble and owns system prompt history',
      () async {
        agent = _FakeAgentClient(chunks: const ['Hel', 'lo']);
        final viewModel = ChatViewModel(agentClientFactory: fakeAgentFactory);
        addTearDown(viewModel.dispose);

        viewModel.sendMessage('Hello');
        await pumpEventQueue();

        expect(viewModel.hasConversationStarted.value, isTrue);
        expect(agent.prompts, ['Hello']);
        expect(
          agent.histories.single.first.role,
          dartantic.ChatMessageRole.system,
        );
        expect(
          _messageText(agent.histories.single.first),
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
      final viewModel = ChatViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      expect(viewModel.buildConversation(), isTrue);
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
        final viewModel = ChatViewModel(agentClientFactory: fakeAgentFactory);
        addTearDown(viewModel.dispose);

        expect(viewModel.buildConversation(), isTrue);
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

    test('prompt load failure emits safe user-facing message', () {
      PromptRegistry.instance.reset();
      final viewModel = ChatViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      viewModel.sendMessage('Hello');

      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(
        (viewModel.messages.value.single as SuperdeckAiMessage).text,
        'Unable to load conversation prompts. Please restart the app.',
      );
    });

    test('missing API key emits safe user-facing message', () {
      dotenv.loadFromString(envString: '', isOptional: true);
      final viewModel = ChatViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      viewModel.sendMessage('Hello');

      expect(viewModel.hasConversationStarted.value, isFalse);
      expect(
        (viewModel.messages.value.single as SuperdeckAiMessage).text,
        'Unable to start conversation. Please check your API key configuration.',
      );
    });

    test('allows model selection before conversation starts', () {
      final viewModel = ChatViewModel(agentClientFactory: fakeAgentFactory);
      addTearDown(viewModel.dispose);

      viewModel.model.value = GeminiModels.gemini25Pro;

      expect(viewModel.model.value, GeminiModels.gemini25Pro);
    });
  });
}

class _FakeAgentClient implements SuperdeckAgentClient {
  _FakeAgentClient({required this.chunks});

  final List<String> chunks;
  final prompts = <String>[];
  final histories = <List<dartantic.ChatMessage>>[];
  String? capturedApiKey;
  String? capturedModelName;
  var disposed = false;

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    prompts.add(prompt);
    histories.add(history.toList());
    for (final chunk in chunks) {
      yield SuperdeckAgentResponseChunk(text: chunk);
    }
  }

  @override
  void dispose() {
    disposed = true;
  }
}

String _messageText(dartantic.ChatMessage message) {
  return message.parts
      .whereType<dartantic.TextPart>()
      .map((e) => e.text)
      .join();
}
