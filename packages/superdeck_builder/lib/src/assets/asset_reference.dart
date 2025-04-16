import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';

/// Reference to an asset in the project
class AssetReference {
  /// Original path or URL to the asset
  final String source;

  /// Destination path for the asset in the build
  final String destination;

  /// Asset type
  final AssetType type;

  /// Whether the asset has been processed
  bool processed = false;

  /// Metadata associated with the asset
  final Map<String, dynamic> metadata;

  /// Create a new asset reference
  AssetReference({
    required this.source,
    required this.destination,
    required this.type,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  /// Create a copy of this asset reference with optional updates
  AssetReference copyWith({
    String? source,
    String? destination,
    AssetType? type,
    bool? processed,
    Map<String, dynamic>? metadata,
  }) {
    final result = AssetReference(
      source: source ?? this.source,
      destination: destination ?? this.destination,
      type: type ?? this.type,
      metadata: {...this.metadata, ...(metadata ?? {})},
    );

    result.processed = processed ?? this.processed;

    return result;
  }

  /// Convert to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'destination': destination,
      'type': type.name,
      'processed': processed,
      'metadata': metadata,
    };
  }

  /// Create from a JSON representation
  factory AssetReference.fromJson(Map<String, dynamic> json) {
    return AssetReference(
      source: json['source'] as String,
      destination: json['destination'] as String,
      type: _parseAssetType(json['type'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    )..processed = json['processed'] as bool? ?? false;
  }

  /// Parse asset type from string, handling both old and new enum values
  static AssetType _parseAssetType(String value) {
    // Try to match with core AssetType
    try {
      return AssetType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      // Handle legacy types from previous enum
      switch (value) {
        case 'image':
          return AssetType.image;
        case 'video':
        case 'audio':
        case 'font':
        case 'code':
        case 'data':
        case 'other':
          return AssetType.custom; // Map all other types to custom
        default:
          return AssetType.custom;
      }
    }
  }

  @override
  String toString() {
    return 'AssetReference{source: $source, destination: $destination, type: ${type.name}}';
  }

  /// Encode as a base64 string
  String toBase64() {
    final jsonString = jsonEncode(toJson());
    return base64Encode(utf8.encode(jsonString));
  }

  /// Create from a base64 string
  factory AssetReference.fromBase64(String base64String) {
    final jsonString = utf8.decode(base64Decode(base64String));
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AssetReference.fromJson(json);
  }
}
