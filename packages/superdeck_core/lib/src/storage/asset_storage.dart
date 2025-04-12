import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../models/asset_model.dart';
import '../models/asset_source.dart';

/// Abstract class defining the interface for asset storage operations
abstract class AssetStorage {
  /// Get a source for the asset, which can be used to access it
  Future<AssetSource> getAssetSource(Asset asset);

  /// Check if an asset exists in storage
  Future<bool> assetExists(Asset asset);

  /// Save an asset to storage
  Future<void> saveAsset(Asset asset, Uint8List data);

  /// Clean up unused assets from storage
  Future<void> cleanupUnusedAssets(Set<String> activeAssetIds);
}

/// Platform detection helpers - to be determined at the app level
/// rather than in the core package
class PlatformHelper {
  /// Whether the platform is development mode (vs production)
  static bool get isDevelopment => false;

  /// Whether the platform is web
  static bool get isWeb => false;
}

/// Implementation for development environments with direct file system access
class DevFileSystemAssetStorage implements AssetStorage {
  final Directory assetDirectory;
  final void Function(String message)? logger;

  DevFileSystemAssetStorage({
    required this.assetDirectory,
    this.logger,
  });

  @override
  Future<AssetSource> getAssetSource(Asset asset) async {
    final filePath = p.join(assetDirectory.path, asset.fileName);
    return AssetSource.file(filePath);
  }

  @override
  Future<bool> assetExists(Asset asset) async {
    final filePath = p.join(assetDirectory.path, asset.fileName);
    return File(filePath).exists();
  }

  @override
  Future<void> saveAsset(Asset asset, Uint8List data) async {
    final filePath = p.join(assetDirectory.path, asset.fileName);
    final file = File(filePath);

    // Create directory if it doesn't exist
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    await file.writeAsBytes(data);
  }

  @override
  Future<void> cleanupUnusedAssets(Set<String> activeAssetIds) async {
    if (!await assetDirectory.exists()) {
      return;
    }

    // Get all files in the asset directory
    final files = await assetDirectory
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    for (final file in files) {
      final fileName = p.basename(file.path);

      // Extract asset ID from filename (format is "{type}_{id}.{extension}")
      final parts = fileName.split('_');
      if (parts.length < 2) {
        continue; // Skip files with unexpected naming pattern
      }

      final type = parts[0];
      final idWithExt = parts.sublist(1).join('_');
      final id = idWithExt.split('.').first;

      final assetKey = '${type}_$id';

      // If this asset is not in the active set, delete it
      if (!activeAssetIds.contains(assetKey)) {
        try {
          await file.delete();
          logger?.call('Deleted unused asset: ${file.path}');
        } catch (e) {
          logger?.call('Error deleting unused asset: $e');
        }
      }
    }
  }
}

/// Implemented by platform-specific code to provide bundle-related functionality
abstract class AssetBundleAccessor {
  /// Check if a bundled asset exists
  Future<bool> assetExists(String path);

  /// Load asset bytes from the bundle
  Future<Uint8List> load(String path);
}

/// Implementation for compiled native apps using asset bundles
class BundledAssetStorage implements AssetStorage {
  final AssetBundleAccessor bundleAccessor;
  final Directory cacheDirectory;
  final void Function(String message)? logger;

  BundledAssetStorage({
    required this.bundleAccessor,
    required this.cacheDirectory,
    this.logger,
  });

  @override
  Future<AssetSource> getAssetSource(Asset asset) async {
    // Try to get from bundle first
    final bundlePath = 'assets/${asset.fileName}';

    try {
      // Check if asset exists in bundle
      if (await bundleAccessor.assetExists(bundlePath)) {
        return AssetSource.bundle(bundlePath);
      }
    } catch (_) {
      // Bundle access failed
    }

    // If not in bundle, check cache directory
    final cachePath = p.join(cacheDirectory.path, asset.fileName);
    if (await File(cachePath).exists()) {
      return AssetSource.file(cachePath);
    }

    // Asset doesn't exist yet
    return AssetSource.file(cachePath); // Return future path
  }

  @override
  Future<bool> assetExists(Asset asset) async {
    try {
      final bundlePath = 'assets/${asset.fileName}';
      return await bundleAccessor.assetExists(bundlePath);
    } catch (_) {
      final cachePath = p.join(cacheDirectory.path, asset.fileName);
      return File(cachePath).exists();
    }
  }

  @override
  Future<void> saveAsset(Asset asset, Uint8List data) async {
    // Can't modify the asset bundle, so save to cache directory
    final cachePath = p.join(cacheDirectory.path, asset.fileName);
    final file = File(cachePath);

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    await file.writeAsBytes(data);
  }

  @override
  Future<void> cleanupUnusedAssets(Set<String> activeAssetIds) async {
    // Only clean up cache directory, not the bundle
    if (!await cacheDirectory.exists()) {
      return;
    }

    final files = await cacheDirectory
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    for (final file in files) {
      final fileName = p.basename(file.path);

      // Extract asset ID from filename (format is "{type}_{id}.{extension}")
      final parts = fileName.split('_');
      if (parts.length < 2) continue;

      final type = parts[0];
      final idWithExt = parts.sublist(1).join('_');
      final id = idWithExt.split('.').first;

      final assetKey = '${type}_$id';

      // If this asset is not in the active set, delete it
      if (!activeAssetIds.contains(assetKey)) {
        try {
          await file.delete();
          logger?.call('Deleted unused cached asset: ${file.path}');
        } catch (e) {
          logger?.call('Error deleting unused cached asset: $e');
        }
      }
    }
  }
}

/// Implementation for web platforms using in-memory storage
class InMemoryAssetStorage implements AssetStorage {
  final Map<String, Uint8List> _memoryAssets = {};
  final NetworkFetcher? networkFetcher;
  final void Function(String message)? logger;

  InMemoryAssetStorage({
    this.networkFetcher,
    this.logger,
  });

  @override
  Future<AssetSource> getAssetSource(Asset asset) async {
    if (_memoryAssets.containsKey(asset.fileName)) {
      return AssetSource.memory(_memoryAssets[asset.fileName]!);
    }

    // Try to load from network if available
    if (networkFetcher != null) {
      try {
        final assetPath = 'assets/${asset.fileName}';
        final bytes = await networkFetcher!.fetchBytes(assetPath);
        if (bytes != null) {
          _memoryAssets[asset.fileName] = bytes;
          return AssetSource.memory(bytes);
        }
      } catch (_) {
        // Network asset not available
      }
    }

    // Return empty memory source that will need to be generated
    return AssetSource.memory(Uint8List(0));
  }

  @override
  Future<bool> assetExists(Asset asset) async {
    if (_memoryAssets.containsKey(asset.fileName)) {
      return true;
    }

    if (networkFetcher != null) {
      try {
        final assetPath = 'assets/${asset.fileName}';
        return await networkFetcher!.exists(assetPath);
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  @override
  Future<void> saveAsset(Asset asset, Uint8List data) async {
    _memoryAssets[asset.fileName] = data;
  }

  @override
  Future<void> cleanupUnusedAssets(Set<String> activeAssetIds) async {
    // Clean up in-memory assets
    final keysToRemove = <String>[];

    for (final fileName in _memoryAssets.keys) {
      // Extract type and id from filename
      final parts = fileName.split('_');
      if (parts.length < 2) continue;

      final type = parts[0];
      final idWithExt = parts.sublist(1).join('_');
      final id = idWithExt.split('.').first;

      final assetKey = '${type}_$id';

      if (!activeAssetIds.contains(assetKey)) {
        keysToRemove.add(fileName);
      }
    }

    for (final key in keysToRemove) {
      _memoryAssets.remove(key);
      logger?.call('Removed unused in-memory asset: $key');
    }
  }
}

/// Interface for fetching assets from the network
abstract class NetworkFetcher {
  /// Check if an asset exists at the given URL
  Future<bool> exists(String url);

  /// Fetch bytes from the given URL
  Future<Uint8List?> fetchBytes(String url);
}

/// Factory for creating appropriate AssetStorage instances based on platform
class DefaultAssetStorageFactory {
  /// Creates the appropriate asset storage implementation based on platform
  /// considerations.
  ///
  /// [assetDirectory] - Directory where assets are stored
  /// [cacheDirectory] - Directory for caching assets (only used in bundled mode)
  /// [bundleAccessor] - Accessor for bundled assets (only used in bundled mode)
  /// [networkFetcher] - Fetcher for network assets (only used in web mode)
  /// [isDevelopment] - Whether the app is running in development mode
  /// [isWeb] - Whether the app is running on the web platform
  /// [logger] - Optional logger function for debugging
  static AssetStorage create({
    required Directory assetDirectory,
    Directory? cacheDirectory,
    AssetBundleAccessor? bundleAccessor,
    NetworkFetcher? networkFetcher,
    bool isDevelopment = false,
    bool isWeb = false,
    void Function(String message)? logger,
  }) {
    if (isWeb) {
      logger?.call('Creating InMemoryAssetStorage for web platform');
      return InMemoryAssetStorage(
        networkFetcher: networkFetcher,
        logger: logger,
      );
    } else if (isDevelopment) {
      logger?.call('Creating DevFileSystemAssetStorage for development');
      return DevFileSystemAssetStorage(
        assetDirectory: assetDirectory,
        logger: logger,
      );
    } else {
      if (bundleAccessor == null) {
        throw ArgumentError(
            'bundleAccessor is required for bundled asset storage');
      }
      if (cacheDirectory == null) {
        throw ArgumentError(
            'cacheDirectory is required for bundled asset storage');
      }

      logger?.call('Creating BundledAssetStorage for production');
      return BundledAssetStorage(
        bundleAccessor: bundleAccessor,
        cacheDirectory: cacheDirectory,
        logger: logger,
      );
    }
  }
}
