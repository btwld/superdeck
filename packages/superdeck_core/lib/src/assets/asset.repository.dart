import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'models/asset.model.dart';
import 'models/source.model.dart';

/// Abstract class defining the interface for asset storage operations
abstract class AssetRepository {
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
class DevFileSystemAssetRepository implements AssetRepository {
  final Directory assetDirectory;
  final void Function(String message)? logger;

  DevFileSystemAssetRepository({
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
class BundledAssetRepository implements AssetRepository {
  final AssetBundleAccessor bundleAccessor;
  final Directory cacheDirectory;
  final void Function(String message)? logger;

  BundledAssetRepository({
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
class InMemoryAssetRepository implements AssetRepository {
  final Map<String, Uint8List> _memoryAssets = {};
  final NetworkFetcher? networkFetcher;
  final void Function(String message)? logger;

  InMemoryAssetRepository({
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
      return _memoryAssets[asset.fileName]!.isNotEmpty;
    }

    if (networkFetcher != null) {
      try {
        final assetPath = 'assets/${asset.fileName}';
        return await networkFetcher!.exists(assetPath);
      } catch (_) {
        // Network check failed
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
    // Get list of asset filenames
    final assetFilenames = _memoryAssets.keys.toList();

    for (final fileName in assetFilenames) {
      // Extract asset ID from filename (format is "{type}_{id}.{extension}")
      final parts = fileName.split('_');
      if (parts.length < 2) continue;

      final type = parts[0];
      final idWithExt = parts.sublist(1).join('_');
      final id = idWithExt.split('.').first;

      final assetKey = '${type}_$id';

      // If this asset is not in the active set, delete it
      if (!activeAssetIds.contains(assetKey)) {
        _memoryAssets.remove(fileName);
        logger?.call('Removed unused memory asset: $fileName');
      }
    }
  }
}

/// Helper for fetching network resources (implemented by platform)
abstract class NetworkFetcher {
  /// Fetch bytes from a network path
  Future<Uint8List?> fetchBytes(String path);

  /// Check if a network path exists
  Future<bool> exists(String path);
}
