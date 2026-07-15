import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:playground/features/ai/wizard/chat/chat_conversation_profile.dart';
import 'package:playground/features/ai/wizard/core/ai/wizard_session_state.dart';
import 'package:playground/features/ai/wizard/core/ai/services/ai_conversation_viewmodel.dart';
import 'package:playground/features/ai/wizard/core/ai/services/genui_conversation_session.dart';
import 'package:playground/features/ai/wizard/core/ai/services/superdeck_agent_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('missing Wizard surfaces', () {
    test('requests recovery when the first response has no surface', () {
      expect(
        decideMissingSurfaceAction(
          hasError: false,
          hasController: true,
          requestProducedSurface: false,
          recoveryAttempts: 0,
        ),
        MissingSurfaceAction.recover,
      );
    });

    test('requests recovery when a later response has no new surface', () {
      expect(
        decideMissingSurfaceAction(
          hasError: false,
          hasController: true,
          requestProducedSurface: false,
          recoveryAttempts: 0,
        ),
        MissingSurfaceAction.recover,
      );
    });

    test('shows an error after one surface recovery attempt', () {
      expect(
        decideMissingSurfaceAction(
          hasError: false,
          hasController: true,
          requestProducedSurface: false,
          recoveryAttempts: 1,
        ),
        MissingSurfaceAction.showError,
      );
    });
  });

  test('accepts only the root component for the canonical Wizard step', () {
    genui.SurfaceDefinition surface(String type) => genui.SurfaceDefinition(
      surfaceId: 'wizard',
      components: {
        'root': genui.Component(id: 'root', type: type, properties: const {}),
      },
    );

    expect(
      isExpectedWizardSurface(surface('AskUserCheckbox'), WizardStep.emphasis),
      isTrue,
    );
    expect(
      isExpectedWizardSurface(surface('AskUserRadio'), WizardStep.emphasis),
      isFalse,
    );
    expect(expectedWizardComponentType(WizardStep.theme), 'AskUserStyle');
  });

  test('turn prompt pins canonical selections and the expected next step', () {
    final state = WizardSessionState.initial()
        .startTopic('Urban gardens')!
        .advance({'selectedOption': 'City planners'})!;

    final prompt = buildWizardTurnPrompt(
      userInput: 'The user selected City planners.',
      state: state,
    );

    expect(prompt, contains('"topic":"Urban gardens"'));
    expect(prompt, contains('"audience":"City planners"'));
    expect(prompt, contains('Expected next step: approach'));
    expect(prompt, contains('exactly one approach surface'));
  });

  test('ignores a second topic while the first request is starting', () async {
    final client = _DelayedAgentClient();
    final viewModel = AiConversationViewModel(
      profile: chatConversationProfile(),
      apiKey: 'test-key',
      agentClientFactory:
          ({required apiKey, required modelName, required tools}) => client,
    );

    final first = viewModel.sendMessage('First topic');
    await client.started.future.timeout(const Duration(seconds: 2));
    await viewModel.sendMessage('Second topic');

    expect(client.requestCount, 1);
    expect(viewModel.wizardState.context.topic, 'First topic');

    viewModel.dispose();
    client.release.complete();
    await first;
  });

  test('Wizard system prompt permits its single-surface replacement flow', () {
    final session = GenUiConversationSession(
      profile: chatConversationProfile(),
      handlers: ConversationSessionHandlers(
        onRequestStarted: () {},
        onRequestFinished: () {},
        onUiSubmit: (_) {},
        onSurfaceUpdate: (_) {},
        onTextResponse: (_) {},
        onError: (_, _) {},
      ),
    );
    addTearDown(session.dispose);

    final prompt = session.buildSystemPromptForTesting(
      'Replace the `wizard` surface by deleting it, then creating it again.',
    );

    expect(prompt, contains('deleteSurface'));
    expect(prompt, contains('To update an existing UI'));
    expect(
      prompt,
      isNot(
        contains('DO NOT update or modify surfaces created in previous turns'),
      ),
    );
  });

  test(
    'Wizard instructions update one persistent surface without text',
    () async {
      final prompt = await rootBundle.loadString(
        'assets/ai_prompts/wizard_system.prompt',
      );

      expect(prompt, contains('updateComponents'));
      expect(prompt, contains('surface messages only'));
      expect(prompt, isNot(contains('provideFinalOutput')));
      expect(prompt, isNot(contains('deleteSurface')));
      expect(prompt, isNot(contains('beginRendering')));
    },
  );
}

final class _DelayedAgentClient implements SuperdeckAgentClient {
  final started = Completer<void>();
  final release = Completer<void>();
  var requestCount = 0;

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    requestCount++;
    if (!started.isCompleted) started.complete();
    await release.future;
  }

  @override
  void dispose() {}
}
