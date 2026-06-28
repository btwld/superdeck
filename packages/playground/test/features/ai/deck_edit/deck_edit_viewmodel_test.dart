import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/deck_tools_adapter.dart';
import 'package:playground/features/ai/core/tools/deck_tools_runtime.dart';
import 'package:playground/features/ai/core/tools/deck_tools_service.dart';
import 'package:playground/features/ai/deck_edit/deck_edit_viewmodel.dart';

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

  test('passes the seven deck-edit tools to the Dartantic agent client', () {
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

    final viewModel = DeckEditViewModel(
      toolsAdapter: adapter,
      agentClientFactory:
          ({
            required String apiKey,
            required String modelName,
            required List<dartantic.Tool> tools,
          }) {
            capturedTools = tools;
            return _FakeAgentClient();
          },
    );
    addTearDown(viewModel.dispose);
    addTearDown(service.dispose);

    expect(viewModel.buildConversation(), isTrue);

    expect(capturedTools!.map((tool) => tool.name), [
      'getDeck',
      'createSlide',
      'updateSlide',
      'deleteSlide',
      'moveSlide',
      'readSlide',
      'updateStyle',
    ]);
  });
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

class _FakeAgentClient implements SuperdeckAgentClient {
  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {}

  @override
  void dispose() {}
}
