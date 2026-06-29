import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/ai_conversation_viewmodel.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/deck_tools_adapter.dart';
import 'package:playground/features/ai/core/tools/deck_tools_runtime.dart';
import 'package:playground/features/ai/core/tools/deck_tools_service.dart';
import 'package:playground/features/ai/deck_edit/deck_edit_conversation_profile.dart';

import '../../../helpers/fake_superdeck_agent_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.loadFromString(envString: 'GOOGLE_AI_API_KEY=test_api_key');
    PromptRegistry.instance.loadForTest(
      prompts: {'deck_edit_system': 'Deck edit prompt'},
    );
  });

  tearDown(() {
    PromptRegistry.instance.reset();
  });

  test(
    'passes the seven deck-edit tools to the Dartantic agent client',
    () async {
      final runtime = DeckToolsRuntime(
        slideConfigurationsProvider: () => const [],
        captureSlide: (_) async => throw StateError('capture not expected'),
        applyStyle: (_) {},
        isAvailable: () => true,
      );
      final service = DeckToolsService(
        documentStore: _EmptyDeckStore(),
        runtime: runtime,
      );
      final adapter = DeckToolsAdapter(service);
      List<dartantic.Tool>? capturedTools;

      final viewModel = AiConversationViewModel(
        profile: deckEditConversationProfile(toolsAdapter: adapter),
        agentClientFactory:
            ({
              required String apiKey,
              required String modelName,
              required List<dartantic.Tool> tools,
            }) {
              capturedTools = tools;
              return FakeSuperdeckAgentClient();
            },
      );
      addTearDown(viewModel.dispose);
      addTearDown(adapter.dispose);
      addTearDown(service.dispose);

      expect(await viewModel.ensureConversationStarted(), isTrue);

      expect(capturedTools!.map((tool) => tool.name), [
        'getDeck',
        'createSlide',
        'updateSlide',
        'deleteSlide',
        'moveSlide',
        'readSlide',
        'updateStyle',
      ]);
    },
  );

  test('loads real asset prompt when conversation starts', () async {
    PromptRegistry.instance.reset();
    final agent = FakeSuperdeckAgentClient();
    final viewModel = _deckEditHarness(agent);

    await viewModel.sendMessage('Tighten the intro slide');

    expect(PromptRegistry.instance.isLoaded, isTrue);
    expect(viewModel.hasConversationStarted.value, isTrue);
    expect(agent.prompts, ['Tighten the intro slide']);
    expect(
      dartanticMessageText(agent.histories.single.first),
      contains('editing a live SuperDeck presentation'),
    );
  });

  test('restart ignores delayed chunks from previous request', () async {
    final responseController = StreamController<SuperdeckAgentResponseChunk>();
    final agent = FakeSuperdeckAgentClient(
      responseStream: responseController.stream,
    );
    final viewModel = _deckEditHarness(agent);
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
    final agent = QueuedSuperdeckAgentClient();
    final viewModel = _deckEditHarness(agent);

    unawaited(viewModel.sendMessage('First'));
    await pumpEventQueue();
    expect(agent.prompts, ['First']);

    unawaited(viewModel.sendMessage('Second'));
    await pumpEventQueue();
    expect(agent.prompts, ['First']);
    expect(agent.maxActiveInvocations, 1);

    agent.completeNext();
    await pumpEventQueue();
    expect(agent.prompts, ['First', 'Second']);
    expect(agent.maxActiveInvocations, 1);

    agent.completeNext();
    await pumpEventQueue();
    expect(agent.activeInvocations, 0);
  });
}

AiConversationViewModel _deckEditHarness(SuperdeckAgentClient agent) {
  final runtime = DeckToolsRuntime(
    slideConfigurationsProvider: () => const [],
    captureSlide: (_) async => throw StateError('capture not expected'),
    applyStyle: (_) {},
    isAvailable: () => true,
  );
  final service = DeckToolsService(
    documentStore: _EmptyDeckStore(),
    runtime: runtime,
  );
  final adapter = DeckToolsAdapter(service);
  final viewModel = AiConversationViewModel(
    profile: deckEditConversationProfile(toolsAdapter: adapter),
    agentClientFactory:
        ({
          required String apiKey,
          required String modelName,
          required List<dartantic.Tool> tools,
        }) {
          return agent;
        },
  );

  addTearDown(viewModel.dispose);
  addTearDown(adapter.dispose);
  addTearDown(service.dispose);
  return viewModel;
}

class _EmptyDeckStore implements DeckStore {
  @override
  Future<DeckDocument> readRequired() async {
    return const DeckDocument(slides: []);
  }

  @override
  Future<String> flushMarkdownToCanonical(String markdown) async => markdown;

  @override
  Future<void> writeCanonical(List slides) async {}

  @override
  Future<String> writeCanonicalMarkdown(String markdown) async => markdown;
}
