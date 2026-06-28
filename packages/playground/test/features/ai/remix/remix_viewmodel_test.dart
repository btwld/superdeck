import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playground/features/ai/chat/view/widgets/model_select.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';
import 'package:playground/features/ai/remix/remix_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAgentClient agent;

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
    agent = _FakeAgentClient(chunks: const []);
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
      agent = _FakeAgentClient(chunks: const ['Done']);
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
        _messageText(agent.histories.single.first),
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

    test('allows model selection before conversation starts', () {
      final viewModel = RemixViewModel(agentClientFactory: fakeAgentFactory);
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
