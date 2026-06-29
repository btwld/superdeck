import 'dart:async';
import 'dart:typed_data';

import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../stores/deck_customization_store.dart';
import '../../../utils/memory_deck_loader.dart';
import '../../../utils/text_editor_controller.dart';
import '../core/debug_logger.dart';
import '../core/ai/services/ai_conversation_viewmodel.dart';
import '../core/ai/services/superdeck_agent_client.dart';
import '../core/tools/deck_tools_adapter.dart';
import '../core/tools/deck_tools_runtime.dart';
import '../core/tools/deck_tools_service.dart';
import '../core/tools/errors.dart';
import '../core/tools/in_memory_deck_store.dart';
import 'deck_edit_conversation_profile.dart';

enum DeckEditStatus { initializing, ready, applying, discarding, error, closed }

enum DeckEditStartupDisposition { ready, abort, cancelled }

final class DeckEditStartupResult {
  const DeckEditStartupResult._({
    required this.disposition,
    this.markdown,
    this.message,
  });

  const DeckEditStartupResult.ready()
    : this._(disposition: DeckEditStartupDisposition.ready);

  const DeckEditStartupResult.cancelled()
    : this._(disposition: DeckEditStartupDisposition.cancelled);

  const DeckEditStartupResult.abort({
    required String markdown,
    required String message,
  }) : this._(
         disposition: DeckEditStartupDisposition.abort,
         markdown: markdown,
         message: message,
       );

  final DeckEditStartupDisposition disposition;
  final String? markdown;
  final String? message;
}

enum DeckEditBoundaryDisposition { success, failure, ignored }

final class DeckEditBoundaryResult {
  const DeckEditBoundaryResult._({required this.disposition, this.message});

  const DeckEditBoundaryResult.success()
    : this._(disposition: DeckEditBoundaryDisposition.success);

  const DeckEditBoundaryResult.ignored()
    : this._(disposition: DeckEditBoundaryDisposition.ignored);

  const DeckEditBoundaryResult.failure(String message)
    : this._(
        disposition: DeckEditBoundaryDisposition.failure,
        message: message,
      );

  final DeckEditBoundaryDisposition disposition;
  final String? message;
}

typedef SlideCaptureForDeckEdit =
    Future<Uint8List> Function(SlideConfiguration configuration);

class DeckEditCoordinator {
  DeckEditCoordinator({
    required DeckController deckController,
    required MemoryDeckLoader loader,
    required DeckCustomizationStore customizationStore,
    required TextEditorController textEditorController,
    required SlideCaptureForDeckEdit captureSlide,
    required bool Function() isAvailable,
    String? capturedSource,
    SuperdeckAgentClientFactory agentClientFactory =
        DartanticSuperdeckAgentClient.new,
  }) : _deckController = deckController,
       _loader = loader,
       _customizationStore = customizationStore,
       _textEditorController = textEditorController,
       _captureSlide = captureSlide,
       _isAvailable = isAvailable,
       _capturedSource = capturedSource,
       _agentClientFactory = agentClientFactory;

  final DeckController _deckController;
  final MemoryDeckLoader _loader;
  final DeckCustomizationStore _customizationStore;
  final TextEditorController _textEditorController;
  final SlideCaptureForDeckEdit _captureSlide;
  final bool Function() _isAvailable;
  final String? _capturedSource;
  final SuperdeckAgentClientFactory _agentClientFactory;

  final status = signal<DeckEditStatus>(DeckEditStatus.initializing);
  final errorMessage = signal<String?>(null);

  InMemoryDeckStore? _store;
  DeckToolsService? _service;
  DeckToolsAdapter? _adapter;
  AiConversationViewModel? _viewModel;
  String? _baselineCanonicalMarkdown;
  DeckCustomizationSnapshot? _baselineCustomizationSnapshot;
  var _disposed = false;

  AiConversationViewModel? get viewModel => _viewModel;

  bool get isCompositeIdle {
    final viewModel = _viewModel;
    final adapter = _adapter;
    final service = _service;
    if (status.value != DeckEditStatus.ready ||
        viewModel == null ||
        adapter == null ||
        service == null) {
      return false;
    }
    return !viewModel.isThinking.value &&
        adapter.isIdle.value &&
        service.isSideEffectQueueIdle.value;
  }

  Future<DeckEditStartupResult> initialize() async {
    if (_disposed) return const DeckEditStartupResult.cancelled();
    if (status.value != DeckEditStatus.initializing) {
      return const DeckEditStartupResult.ready();
    }

    final store = InMemoryDeckStore(
      loader: _loader,
      slidesProvider: _liveSlides,
    );
    String? canonicalForAbort;

    try {
      canonicalForAbort = await _writeEntryMarkdown(store);
      if (_disposed || !_isAvailable()) {
        return const DeckEditStartupResult.cancelled();
      }

      final runtime = DeckToolsRuntime(
        slideConfigurationsProvider: () => _deckController.slides.value,
        applyStyle: _customizationStore.applyFromAiStyle,
        isAvailable: _isAvailable,
        captureSlide: _captureSlide,
      );
      final service = DeckToolsService(documentStore: store, runtime: runtime);
      final adapter = DeckToolsAdapter(service);
      final viewModel = AiConversationViewModel(
        profile: deckEditConversationProfile(toolsAdapter: adapter),
        agentClientFactory: _agentClientFactory,
      );

      _store = store;
      _service = service;
      _adapter = adapter;
      _viewModel = viewModel;
      _baselineCanonicalMarkdown = _serializeLiveSlides();
      _baselineCustomizationSnapshot = _customizationStore.captureSnapshot();
      status.value = DeckEditStatus.ready;
      errorMessage.value = null;
      return const DeckEditStartupResult.ready();
    } catch (error, stackTrace) {
      const message = 'Unable to start AI deck editing.';
      debugLog.error('DECK_EDIT', error, stackTrace);
      status.value = DeckEditStatus.error;
      errorMessage.value = message;
      return DeckEditStartupResult.abort(
        markdown: canonicalForAbort ?? _capturedSource ?? '',
        message: message,
      );
    }
  }

  Future<DeckEditBoundaryResult> apply() async {
    final service = _service;
    if (service == null || !isCompositeIdle) {
      return const DeckEditBoundaryResult.ignored();
    }

    status.value = DeckEditStatus.applying;
    errorMessage.value = null;
    try {
      _textEditorController.loadMarkdown(_serializeLiveSlides());
      _closeToolSession(service);
      status.value = DeckEditStatus.closed;
      return const DeckEditBoundaryResult.success();
    } catch (error, stackTrace) {
      const message = 'Unable to apply AI edits.';
      debugLog.error('DECK_EDIT', error, stackTrace);
      status.value = DeckEditStatus.ready;
      errorMessage.value = message;
      return DeckEditBoundaryResult.failure(message);
    }
  }

  Future<DeckEditBoundaryResult> discard() async {
    final service = _service;
    final store = _store;
    final baselineMarkdown = _baselineCanonicalMarkdown;
    final baselineSnapshot = _baselineCustomizationSnapshot;
    if (service == null ||
        store == null ||
        baselineMarkdown == null ||
        baselineSnapshot == null ||
        !isCompositeIdle) {
      return const DeckEditBoundaryResult.ignored();
    }

    status.value = DeckEditStatus.discarding;
    errorMessage.value = null;
    try {
      await store.writeCanonicalMarkdown(baselineMarkdown);
      _customizationStore.restoreSnapshot(baselineSnapshot);
      _textEditorController.loadMarkdown(baselineMarkdown);
      _closeToolSession(service);
      status.value = DeckEditStatus.closed;
      return const DeckEditBoundaryResult.success();
    } catch (error, stackTrace) {
      const message = 'Unable to discard AI edits.';
      debugLog.error('DECK_EDIT', error, stackTrace);
      status.value = DeckEditStatus.ready;
      errorMessage.value = message;
      return DeckEditBoundaryResult.failure(message);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _viewModel?.dispose();
    _adapter?.dispose();
    _service
      ?..closeSession()
      ..dispose();
    status.value = DeckEditStatus.closed;
    status.dispose();
    errorMessage.dispose();
  }

  Future<String> _writeEntryMarkdown(InMemoryDeckStore store) {
    final capturedSource = _capturedSource;
    if (capturedSource != null) {
      if (!_textEditorController.outboundWritesSuspended) {
        throw DeckToolException.contextUnavailable();
      }
      return store.writeCanonicalMarkdown(capturedSource);
    }

    return store.writeCanonicalMarkdown(_serializeLiveSlides());
  }

  String _serializeLiveSlides() {
    return SlideSerializer().serialize(_liveSlides());
  }

  List<Slide> _liveSlides() {
    return _deckController.slides.value
        .map((configuration) => configuration.slide)
        .toList();
  }

  void _closeToolSession(DeckToolsService service) {
    _viewModel?.restartConversation();
    service.closeSession();
  }
}
