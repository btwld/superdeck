import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../wizard/core/ai/services/ai_conversation_profile.dart';
import '../../wizard/core/ai/services/ai_conversation_viewmodel.dart';
import '../ai/deck_edit_conversation_profile.dart';
import '../ai/deck_style_applier.dart';
import '../ai/deck_tools_adapter.dart';
import '../data/deck_slide_reader.dart';
import '../data/editor_deck_store.dart';
import '../domain/deck_tool_error.dart';
import '../domain/deck_tools_service.dart';
import '../routes/routes.dart';

typedef DeckEditConversationFactory =
    AiConversationViewModel Function(AiConversationProfile profile);

/// Route-owned state machine for one ephemeral AI deck-editing session.
final class DeckEditSessionController extends ChangeNotifier {
  DeckEditSessionController({
    required this.args,
    required DeckController deckController,
    required DeckCustomizationStore customizationStore,
    required BuildContext routeContext,
    DeckEditConversationFactory? conversationFactory,
    SlideCaptureCallback? capture,
  }) : _customizationStore = customizationStore {
    _deckStore = EditorDeckStore(
      documentStore: args.documentStore,
      deckController: deckController,
    );
    final styleApplier = DeckStyleApplier(
      customizationStore: customizationStore,
      deckStore: _deckStore,
    );
    final slideReader = DeckSlideReader(
      context: routeContext,
      deckController: deckController,
      capture: capture,
    );
    _tools = DeckToolsService(
      deckStore: _deckStore,
      readSlide: slideReader.read,
      updateStyle: styleApplier.update,
      onDirty: _markDirty,
    );
    final profile = deckEditConversationProfile(DeckToolsAdapter(_tools));
    viewModel = (conversationFactory ?? _defaultConversationFactory)(profile);
    viewModel.onUiRequest = _trackUiRequest;
  }

  final DeckEditRouteArgs args;
  final DeckCustomizationStore _customizationStore;

  late final EditorDeckStore _deckStore;
  late final DeckToolsService _tools;
  late final AiConversationViewModel viewModel;

  bool _ready = false;
  bool _requestInFlight = false;
  bool _dirty = false;
  bool _disposed = false;
  String? _entryError;
  String? _restoreError;

  DeckToolsService get tools => _tools;
  bool get ready => _ready;
  bool get requestInFlight => _requestInFlight;
  bool get dirty => _dirty;
  String? get entryError => _entryError;
  String? get restoreError => _restoreError;

  static AiConversationViewModel _defaultConversationFactory(
    AiConversationProfile profile,
  ) => AiConversationViewModel(profile: profile);

  Future<void> initialize() async {
    if (_disposed || _requestInFlight) return;
    _entryError = null;
    _setRequestInFlight(true);
    try {
      await _deckStore.synchronize();
      if (_disposed) return;
      _ready = true;
    } catch (error) {
      if (_disposed) return;
      _ready = false;
      _entryError = _messageFor(
        error,
        'The current deck is not ready to edit.',
      );
    } finally {
      if (!_disposed) {
        _setRequestInFlight(false);
      }
    }
  }

  Future<void> sendMessage(String value) async {
    if (!_ready || _requestInFlight || value.trim().isEmpty || _disposed) {
      return;
    }
    _setRequestInFlight(true);
    try {
      await viewModel.sendMessage(value);
    } finally {
      if (!_disposed) {
        _setRequestInFlight(false);
      }
    }
  }

  Future<bool> apply() async {
    if (_requestInFlight || _disposed) return false;
    _tools.close();
    try {
      final slideCount = _deckStore.read().length;
      args.editorStore.activeSlideIndex = _clampedEntryIndex(slideCount);
      _dirty = false;
      notifyListeners();
      return true;
    } catch (error) {
      _restoreError = _messageFor(error, 'Could not keep the current changes.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> discard() async {
    if (_requestInFlight || _disposed) return false;
    _tools.close();
    _restoreError = null;
    _setRequestInFlight(true);
    try {
      await _deckStore.restore(args.baselineMarkdown);
      _customizationStore.restoreSnapshot(args.baselineCustomization);
      args.editorStore.activeSlideIndex = args.baselineSlideIndex;
      _dirty = false;
      return true;
    } catch (error) {
      _restoreError = _messageFor(
        error,
        'Could not restore the original deck.',
      );
      return false;
    } finally {
      if (!_disposed) _setRequestInFlight(false);
    }
  }

  void _markDirty() {
    if (_disposed) return;
    _dirty = true;
    notifyListeners();
  }

  void _trackUiRequest(Future<void> request) {
    if (_disposed) return;
    _setRequestInFlight(true);
    unawaited(
      request.whenComplete(() {
        if (!_disposed) {
          _setRequestInFlight(false);
        }
      }),
    );
  }

  void _setRequestInFlight(bool value) {
    if (_requestInFlight == value) return;
    _requestInFlight = value;
    notifyListeners();
  }

  int _clampedEntryIndex(int slideCount) {
    if (slideCount <= 0) return 0;
    return args.baselineSlideIndex.clamp(0, slideCount - 1);
  }

  String _messageFor(Object error, String fallback) {
    return switch (error) {
      DeckToolError(:final message) => message,
      _ => fallback,
    };
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _tools.close();
    viewModel.onUiRequest = null;
    viewModel.dispose();
    super.dispose();
  }
}
