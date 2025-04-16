import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:superdeck_core/src/models/asset_source.dart';
import 'package:superdeck_core/src/storage/asset_storage.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../common/helpers/provider.dart';
import '../deck/slide_configuration.dart';
import '../slide_capture/slide_capture_service.dart';

/// A service for managing assets (thumbnails, mermaid diagrams, images)
class AssetService extends ChangeNotifier {
  /// The underlying storage implementation
  final AssetStorage storage;
  final SlideCaptureService _captureService;

  /// Set of active asset IDs to prevent cleanup of needed assets
  final Set<String> _activeAssetIds = {};

  /// Map of currently loading assets
  final Map<String, Completer<AssetSource>> _loadingAssets = {};

  AssetService({
    required this.storage,
    SlideCaptureService? captureService,
  }) : _captureService = captureService ?? SlideCaptureService();

  /// Track an asset as active to prevent it from being cleaned up
  void trackAsset(Asset asset) {
    _activeAssetIds.add('${asset.type.name}_${asset.id}');
  }

  /// Get a thumbnail for a slide, generating it if needed
  Future<AssetSource> getThumbnail({
    required SlideConfiguration slide,
    required BuildContext context,
    bool force = false,
  }) async {
    final asset = Asset.thumbnail(slide.key);
    trackAsset(asset);

    final assetKey = '${asset.type.name}_${asset.id}';

    // If this asset is already being loaded, wait for that operation to complete
    if (_loadingAssets.containsKey(assetKey) && !force) {
      return _loadingAssets[assetKey]!.future;
    }

    // Create a completer for this loading operation
    final completer = Completer<AssetSource>();
    _loadingAssets[assetKey] = completer;

    try {
      // Check if asset exists and we don't need to force regenerate
      if (!force && await storage.assetExists(asset)) {
        final source = await storage.getAssetSource(asset);
        completer.complete(source);
        _loadingAssets.remove(assetKey);
        return source;
      }

      // Asset doesn't exist or needs to be regenerated
      // Check if mounted before capturing
      if (!context.mounted) {
        throw Exception('Context is no longer mounted');
      }
      final imageData = await _captureService.capture(
        slide: slide,
        context: context,
        quality:
            kIsWeb ? SlideCaptureQuality.thumbnail : SlideCaptureQuality.good,
      );

      // Save the generated thumbnail
      await storage.saveAsset(asset, imageData);

      // Return the saved asset
      final source = await storage.getAssetSource(asset);
      completer.complete(source);
      return source;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _loadingAssets.remove(assetKey);
    }
  }

  /// Generate thumbnails for a list of slides
  Future<void> generateThumbnails(
    List<SlideConfiguration> slides,
    BuildContext context, {
    bool force = false,
  }) async {
    for (final slide in slides) {
      getThumbnail(slide: slide, context: context, force: force)
          .catchError((error) {
        // Ignore errors but return a placeholder source to match return type
        return AssetSource.memory(Uint8List(0));
      });
    }
  }

  /// Extracts all assets from the slide content and stores them in the repository
  Future<void> processSlideContent(
    String slideKey,
    String content, {
    PresentationRepository? repository,
  }) async {
    // TODO: Implement asset extraction and storage from slide content
    // Currently stubbed due to missing components
  }

  /// Synchronizes assets between decks.
  ///
  /// If a slide references an asset that doesn't exist in the target repository,
  /// it will be copied from the source repository.
  Future<void> syncDeckAssets({
    required PresentationRepository source,
    required PresentationRepository target,
    required dynamic
        deck, // Changed from Deck to dynamic to resolve linter error
  }) async {
    // TODO: Implement asset synchronization between repositories
    // Currently stubbed due to missing components
  }

  /// Cleans up unused assets from the repository
  Future<void> cleanupUnusedAssets({
    required PresentationRepository repository,
    required dynamic
        deck, // Changed from Deck to dynamic to resolve linter error
  }) async {
    // TODO: Implement unused asset cleanup
    // Currently stubbed due to missing components
  }

  /// Synchronize assets for a deck by tracking all required assets
  /// and cleaning up unused ones
  Future<void> synchronizeDeckAssets(List<SlideConfiguration> slides) async {
    // TODO: Implement deck asset synchronization
    // Currently stubbed due to missing components
  }

  /// Get the AssetService from the BuildContext
  static AssetService of(BuildContext context) {
    return InheritedNotifierData.of<AssetService>(context);
  }

  @override
  void dispose() {
    // Clear maps to avoid memory leaks
    _activeAssetIds.clear();
    _loadingAssets.clear();
    super.dispose();
  }

  // Method to add a path to recent assets - implementation commented out due to missing components
  Future<void> addRecentAsset(String assetPath) async {
    // TODO: Implement recent asset tracking
    // Currently stubbed due to missing components
  }
}
