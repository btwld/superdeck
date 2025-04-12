import 'dart:io';
import 'dart:typed_data';

/// Represents the source/location of an asset
enum AssetSourceType {
  file, // Direct file system access
  bundle, // App asset bundle
  memory, // In-memory storage
  url, // Remote URL
}

/// Represents a source from which an asset can be loaded
///
/// This abstraction allows us to handle different storage mechanisms
/// consistently across the application.
class AssetSource {
  /// The type of source (file, bundle, memory, url)
  final AssetSourceType type;

  /// Path to the asset (for file, bundle, or URL sources)
  final String path;

  /// The raw bytes of the asset (for memory sources)
  final Uint8List? bytes;

  /// Create a file-based asset source
  AssetSource.file(this.path)
      : type = AssetSourceType.file,
        bytes = null;

  /// Create an asset bundle-based source
  AssetSource.bundle(this.path)
      : type = AssetSourceType.bundle,
        bytes = null;

  /// Create an in-memory asset source
  AssetSource.memory(this.bytes)
      : type = AssetSourceType.memory,
        path = '';

  /// Create a URL-based asset source
  AssetSource.url(this.path)
      : type = AssetSourceType.url,
        bytes = null;

  /// Whether the asset exists in the source
  ///
  /// For file sources, checks if the file exists.
  /// For memory sources, checks if bytes are non-empty.
  /// For other sources, checks if the path is non-empty.
  bool get exists {
    return switch (type) {
      AssetSourceType.file => File(path).existsSync(),
      AssetSourceType.bundle => path.isNotEmpty,
      AssetSourceType.memory => bytes != null && bytes!.isNotEmpty,
      AssetSourceType.url => path.isNotEmpty,
    };
  }

  /// A displayable path for the asset
  String get displayPath => path.isNotEmpty ? path : 'memory-asset';
}
