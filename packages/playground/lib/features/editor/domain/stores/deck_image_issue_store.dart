import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/domain/generated_image_asset.dart';
import '../../../../core/result.dart';
import '../../../ai/image_generation/image_generator.dart';
import '../../../ai/quick_agent/core/engine/services/error_classifier.dart';
import '../files/deck_file.dart';
import '../files/deck_file_repository.dart';
import '../files/deck_image_manifest.dart';
import 'deck_asset_cache_store.dart';
import 'deck_file_session.dart';

/// Tracks failed generated images for the active deck and retries them on demand.
class DeckImageIssueStore extends ChangeNotifier {
  DeckImageIssueStore({
    required DeckFileSession fileSession,
    required DeckFileRepository repository,
    required ImageGenerator imageGenerator,
    required DeckAssetCacheStore assetCacheStore,
  }) : _fileSession = fileSession,
       _repository = repository,
       _imageGenerator = imageGenerator,
       _assetCacheStore = assetCacheStore {
    _fileSession.addListener(_onSessionChanged);
    unawaited(_loadForActiveDeck());
  }

  final DeckFileSession _fileSession;
  final DeckFileRepository _repository;
  final ImageGenerator _imageGenerator;
  final DeckAssetCacheStore _assetCacheStore;

  DeckFileReference? _loadedReference;
  DeckImageManifest? _manifest;
  final Set<String> _retrying = {};
  String? _errorMessage;
  int _loadEpoch = 0;
  bool _disposed = false;

  List<DeckImageManifestEntry> get issues =>
      _manifest?.images
          .where((image) => image.status == GeneratedImageStatus.failed)
          .toList(growable: false) ??
      const [];

  String? get errorMessage => _errorMessage;

  bool isRetrying(String assetKey) => _retrying.contains(assetKey);

  Future<void> retry(DeckImageManifestEntry entry) async {
    final reference = _loadedReference;
    if (reference == null || _retrying.contains(entry.assetKey)) return;

    _retrying.add(entry.assetKey);
    _errorMessage = null;
    _notify();
    try {
      final result = await _generate(entry);
      final asset = _toAsset(entry, result);
      final persisted = await _repository.updateGeneratedImage(
        reference,
        asset,
      );
      if (_disposed || _loadedReference != reference) return;

      switch (persisted) {
        case Ok():
          _manifest = _manifest?.replace(
            DeckImageManifestEntry.fromAsset(asset),
          );
          if (asset.status == GeneratedImageStatus.ready) {
            _assetCacheStore.refresh();
          }
        case Failure():
          _errorMessage = 'Could not save the image retry. Try again.';
      }
    } catch (_) {
      if (!_disposed && _loadedReference == reference) {
        _errorMessage = 'Could not save the image retry. Try again.';
      }
    } finally {
      _retrying.remove(entry.assetKey);
      if (!_disposed && _loadedReference == reference) _notify();
    }
  }

  Future<ImageGenerationResult> _generate(DeckImageManifestEntry entry) async {
    try {
      return await _imageGenerator.generate(
        ImageGenerationRequest(
          prompt: entry.prompt,
          aspectRatio: entry.aspectRatio,
        ),
      );
    } catch (error) {
      return ImageGenerationFailure(
        const ErrorClassifier().getUserMessage(error),
      );
    }
  }

  GeneratedImageAsset _toAsset(
    DeckImageManifestEntry entry,
    ImageGenerationResult result,
  ) {
    return switch (result) {
      ImageGenerationSuccess(:final bytes) => GeneratedImageAsset.success(
        assetKey: entry.assetKey,
        slideKey: entry.slideKey,
        subject: entry.subject,
        prompt: entry.prompt,
        aspectRatio: entry.aspectRatio,
        bytes: bytes,
      ),
      ImageGenerationFailure(:final message) => GeneratedImageAsset.failure(
        assetKey: entry.assetKey,
        slideKey: entry.slideKey,
        subject: entry.subject,
        prompt: entry.prompt,
        aspectRatio: entry.aspectRatio,
        error: message,
      ),
    };
  }

  void _onSessionChanged() {
    if (_fileSession.boundReference == _loadedReference) return;
    unawaited(_loadForActiveDeck());
  }

  Future<void> _loadForActiveDeck() async {
    final epoch = ++_loadEpoch;
    final reference = _fileSession.boundReference;
    _loadedReference = reference;
    _manifest = null;
    _errorMessage = null;
    _retrying.clear();
    _notify();
    if (reference == null) return;

    final result = await _repository.loadImageManifest(reference);
    if (_disposed || epoch != _loadEpoch) return;
    switch (result) {
      case Ok(:final value):
        _manifest = value;
      case Failure():
        _errorMessage = 'Could not load generated image issues.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadEpoch++;
    _fileSession.removeListener(_onSessionChanged);
    super.dispose();
  }
}
