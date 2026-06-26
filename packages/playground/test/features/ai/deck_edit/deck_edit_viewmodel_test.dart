import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/tools/deck_store.dart';
import 'package:playground/features/ai/core/tools/deck_tools_adapter.dart';
import 'package:playground/features/ai/core/tools/deck_tools_runtime.dart';
import 'package:playground/features/ai/core/tools/deck_tools_service.dart';
import 'package:playground/features/ai/deck_edit/deck_edit_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'GOOGLE_AI_API_KEY=test_api_key');
  });

  setUp(() {
    PromptRegistry.instance.loadForTest(
      prompts: {'deck_edit_system': 'Deck edit prompt'},
    );
  });

  tearDown(() {
    PromptRegistry.instance.reset();
  });

  test('passes the seven deck-edit tools as additionalTools', () {
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
    ContentGenerator? capturedGenerator;

    final viewModel = DeckEditViewModel(
      toolsAdapter: adapter,
      conversationBuilder:
          ({
            required contentGenerator,
            required a2uiMessageProcessor,
            required onTextResponse,
            required onError,
            required onSurfaceAdded,
            required onSurfaceUpdated,
            required onSurfaceDeleted,
          }) {
            capturedGenerator = contentGenerator;
            return _FakeConversation(
              processor: a2uiMessageProcessor,
              generator: contentGenerator,
            );
          },
    );
    addTearDown(viewModel.dispose);
    addTearDown(adapter.dispose);
    addTearDown(service.dispose);

    expect(viewModel.buildConversation(), isTrue);

    final generator = capturedGenerator as GoogleGenerativeAiContentGenerator;
    expect(generator.additionalTools.map((tool) => tool.name), [
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

class _FakeConversation implements GenUiConversation {
  _FakeConversation({required this.processor, required this.generator});

  final A2uiMessageProcessor processor;
  final ContentGenerator generator;
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);
  final ValueNotifier<List<ChatMessage>> _conversation =
      ValueNotifier<List<ChatMessage>>([]);

  @override
  A2uiMessageProcessor get a2uiMessageProcessor => processor;

  @override
  ValueListenable<List<ChatMessage>> get conversation => _conversation;

  @override
  ContentGenerator get contentGenerator => generator;

  @override
  GenUiHost get host => processor;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  ValueChanged<ContentGeneratorError>? get onError => null;

  @override
  ValueChanged<SurfaceAdded>? get onSurfaceAdded => null;

  @override
  ValueChanged<SurfaceRemoved>? get onSurfaceDeleted => null;

  @override
  ValueChanged<SurfaceUpdated>? get onSurfaceUpdated => null;

  @override
  ValueChanged<String>? get onTextResponse => null;

  @override
  void dispose() {
    _isProcessing.dispose();
    _conversation.dispose();
    processor.dispose();
    generator.dispose();
  }

  @override
  Future<void> sendRequest(ChatMessage message) async {}

  @override
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return processor.getSurfaceNotifier(surfaceId);
  }
}
