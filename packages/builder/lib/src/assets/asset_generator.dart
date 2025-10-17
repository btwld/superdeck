import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

/// Abstract interface for build-time asset generators.
///
/// An [AssetGenerator] is responsible for generating assets from content
/// (e.g., converting Mermaid syntax to PNG images, downloading remote images).
/// It focuses purely on asset generation and does not manipulate slide content.
abstract interface class AssetGenerator {
  /// The type of content this generator handles (e.g., 'mermaid', 'image').
  String get type;

  /// Configuration options for this generator.
  Map<String, dynamic> get configuration;

  /// Creates a [GeneratedAsset] reference for the given content.
  ///
  /// This method allows generators to create their own asset references
  /// without the pipeline needing to know about specific asset types.
  ///
  /// Returns a [GeneratedAsset] that can be used to track and locate the asset.
  GeneratedAsset createAssetReference(String content);

  /// Generates an asset from the given content.
  ///
  /// Returns the raw asset data (e.g., PNG bytes) that can be written to disk.
  /// The [content] parameter contains the raw content to process.
  /// The [assetPath] parameter is the target file path where the asset will be saved.
  Future<List<int>> generateAsset(String content, String assetPath);

  /// Checks if this generator can handle the given content type.
  bool canProcess(String contentType);

  /// Disposes of any resources held by the generator.
  FutureOr<void> dispose() => Future.value();
}
