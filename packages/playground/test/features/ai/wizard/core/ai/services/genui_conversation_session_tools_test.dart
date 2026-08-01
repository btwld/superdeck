import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/deck_editor/ai/deck_edit_conversation_profile.dart';
import 'package:playground/features/ai/deck_editor/ai/deck_tools_adapter.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_store.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_tools_service.dart';
import 'package:playground/features/ai/wizard/chat/chat_conversation_profile.dart';
import 'package:playground/features/ai/wizard/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/wizard/core/ai/services/genui_conversation_session.dart';
import 'package:playground/features/ai/wizard/core/ai/services/superdeck_agent_client.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PromptRegistry.instance.loadForTest(
      prompts: {
        'deck_edit_system': 'Use the deck tools.',
        'wizard_system': 'Ask wizard questions.',
      },
    );
  });
  tearDown(PromptRegistry.instance.reset);

  test('session forwards deck tools while wizard forwards none', () async {
    final captured = <List<dartantic.Tool>>[];
    SuperdeckAgentClient factory({
      required String apiKey,
      required String modelName,
      required List<dartantic.Tool> tools,
    }) {
      captured.add(tools);
      return _FakeAgentClient();
    }

    final adapter = DeckToolsAdapter(
      DeckToolsService(deckStore: _EmptyDeckStore()),
    );
    final deckSession = _session(
      profile: deckEditConversationProfile(adapter),
      agentClientFactory: factory,
    );
    final wizardSession = _session(
      profile: chatConversationProfile(),
      agentClientFactory: factory,
    );
    addTearDown(deckSession.dispose);
    addTearDown(wizardSession.dispose);

    expect(
      (await deckSession.ensureStarted(modelName: 'test-model')).started,
      isTrue,
    );
    expect(
      (await wizardSession.ensureStarted(modelName: 'test-model')).started,
      isTrue,
    );

    expect(captured, hasLength(2));
    expect(
      captured.first.map((tool) => tool.name),
      adapter.tools.map((e) => e.name),
    );
    expect(captured.first, hasLength(7));
    expect(captured.last, isEmpty);
  });
}

GenUiConversationSession _session({
  required dynamic profile,
  required SuperdeckAgentClientFactory agentClientFactory,
}) {
  return GenUiConversationSession(
    profile: profile,
    apiKeyProvider: () => 'test-api-key',
    agentClientFactory: agentClientFactory,
    handlers: ConversationSessionHandlers(
      onRequestStarted: () {},
      onRequestFinished: () {},
      onUiSubmit: (_) {},
      onSurfaceUpdate: (_) {},
      onTextResponse: (_) {},
      onError: (_, _) {},
    ),
  );
}

class _FakeAgentClient implements SuperdeckAgentClient {
  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) => const Stream.empty();

  @override
  void dispose() {}
}

class _EmptyDeckStore implements DeckStore {
  @override
  List<Slide> read() => const [];

  @override
  Future<List<Slide>> restore(String markdown) async => const [];

  @override
  Future<List<Slide>> synchronize() async => const [];

  @override
  Future<List<Slide>> write(List<Slide> slides) async => slides;
}
