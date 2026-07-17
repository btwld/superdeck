import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:playground/features/ai/quick_agent/core/constants/gemini_models.dart';
import 'package:playground/features/ai/wizard/chat/chat_conversation_profile.dart';
import 'package:playground/features/ai/wizard/core/ai/services/ai_conversation_viewmodel.dart';
import 'package:playground/features/ai/wizard/core/ai/services/superdeck_agent_client.dart';
import 'package:playground/features/ai/wizard/core/ai/wizard_session_state.dart';

const _runLiveWizardModelTests = bool.fromEnvironment(
  'RUN_LIVE_WIZARD_MODEL_TESTS',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This suite is explicitly opt-in and exercises real model transports.
  HttpOverrides.global = null;

  test(
    'completes the canonical six-step Wizard flow',
    () async {
      final modelRequests = <Map<String, Object?>>[];
      SuperdeckAgentClient recordingFactory({
        required String apiKey,
        required String modelName,
        required List<dartantic.Tool> tools,
      }) => _RecordingAgentClient(
        delegate: DartanticSuperdeckAgentClient(
          apiKey: apiKey,
          modelName: modelName,
          tools: tools,
        ),
        requests: modelRequests,
      );

      final viewModel = AiConversationViewModel(
        profile: chatConversationProfile(),
        agentClientFactory: recordingFactory,
      );
      addTearDown(viewModel.dispose);

      final turns = <Map<String, Object?>>[];
      Object? failure;
      StackTrace? failureStack;
      try {
        await _runTopicTurn(
          viewModel,
          turns,
          topic:
              'A playful guide to how giraffes live, learn, and help their ecosystems',
          expectedStep: .audience,
          expectedComponent: 'AskUserRadio',
        );
        await _runActionTurn(
          viewModel,
          turns,
          context: {'selectedOption': 'Curious families'},
          expectedStep: .approach,
          expectedComponent: 'AskUserRadio',
        );
        await _runActionTurn(
          viewModel,
          turns,
          context: {'selectedOption': 'Visual story with surprising facts'},
          expectedStep: .emphasis,
          expectedComponent: 'AskUserCheckbox',
        );
        await _runActionTurn(
          viewModel,
          turns,
          context: {
            'selectedOptions': [
              'Giraffe adaptations',
              'Social behavior',
              'Conservation',
            ],
          },
          expectedStep: .slideCount,
          expectedComponent: 'AskUserSlider',
        );
        await _runActionTurn(
          viewModel,
          turns,
          context: {'value': 10},
          expectedStep: .theme,
          expectedComponent: 'AskUserStyle',
        );
        await _runActionTurn(
          viewModel,
          turns,
          context: {'themeId': 'technical-paper'},
          expectedStep: .imageStyle,
          expectedComponent: 'AskUserImageStyle',
        );

        viewModel.controller!.handleUiEvent(
          genui.UserActionEvent(
            surfaceId: 'wizard',
            name: 'submit_answer',
            sourceComponentId: 'root',
            context: const {
              'imageStyleId': 'minimalist',
              'imageStyleVersion': 1,
            },
          ),
        );
        await _waitUntil(
          () => viewModel.wizardState.isReviewReady,
          description: 'Wizard review state',
        );
      } catch (error, stackTrace) {
        failure = error;
        failureStack = stackTrace;
      }

      final totalTurnMs = turns.fold<int>(
        0,
        (total, turn) => total + (turn['elapsedMs']! as int),
      );
      final artifact = {
        'provider': 'gemini',
        'model': GeminiModelNames.gemini31FlashLite,
        'turnCount': turns.length,
        'totalTurnMs': totalTurnMs,
        'averageTurnMs': turns.isEmpty ? null : totalTurnMs ~/ turns.length,
        'valid': failure == null && viewModel.wizardState.isReviewReady,
        'error': failure?.toString(),
        'turns': turns,
        'modelRequests': modelRequests,
      };
      final artifactPath = await _writeArtifact(artifact);
      // ignore: avoid_print
      print('Wizard benchmark artifact: ${artifactPath.path}');
      // ignore: avoid_print
      print(const JsonEncoder.withIndent('  ').convert(artifact));

      if (failure != null) {
        Error.throwWithStackTrace(failure, failureStack!);
      }
      expect(viewModel.wizardState.isReviewReady, isTrue);
      expect(turns, hasLength(6));
    },
    skip: !_runLiveWizardModelTests,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> _runTopicTurn(
  AiConversationViewModel viewModel,
  List<Map<String, Object?>> turns, {
  required String topic,
  required WizardStep expectedStep,
  required String expectedComponent,
}) async {
  final stopwatch = Stopwatch()..start();
  await viewModel.sendMessage(topic);
  await _waitForComponent(viewModel, expectedStep, expectedComponent);
  stopwatch.stop();
  turns.add(_turnResult(viewModel, expectedComponent, stopwatch.elapsed));
}

Future<void> _runActionTurn(
  AiConversationViewModel viewModel,
  List<Map<String, Object?>> turns, {
  required Map<String, Object?> context,
  required WizardStep expectedStep,
  required String expectedComponent,
}) async {
  final stopwatch = Stopwatch()..start();
  viewModel.controller!.handleUiEvent(
    genui.UserActionEvent(
      surfaceId: 'wizard',
      name: 'submit_answer',
      sourceComponentId: 'root',
      context: context,
    ),
  );
  await _waitForComponent(viewModel, expectedStep, expectedComponent);
  stopwatch.stop();
  turns.add(_turnResult(viewModel, expectedComponent, stopwatch.elapsed));
}

Future<void> _waitForComponent(
  AiConversationViewModel viewModel,
  WizardStep expectedStep,
  String expectedComponent,
) async {
  await _waitUntil(() {
    if (viewModel.errorMessage case final error?) {
      throw StateError(error);
    }
    final controller = viewModel.controller;
    final surface = controller?.registry.getSurface('wizard');
    return viewModel.wizardState.step == expectedStep &&
        !viewModel.isThinking.value &&
        controller?.activeSurfaceIds.length == 1 &&
        surface?.components['root']?.type == expectedComponent;
  }, description: expectedComponent);
}

Future<void> _waitUntil(
  bool Function() predicate, {
  required String description,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException('Timed out waiting for $description.');
}

Map<String, Object?> _turnResult(
  AiConversationViewModel viewModel,
  String component,
  Duration elapsed,
) => {
  'step': viewModel.wizardState.step.name,
  'component': component,
  'elapsedMs': elapsed.inMilliseconds,
};

Future<File> _writeArtifact(Map<String, Object?> artifact) async {
  final timestamp = DateTime.now()
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  final directory = Directory('test_live/wizard/artifacts');
  await directory.create(recursive: true);
  final provider = artifact['provider'];
  final file = File('${directory.path}/${provider}_$timestamp.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(artifact),
  );
  return file;
}

final class _RecordingAgentClient implements SuperdeckAgentClient {
  _RecordingAgentClient({required this.delegate, required this.requests});

  final SuperdeckAgentClient delegate;
  final List<Map<String, Object?>> requests;

  @override
  void dispose() => delegate.dispose();

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    final stopwatch = Stopwatch()..start();
    final output = StringBuffer();
    Object? error;
    try {
      await for (final chunk in delegate.sendStream(prompt, history: history)) {
        output.write(chunk.text);
        yield chunk;
      }
    } catch (caught) {
      error = caught;
      rethrow;
    } finally {
      stopwatch.stop();
      requests.add({
        'promptChars': prompt.length,
        'historyMessages': history.length,
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'output': output.toString(),
        'error': error?.toString(),
      });
    }
  }
}
