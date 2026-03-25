import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

/// Generates assets from content at build time (e.g., Mermaid diagrams to PNG).
///
/// Implementations handle a specific content type and produce raw asset data.
/// They do not manipulate slide content directly — the pipeline handles replacement.
abstract interface class AssetGenerator {
  String get type;

  Map<String, Object?> get configuration;

  /// Creates a [GeneratedAsset] reference for the given [content], allowing
  /// generators to define their own asset naming/hashing without the pipeline
  /// needing to know about specific asset types.
  GeneratedAsset createAssetReference(String content);

  /// Generates an asset from [content] and returns the raw bytes.
  ///
  /// The [assetPath] is the target file path where the asset will be saved.
  Future<List<int>> generateAsset(String content, String assetPath);

  /// Checks if this generator can handle the given content type.
  bool canProcess(String contentType);

  /// Disposes of any resources held by the generator.
  FutureOr<void> dispose() => Future.value();
}
