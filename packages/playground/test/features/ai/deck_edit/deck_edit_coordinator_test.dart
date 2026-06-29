import 'dart:async';
import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';
import 'package:playground/features/ai/deck_edit/deck_edit_coordinator.dart';
import 'package:playground/stores/deck_customization_store.dart';
import 'package:playground/utils/memory_deck_loader.dart';
import 'package:playground/utils/text_editor_controller.dart';
import 'package:superdeck/superdeck.dart';

import '../../../helpers/fake_superdeck_agent_client.dart';

const _seedMarkdown = '---\ntitle: Seed\n---\n\n# Seed\n';
const _changedMarkdown = '---\ntitle: Changed\n---\n\n# Changed\n';
const _capturedMarkdown = '---\ntitle: Captured\n---\n\n# Captured\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    dotenv.loadFromString(envString: 'GOOGLE_AI_API_KEY=test_api_key');
    PromptRegistry.instance.loadForTest(
      prompts: {'deck_edit_system': 'Deck edit prompt'},
    );
  });

  tearDown(() {
    PromptRegistry.instance.reset();
  });

  test('initializes from the live deck', () async {
    final harness = _DeckEditHarness();
    addTearDown(harness.dispose);
    await harness.load(_seedMarkdown);

    final coordinator = harness.createCoordinator();
    addTearDown(coordinator.dispose);

    final result = await coordinator.initialize();

    expect(result.disposition, DeckEditStartupDisposition.ready);
    expect(coordinator.status.value, DeckEditStatus.ready);
    expect(coordinator.viewModel, isNotNull);
    expect(coordinator.isCompositeIdle, isTrue);
  });

  test(
    'initializes from captured source when outbound writes are suspended',
    () async {
      final harness = _DeckEditHarness();
      addTearDown(harness.dispose);
      harness.textEditorController.suspendOutboundWritesForAiEntry();

      final coordinator = harness.createCoordinator(
        capturedSource: _capturedMarkdown,
      );
      addTearDown(coordinator.dispose);

      final result = await coordinator.initialize();

      expect(result.disposition, DeckEditStartupDisposition.ready);
      expect(
        harness.controller.slides.value.single.slide.options?.title,
        'Captured',
      );
    },
  );

  test(
    'aborts captured-source initialization when editor handoff is invalid',
    () async {
      final harness = _DeckEditHarness();
      addTearDown(harness.dispose);

      final coordinator = harness.createCoordinator(
        capturedSource: _capturedMarkdown,
      );
      addTearDown(coordinator.dispose);

      final result = await coordinator.initialize();

      expect(result.disposition, DeckEditStartupDisposition.abort);
      expect(result.markdown, _capturedMarkdown);
      expect(result.message, contains('Unable to start AI deck editing'));
      expect(coordinator.status.value, DeckEditStatus.error);
    },
  );

  test('apply loads current live markdown and closes the session', () async {
    final agent = FakeSuperdeckAgentClient(chunks: const ['Done']);
    final harness = _DeckEditHarness();
    addTearDown(harness.dispose);
    await harness.load(_seedMarkdown);
    final coordinator = harness.createCoordinator(agent: agent);
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    await coordinator.viewModel!.sendMessage('Tighten the deck');
    await harness.load(_changedMarkdown);

    final result = await coordinator.apply();

    expect(result.disposition, DeckEditBoundaryDisposition.success);
    expect(harness.textEditorController.latestMarkdown, contains('Changed'));
    expect(coordinator.status.value, DeckEditStatus.closed);
    expect(agent.disposed, isTrue);
  });

  test('apply failure keeps the session open', () async {
    final harness = _DeckEditHarness(
      textEditorController: _ThrowingTextEditorController(),
    );
    addTearDown(harness.dispose);
    await harness.load(_seedMarkdown);
    final coordinator = harness.createCoordinator();
    addTearDown(coordinator.dispose);
    await coordinator.initialize();

    final result = await coordinator.apply();

    expect(result.disposition, DeckEditBoundaryDisposition.failure);
    expect(result.message, 'Unable to apply AI edits.');
    expect(result.message, isNot(contains('load failed')));
    expect(coordinator.status.value, DeckEditStatus.ready);
    expect(coordinator.isCompositeIdle, isTrue);
  });

  test('discard restores baseline markdown and closes the session', () async {
    final agent = FakeSuperdeckAgentClient(chunks: const ['Done']);
    final harness = _DeckEditHarness();
    addTearDown(harness.dispose);
    await harness.load(_seedMarkdown);
    final coordinator = harness.createCoordinator(agent: agent);
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    await coordinator.viewModel!.sendMessage('Tighten the deck');
    await harness.load(_changedMarkdown);

    final result = await coordinator.discard();

    expect(result.disposition, DeckEditBoundaryDisposition.success);
    expect(harness.textEditorController.latestMarkdown, contains('Seed'));
    expect(harness.controller.slides.value.single.slide.options?.title, 'Seed');
    expect(coordinator.status.value, DeckEditStatus.closed);
    expect(agent.disposed, isTrue);
  });

  test('discard failure keeps the session open', () async {
    final harness = _DeckEditHarness(
      textEditorController: _ThrowingTextEditorController(),
    );
    addTearDown(harness.dispose);
    await harness.load(_seedMarkdown);
    final coordinator = harness.createCoordinator();
    addTearDown(coordinator.dispose);
    await coordinator.initialize();

    final result = await coordinator.discard();

    expect(result.disposition, DeckEditBoundaryDisposition.failure);
    expect(result.message, 'Unable to discard AI edits.');
    expect(result.message, isNot(contains('load failed')));
    expect(coordinator.status.value, DeckEditStatus.ready);
    expect(coordinator.isCompositeIdle, isTrue);
  });

  test('busy conversation blocks apply/discard boundaries', () async {
    final agent = QueuedSuperdeckAgentClient();
    final harness = _DeckEditHarness(agent: agent);
    addTearDown(harness.dispose);
    await harness.load(_seedMarkdown);
    final coordinator = harness.createCoordinator();
    addTearDown(coordinator.dispose);
    await coordinator.initialize();

    unawaited(coordinator.viewModel!.sendMessage('Keep working'));
    await pumpEventQueue();

    expect(coordinator.isCompositeIdle, isFalse);
    expect(
      (await coordinator.apply()).disposition,
      DeckEditBoundaryDisposition.ignored,
    );
    expect(
      (await coordinator.discard()).disposition,
      DeckEditBoundaryDisposition.ignored,
    );

    agent.completeNext();
    await pumpEventQueue();
  });

  test('dispose while a request is active is safe', () async {
    final agent = QueuedSuperdeckAgentClient();
    final harness = _DeckEditHarness(agent: agent);
    addTearDown(harness.dispose);
    await harness.load(_seedMarkdown);
    final coordinator = harness.createCoordinator();
    await coordinator.initialize();

    unawaited(coordinator.viewModel!.sendMessage('Keep working'));
    await pumpEventQueue();
    coordinator.dispose();
    agent.completeNext();
    await pumpEventQueue();

    expect(agent.disposed, isTrue);
  });
}

class _DeckEditHarness {
  _DeckEditHarness({
    TextEditorController? textEditorController,
    SuperdeckAgentClient? agent,
  }) : textEditorController = textEditorController ?? TextEditorController(),
       agent = agent ?? FakeSuperdeckAgentClient() {
    controller = DeckController(deckLoader: loader, options: DeckOptions());
    customizationStore = DeckCustomizationStore(controller);
  }

  final MemoryDeckLoader loader = MemoryDeckLoader();
  final TextEditorController textEditorController;
  final SuperdeckAgentClient agent;
  late final DeckController controller;
  late final DeckCustomizationStore customizationStore;

  Future<void> load(String markdown) async {
    loader.updateMarkdown(markdown);
    await pumpEventQueue();
  }

  DeckEditCoordinator createCoordinator({
    String? capturedSource,
    SuperdeckAgentClient? agent,
  }) {
    return DeckEditCoordinator(
      deckController: controller,
      loader: loader,
      customizationStore: customizationStore,
      textEditorController: textEditorController,
      captureSlide: (_) async => Uint8List(0),
      isAvailable: () => true,
      capturedSource: capturedSource,
      agentClientFactory:
          ({
            required String apiKey,
            required String modelName,
            required List<dartantic.Tool> tools,
          }) {
            return agent ?? this.agent;
          },
    );
  }

  Future<void> dispose() async {
    customizationStore.dispose();
    controller.dispose();
    textEditorController.dispose();
  }
}

class _ThrowingTextEditorController extends TextEditorController {
  @override
  void loadMarkdown(String markdown) {
    throw StateError('load failed');
  }
}
