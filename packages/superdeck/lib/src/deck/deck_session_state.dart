import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

final class DeckSessionState {
  final DeckLoader _deckLoader;

  bool _disposed = false;
  StreamSubscription<SlidesEvent>? _subscription;

  final _loadedSlides = signal<List<Slide>?>(null);
  final _isLoading = signal<bool>(true);
  final _error = signal<Object?>(null);
  final _isBuildActive = signal<bool>(false);
  final _buildFailure = signal<DeckBuildError?>(null);

  DeckSessionState({required DeckLoader deckLoader})
    : _deckLoader = deckLoader {
    _subscription = _deckLoader.load().listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        debugPrint('[DeckSessionState] Loader stream error: $error');
        _applyErrorState(error, '$error');
      },
    );
  }

  ReadonlySignal<List<Slide>?> get loadedSlides => _loadedSlides;
  ReadonlySignal<bool> get isLoading => _isLoading;
  ReadonlySignal<Object?> get error => _error;
  ReadonlySignal<bool> get isBuildActive => _isBuildActive;
  ReadonlySignal<DeckBuildError?> get buildFailure => _buildFailure;
  late final ReadonlySignal<bool> hasFatalError = computed(
    () => _error.value != null && _loadedSlides.value == null,
  );

  void _handleEvent(SlidesEvent event) {
    if (_disposed) return;

    batch(() {
      switch (event) {
        case SlidesLoadingEvent():
          _isLoading.value = true;
          _error.value = null;
        case SlidesLoadedEvent(:final slides):
          _loadedSlides.value = List<Slide>.unmodifiable(slides);
          _isLoading.value = false;
          _error.value = null;
          _isBuildActive.value = false;
          _buildFailure.value = null;
        case SlidesErrorEvent(:final message, :final error):
          _applyErrorState(error ?? message, message);
        case SlidesRebuildingEvent():
          _isBuildActive.value = true;
          _buildFailure.value = null;
      }
    });
  }

  void _applyErrorState(Object? error, String message) {
    batch(() {
      _isLoading.value = false;
      _isBuildActive.value = false;
      if (_loadedSlides.value != null) {
        _buildFailure.value = error is DeckBuildError
            ? error
            : DeckBuildError(message: message);
      } else {
        _error.value = error ?? message;
        _buildFailure.value = null;
      }
    });
  }

  Future<void> reload() async {
    if (_disposed) return;
    batch(() {
      _error.value = null;
      _buildFailure.value = null;
      _isBuildActive.value = false;
      _isLoading.value = true;
    });
    await _deckLoader.reload();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    unawaited(_subscription?.cancel());
    unawaited(_deckLoader.dispose());

    _loadedSlides.dispose();
    _isLoading.dispose();
    _error.dispose();
    _isBuildActive.dispose();
    _buildFailure.dispose();
    hasFatalError.dispose();
  }
}
