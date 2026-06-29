import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:playground/features/ai/core/ai/catalog/catalog.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/ai_conversation_profile.dart';
import 'package:playground/features/ai/core/ai/services/genui_conversation_session.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_a2ui_transport.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';

import '../../../../../helpers/fake_superdeck_agent_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.loadFromString(envString: 'GOOGLE_AI_API_KEY=test_api_key');
    PromptRegistry.instance.loadForTest(
      prompts: {'test_system': 'Test session prompt'},
    );
  });

  tearDown(() {
    PromptRegistry.instance.reset();
  });

  test('ensureStarted is idempotent while startup is in flight', () async {
    final harness = _SessionHarness();
    var transportCreations = 0;

    final session = GenUiConversationSession(
      profile: _profile(),
      handlers: harness.handlers,
      transportFactory:
          ({
            required String apiKey,
            required String modelName,
            required String systemPrompt,
            required List<dartantic.Tool> tools,
            SuperdeckAgentClientFactory agentClientFactory =
                DartanticSuperdeckAgentClient.new,
          }) {
            transportCreations++;
            return SuperdeckA2uiTransport(
              apiKey: apiKey,
              modelName: modelName,
              systemPrompt: systemPrompt,
              tools: tools,
              agentClientFactory: agentClientFactory,
            );
          },
      agentClientFactory: _fakeAgentFactory(FakeSuperdeckAgentClient()),
    );
    addTearDown(session.dispose);

    final results = await Future.wait([
      session.ensureStarted(modelName: 'gemini-test'),
      session.ensureStarted(modelName: 'gemini-test'),
    ]);

    expect(results.every((result) => result.started), isTrue);
    expect(transportCreations, 1);
    expect(session.hasActiveSession, isTrue);
  });

  test('missing API key fails without creating a session', () async {
    dotenv.loadFromString(envString: '', isOptional: true);
    final harness = _SessionHarness();
    final session = GenUiConversationSession(
      profile: _profile(),
      handlers: harness.handlers,
      agentClientFactory: _fakeAgentFactory(FakeSuperdeckAgentClient()),
    );
    addTearDown(session.dispose);

    final result = await session.ensureStarted(modelName: 'gemini-test');

    expect(result.started, isFalse);
    expect(
      result.message,
      'Unable to start conversation. Please check your API key configuration.',
    );
    expect(session.hasActiveSession, isFalse);
  });

  test('missing prompt fails with profile prompt-load message', () async {
    PromptRegistry.instance.loadForTest();
    final harness = _SessionHarness();
    final session = GenUiConversationSession(
      profile: _profile(),
      handlers: harness.handlers,
      agentClientFactory: _fakeAgentFactory(FakeSuperdeckAgentClient()),
    );
    addTearDown(session.dispose);

    final result = await session.ensureStarted(modelName: 'gemini-test');

    expect(result.started, isFalse);
    expect(result.message, 'Prompt unavailable.');
    expect(session.hasActiveSession, isFalse);
  });

  test('sendRequest serializes overlapping requests', () async {
    final harness = _SessionHarness();
    final agent = QueuedSuperdeckAgentClient();
    final session = GenUiConversationSession(
      profile: _profile(),
      handlers: harness.handlers,
      agentClientFactory: _fakeAgentFactory(agent),
    );
    addTearDown(session.dispose);

    expect(
      (await session.ensureStarted(modelName: 'gemini-test')).started,
      isTrue,
    );

    unawaited(session.sendRequest(genui.ChatMessage.user('First')));
    await pumpEventQueue();
    expect(agent.prompts, ['First']);
    expect(harness.requestStarts, 1);

    unawaited(session.sendRequest(genui.ChatMessage.user('Second')));
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
    expect(harness.requestFinishes, 2);
  });

  test('restart during startup handoff drops stale session', () async {
    final harness = _SessionHarness();
    final agent = FakeSuperdeckAgentClient();
    late GenUiConversationSession session;
    late _RestartOnIncomingMessagesTransport transport;

    session = GenUiConversationSession(
      profile: _profile(),
      handlers: harness.handlers,
      transportFactory:
          ({
            required String apiKey,
            required String modelName,
            required String systemPrompt,
            required List<dartantic.Tool> tools,
            SuperdeckAgentClientFactory agentClientFactory =
                DartanticSuperdeckAgentClient.new,
          }) {
            transport = _RestartOnIncomingMessagesTransport(
              apiKey: apiKey,
              modelName: modelName,
              systemPrompt: systemPrompt,
              tools: tools,
              agentClientFactory: agentClientFactory,
              onIncomingMessagesListen: session.restart,
            );
            return transport;
          },
      agentClientFactory: _fakeAgentFactory(agent),
    );
    addTearDown(session.dispose);

    final result = await session.ensureStarted(modelName: 'gemini-test');

    expect(result.started, isFalse);
    expect(result.message, isNull);
    expect(session.hasActiveSession, isFalse);
    expect(transport.disposed, isTrue);
    expect(agent.disposed, isTrue);
  });

  test(
    'bind failure disposes local transport and reports startup failure',
    () async {
      final harness = _SessionHarness();
      final agent = FakeSuperdeckAgentClient();
      late _ThrowingIncomingMessagesTransport transport;

      final session = GenUiConversationSession(
        profile: _profile(),
        handlers: harness.handlers,
        transportFactory:
            ({
              required String apiKey,
              required String modelName,
              required String systemPrompt,
              required List<dartantic.Tool> tools,
              SuperdeckAgentClientFactory agentClientFactory =
                  DartanticSuperdeckAgentClient.new,
            }) {
              transport = _ThrowingIncomingMessagesTransport(
                apiKey: apiKey,
                modelName: modelName,
                systemPrompt: systemPrompt,
                tools: tools,
                agentClientFactory: agentClientFactory,
              );
              return transport;
            },
        agentClientFactory: _fakeAgentFactory(agent),
      );
      addTearDown(session.dispose);

      final result = await session.ensureStarted(modelName: 'gemini-test');

      expect(result.started, isFalse);
      expect(
        result.message,
        'Failed to initialize conversation. Please try again.',
      );
      expect(session.hasActiveSession, isFalse);
      expect(transport.disposed, isTrue);
      expect(agent.disposed, isTrue);
    },
  );
}

AiConversationProfile _profile() {
  return AiConversationProfile(
    catalog: chatCatalog,
    promptName: 'test_system',
    promptLoadErrorMessage: 'Prompt unavailable.',
  );
}

SuperdeckAgentClientFactory _fakeAgentFactory(SuperdeckAgentClient agent) {
  return ({
    required String apiKey,
    required String modelName,
    required List<dartantic.Tool> tools,
  }) {
    return agent;
  };
}

class _SessionHarness {
  final uiSubmits = <genui.ChatMessage>[];
  final surfaceUpdates = <genui.SurfaceUpdate>[];
  final textResponses = <String>[];
  final errors = <Object>[];
  var requestStarts = 0;
  var requestFinishes = 0;

  late final ConversationSessionHandlers handlers = ConversationSessionHandlers(
    onRequestStarted: () => requestStarts++,
    onRequestFinished: () => requestFinishes++,
    onUiSubmit: uiSubmits.add,
    onSurfaceUpdate: surfaceUpdates.add,
    onTextResponse: textResponses.add,
    onError: (error, stackTrace) => errors.add(error),
  );
}

class _RestartOnIncomingMessagesTransport extends SuperdeckA2uiTransport {
  _RestartOnIncomingMessagesTransport({
    required super.apiKey,
    required super.modelName,
    required super.systemPrompt,
    required super.tools,
    required super.agentClientFactory,
    required this.onIncomingMessagesListen,
  });

  final void Function() onIncomingMessagesListen;
  late final _messages = StreamController<genui.A2uiMessage>(
    onListen: onIncomingMessagesListen,
  );
  final _text = StreamController<String>();
  var disposed = false;

  @override
  Stream<genui.A2uiMessage> get incomingMessages => _messages.stream;

  @override
  Stream<String> get incomingText => _text.stream;

  @override
  void dispose() {
    if (disposed) return;
    disposed = true;
    unawaited(_messages.close());
    unawaited(_text.close());
    super.dispose();
  }
}

class _ThrowingIncomingMessagesTransport extends SuperdeckA2uiTransport {
  _ThrowingIncomingMessagesTransport({
    required super.apiKey,
    required super.modelName,
    required super.systemPrompt,
    required super.tools,
    required super.agentClientFactory,
  });

  var disposed = false;

  @override
  Stream<genui.A2uiMessage> get incomingMessages {
    throw StateError('bind failed');
  }

  @override
  void dispose() {
    if (disposed) return;
    disposed = true;
    super.dispose();
  }
}
