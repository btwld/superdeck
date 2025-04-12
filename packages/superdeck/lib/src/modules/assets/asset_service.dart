import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/helpers/provider.dart';
import '../deck/slide_configuration.dart';
import '../slide_capture/slide_capture_service.dart';

// Forward interfaces for types from superdeck_core
class Asset {
  final String id;
  final AssetExtension extension;
  final AssetType type;

  Asset({
    required this.id,
    required this.extension,
    required this.type,
  });

  String get fileName => '${type.name}_$id.${extension.name}';

  static String buildId(String valueToHash) => throw UnimplementedError();

  static Asset thumbnail(String slideKey) => throw UnimplementedError();
  static Asset mermaid(String syntax) => throw UnimplementedError();
  static Asset image(String url, AssetExtension extension) =>
      throw UnimplementedError();
}

enum AssetType {
  thumbnail,
  mermaid,
  image,
  custom;
}

enum AssetExtension {
  png,
  jpeg,
  gif,
  webp,
  svg;

  static AssetExtension? tryParse(String value) => throw UnimplementedError();
}

class AssetSource {
  final String path;
  final Uint8List? bytes;
  final AssetSourceType type;

  AssetSource.file(this.path)
      : bytes = null,
        type = AssetSourceType.file;
  AssetSource.bundle(this.path)
      : bytes = null,
        type = AssetSourceType.bundle;
  AssetSource.memory(this.bytes)
      : path = '',
        type = AssetSourceType.memory;
  AssetSource.url(this.path)
      : bytes = null,
        type = AssetSourceType.url;

  bool get exists => true; // Placeholder
}

enum AssetSourceType {
  file,
  bundle,
  memory,
  url,
}

abstract class AssetStorage {
  Future<AssetSource> getAssetSource(Asset asset);
  Future<bool> assetExists(Asset asset);
  Future<void> saveAsset(Asset asset, Uint8List data);
  Future<void> cleanupUnusedAssets(Set<String> activeAssetIds);
}

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

  /// Process slide content to find and track assets
  Future<void> processSlideContent(SlideConfiguration slideConfig) async {
    // Assume SlideConfiguration holds a Slide object or can provide one
    // If SlideConfiguration doesn't directly hold a Slide, this needs adjustment.
    // For now, assuming slideConfig.slide exists or similar.
    // If not, we might need to fetch the Slide based on the config.
    // Placeholder: Adjust based on actual SlideConfiguration structure
    // final slide = slideConfig.slide; // Hypothetical access - COMMENTED OUT

    // final markdown = _getSlideContent(slide); // COMMENTED OUT

    // Track the slide's thumbnail
    // final thumbnail = slideConfig.thumbnail;
    // if (thumbnail != null) {
    //   await _storage.saveAsset(thumbnail.file, activeAssetIds);
    // }

    // Track generated images
    // final images = slideConfig.generatedImages;
    // for (final image in images) {
    //   if (image.provider.asset != null) {
    //     await _storage.saveAsset(image.provider.asset!, activeAssetIds);
    //   }
    // }

    // TODO: Re-enable markdown processing and asset tracking once Slide access is resolved
    await Future.value(); // Placeholder to keep the method async
  }

  /// Synchronize assets for a deck by tracking all required assets
  /// and cleaning up unused ones
  Future<void> synchronizeDeckAssets(List<SlideConfiguration> slides) async {
    // Clear current tracking
    _activeAssetIds.clear();

    // Process all slides to track their assets
    for (final slide in slides) {
      await processSlideContent(slide);
    }

    // Clean up unused assets
    await storage.cleanupUnusedAssets(_activeAssetIds);
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
}
