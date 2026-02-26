import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:superdeck_genui/src/chat/chat_viewmodel.dart';
import 'package:superdeck_genui/src/chat/view/widgets/model_select.dart';
import 'package:superdeck_genui/src/ai/prompts/prompt_registry.dart';

/// A mock [A2uiMessageProcessor] for testing.
class MockA2uiMessageProcessor implements A2uiMessageProcessor {
  final _onSubmitController =
      StreamController<UserUiInteractionMessage>.broadcast();
  final _surfaceUpdatesController = StreamController<GenUiUpdate>.broadcast();
  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  final _dataModels = <String, DataModel>{};

  @override
  Stream<UserUiInteractionMessage> get onSubmit => _onSubmitController.stream;

  @override
  Stream<GenUiUpdate> get surfaceUpdates => _surfaceUpdatesController.stream;

  @override
  Iterable<Catalog> get catalogs => [];

  @override
  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  @override
  Map<String, DataModel> get dataModels => Map.unmodifiable(_dataModels);

  @override
  DataModel dataModelForSurface(String surfaceId) {
    return _dataModels.putIfAbsent(surfaceId, DataModel.new);
  }

  @override
  void handleMessage(A2uiMessage message) {}

  @override
  void handleUiEvent(UiEvent event) {}

  @override
  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId) {
    return _surfaces.putIfAbsent(
      surfaceId,
      () => ValueNotifier<UiDefinition?>(null),
    );
  }

  @override
  void dispose() {
    _onSubmitController.close();
    _surfaceUpdatesController.close();
    for (final notifier in _surfaces.values) {
      notifier.dispose();
    }
  }
}

/// A mock [ContentGenerator] for testing.
class MockContentGenerator implements ContentGenerator {
  final _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  @override
  Stream<String> get textResponseStream => _textResponseController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {}

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
    _errorController.close();
    _isProcessing.dispose();
  }
}

/// A mock [GenUiConversation] that performs no async operations.
///
/// Explicitly implements all members to ensure tests fail at compile time
/// when the [GenUiConversation] class changes.
class MockGenUiConversation implements GenUiConversation {
  MockGenUiConversation()
    : _processor = MockA2uiMessageProcessor(),
      _generator = MockContentGenerator();

  final MockA2uiMessageProcessor _processor;
  final MockContentGenerator _generator;
  final _isProcessing = ValueNotifier<bool>(false);
  final _conversation = ValueNotifier<List<ChatMessage>>([]);
  bool _isDisposed = false;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  ValueListenable<List<ChatMessage>> get conversation => _conversation;

  @override
  Future<void> sendRequest(ChatMessage message) async {
    // No-op for tests - don't trigger async operations
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isProcessing.dispose();
    _conversation.dispose();
    _processor.dispose();
    _generator.dispose();
  }

  bool get isDisposed => _isDisposed;

  @override
  GenUiHost get host => _processor;

  @override
  A2uiMessageProcessor get a2uiMessageProcessor => _processor;

  @override
  ContentGenerator get contentGenerator => _generator;

  @override
  ValueNotifier<UiDefinition?> surface(String surfaceId) {
    return _processor.getSurfaceNotifier(surfaceId);
  }

  @override
  ValueChanged<SurfaceAdded>? get onSurfaceAdded => null;

  @override
  ValueChanged<SurfaceRemoved>? get onSurfaceDeleted => null;

  @override
  ValueChanged<SurfaceUpdated>? get onSurfaceUpdated => null;

  @override
  ValueChanged<String>? get onTextResponse => null;

  @override
  ValueChanged<ContentGeneratorError>? get onError => null;
}

/// A mock builder that creates [MockGenUiConversation] instances.
class MockConversationBuilder {
  MockGenUiConversation? lastCreatedConversation;

  GenUiConversation call({
    required ContentGenerator contentGenerator,
    required A2uiMessageProcessor a2uiMessageProcessor,
    required ValueChanged<String>? onTextResponse,
    required ValueChanged<ContentGeneratorError>? onError,
    required ValueChanged<SurfaceAdded>? onSurfaceAdded,
    required ValueChanged<SurfaceUpdated>? onSurfaceUpdated,
    required ValueChanged<SurfaceRemoved>? onSurfaceDeleted,
  }) {
    lastCreatedConversation = MockGenUiConversation();
    return lastCreatedConversation!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatViewModel viewModel;
  late MockConversationBuilder mockConversationBuilder;
  var viewModelDisposedInTest = false;

  setUpAll(() async {
    // Load test environment variables
    dotenv.loadFromString(envString: 'GOOGLE_AI_API_KEY=test_api_key');

    // Load PromptRegistry with a minimal test prompt
    PromptRegistry.instance.loadForTest(
      prompts: {'wizard_system': 'Test system prompt for wizard'},
    );
  });

  tearDownAll(() {
    PromptRegistry.instance.reset();
  });

  setUp(() {
    viewModelDisposedInTest = false;
    mockConversationBuilder = MockConversationBuilder();
    viewModel = ChatViewModel(
      conversationBuilder: mockConversationBuilder.call,
    );
  });

  tearDown(() {
    if (!viewModelDisposedInTest) {
      viewModel.dispose();
    }
  });

  group('ChatViewModel', () {
    group('initial state', () {
      test('surfaceIds should be empty list', () {
        expect(viewModel.surfaceIds.value, isEmpty);
      });

      test('hasConversationStarted should be false', () {
        expect(viewModel.hasConversationStarted.value, isFalse);
      });

      test('messages should be empty', () {
        expect(viewModel.messages.value, isEmpty);
      });

      test('isThinking should return false', () {
        expect(viewModel.isThinking.value, isFalse);
      });
    });

    group('sendMessage', () {
      test('should not start conversation when message is empty', () {
        viewModel.sendMessage('');

        expect(viewModel.hasConversationStarted.value, isFalse);
        expect(viewModel.messages.value, isEmpty);
      });

      test('should start conversation when message is not empty', () {
        viewModel.sendMessage('Hello');

        expect(viewModel.hasConversationStarted.value, isTrue);
        expect(viewModel.messages.value, isNotEmpty);
      });

      test('should add user message to messages list', () {
        viewModel.sendMessage('Hello');

        expect(viewModel.messages.value.length, 1);
        expect(viewModel.messages.value.first, isA<SuperdeckUserMessage>());
        expect(
          (viewModel.messages.value.first as SuperdeckUserMessage).text,
          'Hello',
        );
      });

      test('should add multiple messages to messages list', () {
        viewModel.sendMessage('First message');
        viewModel.sendMessage('Second message');

        expect(viewModel.messages.value.length, 2);
      });

      test('should create conversation via builder', () {
        viewModel.sendMessage('Hello');

        expect(mockConversationBuilder.lastCreatedConversation, isNotNull);
      });
    });

    group('restartConversation', () {
      test('should clear conversation and messages', () {
        viewModel.sendMessage('Hello');
        expect(viewModel.hasConversationStarted.value, isTrue);

        viewModel.restartConversation();

        expect(viewModel.hasConversationStarted.value, isFalse);
        expect(viewModel.messages.value, isEmpty);
      });

      test('should clear surfaceIds', () {
        viewModel.sendMessage('Hello');
        viewModel.surfaceIds.value = [
          ...viewModel.surfaceIds.value,
          'surface-1',
        ];
        expect(viewModel.surfaceIds.value, isNotEmpty);

        viewModel.restartConversation();

        expect(viewModel.surfaceIds.value, isEmpty);
      });

      test('should dispose previous conversation', () {
        viewModel.sendMessage('Hello');
        final conversation = mockConversationBuilder.lastCreatedConversation!;

        viewModel.restartConversation();

        expect(conversation.isDisposed, isTrue);
      });
    });

    group('dispose', () {
      // These tests create their own viewModel to avoid double-disposal
      // from the shared tearDown.

      test('should dispose conversation when present', () {
        final localBuilder = MockConversationBuilder();
        final localViewModel = ChatViewModel(
          conversationBuilder: localBuilder.call,
        );

        localViewModel.sendMessage('Hello');
        final conversation = localBuilder.lastCreatedConversation!;

        localViewModel.dispose();

        expect(conversation.isDisposed, isTrue);
      });

      test('should not throw when no conversation exists', () {
        final localViewModel = ChatViewModel(
          conversationBuilder: mockConversationBuilder.call,
        );

        expect(() => localViewModel.dispose(), returnsNormally);
      });
    });

    group('model', () {
      test('should be able to change model', () {
        // Pick a different model than current
        final newModel = viewModel.model.value == GeminiModels.gemini25Pro
            ? GeminiModels.gemini25Flash
            : GeminiModels.gemini25Pro;

        viewModel.model.value = newModel;

        expect(viewModel.model.value, newModel);
      });
    });

    group('surfaceIds', () {
      test('should be able to add surface id', () {
        viewModel.surfaceIds.value = [
          ...viewModel.surfaceIds.value,
          'surface-1',
        ];

        expect(viewModel.surfaceIds.value, contains('surface-1'));
      });

      test('should be able to remove surface id', () {
        viewModel.surfaceIds.value = ['surface-1', 'surface-2'];

        viewModel.surfaceIds.value = viewModel.surfaceIds.value
            .where((id) => id != 'surface-1')
            .toList();

        expect(viewModel.surfaceIds.value, isNot(contains('surface-1')));
        expect(viewModel.surfaceIds.value, contains('surface-2'));
      });

      test('should be able to clear all surface ids', () {
        viewModel.surfaceIds.value = ['surface-1', 'surface-2'];

        viewModel.surfaceIds.value = [];

        expect(viewModel.surfaceIds.value, isEmpty);
      });
    });
  });
}
