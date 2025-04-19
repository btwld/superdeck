import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

import '../common/helpers/provider.dart';
import '../common/platform_utils.dart';
import '../deck/slide_configuration.dart';

/// Service for handling asset operations
///
/// This service provides methods for loading, caching and
/// managing assets used throughout the application.
class AssetService with ProviderMixin {
  final String assetsRootPath;
  final AssetRepository _assetRepository;

  /// Cache of loaded assets to avoid reloading
  final Map<String, AssetSource> _assetSourceCache = {};

  AssetService({
    required this.assetsRootPath,
    required AssetRepository assetRepository,
  }) : _assetRepository = assetRepository;

  /// Get the asset repository
  AssetRepository get storage => _assetRepository;

  /// Initialize the asset service
  @override
  Future<void> initialize() async {
    // Nothing to initialize yet
  }

  /// Get a source for the given asset
  Future<AssetSource> getAssetSource(Asset asset) async {
    final cacheKey = asset.fileName;

    // Return from cache if available
    if (_assetSourceCache.containsKey(cacheKey)) {
      return _assetSourceCache[cacheKey]!;
    }

    // Get asset source from storage
    final source = await _assetRepository.getAssetSource(asset);

    // Cache if it exists
    if (source.exists) {
      _assetSourceCache[cacheKey] = source;
    }

    return source;
  }

  /// Save asset data and return source
  Future<AssetSource> saveAsset(Asset asset, Uint8List data) async {
    await _assetRepository.saveAsset(asset, data);

    // Clear cache entry to force reload
    _assetSourceCache.remove(asset.fileName);

    // Get updated source
    return getAssetSource(asset);
  }

  /// Get asset source for a mermaid diagram
  Future<AssetSource> getMermaidAsset(String mermaidSyntax) async {
    final asset = Asset.mermaid(mermaidSyntax);
    final assetSource = await getAssetSource(asset);

    // If asset doesn't exist or is empty, generate it
    if (!assetSource.exists || (assetSource.bytes?.isEmpty ?? false)) {
      // This would be implemented in full app with mermaid renderer
      throw UnimplementedError('Mermaid rendering not implemented in core');
    }

    return assetSource;
  }

  /// Get the thumbnail for a slide
  Future<AssetSource> getThumbnail({
    required SlideConfiguration slide,
    required BuildContext context,
    bool force = false,
  }) async {
    final asset = Asset.thumbnail(slide.key);
    return await getAssetSource(asset);
  }

  /// Get the absolute file path for an asset
  String getAssetFilePath(Asset asset) {
    return p.join(assetsRootPath, asset.fileName);
  }

  /// Create an asset repository based on platform
  static AssetRepository createRepository({
    required String assetsPath,
    void Function(String message)? logger,
  }) {
    if (PlatformUtils.isWeb) {
      return InMemoryAssetRepository(
        logger: logger,
        networkFetcher: null, // Would add implementation in full app
      );
    } else {
      final directory = Directory(assetsPath);

      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      return DevFileSystemAssetRepository(
        assetDirectory: directory,
        logger: logger,
      );
    }
  }

  /// Get the AssetService from the widget tree
  static AssetService of(BuildContext context) {
    return InheritedData.of<AssetService>(context);
  }
}
