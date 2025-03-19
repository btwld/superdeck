import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/log_utils.dart';
import '../utils/string_utils.dart';
import 'asset_reference.dart';

/// Manager for asset handling
class AssetManager {
  /// Root directory for assets
  final String rootDir;

  /// Output directory for processed assets
  final String outputDir;

  /// Assets that have been registered
  final Map<String, AssetReference> _assets = {};

  /// Create a new asset manager
  AssetManager({
    required this.rootDir,
    required this.outputDir,
  });

  /// Register an asset
  /// Returns a reference to the registered asset
  AssetReference registerAsset({
    required String source,
    String? destination,
    AssetType? type,
    Map<String, dynamic>? metadata,
  }) {
    // Determine the asset type if not provided
    final assetType = type ?? _detectAssetType(source);

    // Determine destination path if not provided
    final assetDestination =
        destination ?? _generateDestinationPath(source, assetType);

    // Create the asset reference
    final asset = AssetReference(
      source: source,
      destination: assetDestination,
      type: assetType,
      metadata: metadata,
    );

    // Store the asset with a unique key (destination path)
    _assets[asset.destination] = asset;

    LogUtils.debug('Registered asset', data: {
      'source': source,
      'destination': assetDestination,
      'type': assetType.name,
    });

    return asset;
  }

  /// Find assets by type
  List<AssetReference> findAssetsByType(AssetType type) {
    return _assets.values.where((asset) => asset.type == type).toList();
  }

  /// Find assets by metadata value
  List<AssetReference> findAssetsByMetadata(String key, dynamic value) {
    return _assets.values
        .where((asset) => asset.metadata[key] == value)
        .toList();
  }

  /// Get asset by destination path
  AssetReference? getAssetByDestination(String destination) {
    return _assets[destination];
  }

  /// Process all registered assets
  /// Copies them to the output directory
  Future<void> processAssets() async {
    for (final asset in _assets.values) {
      if (!asset.processed) {
        await _processAsset(asset);
      }
    }
  }

  /// Process a single asset
  Future<void> _processAsset(AssetReference asset) async {
    try {
      // Create the full source path
      final sourcePath = _getSourcePath(asset.source);

      // Create the full destination path
      final destPath = p.join(outputDir, asset.destination);

      // Ensure the destination directory exists
      final destDir = p.dirname(destPath);
      await Directory(destDir).create(recursive: true);

      // Copy the file
      await File(sourcePath).copy(destPath);

      // Mark as processed
      asset.processed = true;

      LogUtils.debug('Processed asset', data: {
        'source': sourcePath,
        'destination': destPath,
      });
    } catch (e, stackTrace) {
      LogUtils.error(
        'Failed to process asset',
        error: e,
        stackTrace: stackTrace,
        data: {
          'source': asset.source,
          'destination': asset.destination,
        },
      );
      rethrow;
    }
  }

  /// Get the full source path for an asset
  String _getSourcePath(String source) {
    // If source is a URL or absolute path, return as-is
    if (source.startsWith('http://') ||
        source.startsWith('https://') ||
        p.isAbsolute(source)) {
      return source;
    }

    // Otherwise, resolve relative to root directory
    return p.join(rootDir, source);
  }

  /// Generate a destination path for an asset
  String _generateDestinationPath(String source, AssetType type) {
    // Extract filename from source
    final fileName = p.basename(source);

    // Generate a hash from the source to ensure uniqueness
    final hash = generateValueHash(source).substring(0, 8);

    // Create a directory based on the asset type
    final typeDir = type.name.toLowerCase();

    // Combine to form a path like "images/image_hash.png"
    return p.join(
      typeDir,
      '${p.basenameWithoutExtension(fileName)}_$hash${p.extension(fileName)}',
    );
  }

  /// Detect the asset type based on file extension
  AssetType _detectAssetType(String source) {
    final ext = p.extension(source).toLowerCase();

    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.svg':
      case '.webp':
        return AssetType.image;

      case '.mp4':
      case '.webm':
      case '.mov':
        return AssetType.video;

      case '.mp3':
      case '.wav':
      case '.ogg':
        return AssetType.audio;

      case '.ttf':
      case '.otf':
      case '.woff':
      case '.woff2':
        return AssetType.font;

      case '.dart':
      case '.js':
      case '.ts':
      case '.html':
      case '.css':
        return AssetType.code;

      case '.json':
      case '.yaml':
      case '.csv':
      case '.xml':
        return AssetType.data;

      default:
        return AssetType.other;
    }
  }

  /// Clear all registered assets
  void clear() {
    _assets.clear();
  }

  /// Get all registered assets
  List<AssetReference> getAllAssets() {
    return _assets.values.toList();
  }

  /// Get all asset references as a JSON map
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};

    for (final entry in _assets.entries) {
      result[entry.key] = entry.value.toJson();
    }

    return result;
  }
}
