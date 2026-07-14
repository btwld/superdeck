import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../../../core/domain/generated_image_asset.dart';

const deckImageManifestVersion = 1;
const deckImageManifestFileName = 'manifest.json';

String deckAssetsDirectoryPath(String deckPath) {
  final directory = p.dirname(deckPath);
  final stem = p.basenameWithoutExtension(deckPath);
  return p.join(directory, '$stem.assets');
}

final class DeckImageManifestEntry {
  const DeckImageManifestEntry({
    required this.assetKey,
    required this.slideKey,
    required this.subject,
    required this.prompt,
    required this.aspectRatio,
    required this.status,
    this.error,
  });

  factory DeckImageManifestEntry.fromAsset(GeneratedImageAsset asset) {
    return DeckImageManifestEntry(
      assetKey: asset.assetKey,
      slideKey: asset.slideKey,
      subject: asset.subject,
      prompt: asset.prompt,
      aspectRatio: asset.aspectRatio,
      status: asset.status,
      error: asset.error,
    );
  }

  factory DeckImageManifestEntry.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Image manifest entry must be an object.');
    }
    final map = Map<String, dynamic>.from(value);
    final statusName = _requiredString(map, 'status');
    final status = GeneratedImageStatus.values.firstWhere(
      (candidate) => candidate.name == statusName,
      orElse: () => throw FormatException(
        'Unsupported generated image status: $statusName',
      ),
    );
    return DeckImageManifestEntry(
      assetKey: _requiredString(map, 'assetKey'),
      slideKey: _requiredString(map, 'slideKey'),
      subject: _requiredString(map, 'subject'),
      prompt: _requiredString(map, 'prompt'),
      aspectRatio: GeneratedImageAspectRatio.parse(
        _requiredString(map, 'aspectRatio'),
      ),
      status: status,
      error: map['error']?.toString(),
    );
  }

  final String assetKey;
  final String slideKey;
  final String subject;
  final String prompt;
  final GeneratedImageAspectRatio aspectRatio;
  final GeneratedImageStatus status;
  final String? error;

  Map<String, Object> toJson() => {
    'assetKey': assetKey,
    'slideKey': slideKey,
    'subject': subject,
    'prompt': prompt,
    'aspectRatio': aspectRatio.apiValue,
    'status': status.name,
    'error': ?error,
  };
}

final class DeckImageManifest {
  const DeckImageManifest({
    this.version = deckImageManifestVersion,
    required this.images,
  });

  factory DeckImageManifest.fromAssets(List<GeneratedImageAsset> images) {
    return DeckImageManifest(
      images: images.map(DeckImageManifestEntry.fromAsset).toList(),
    );
  }

  factory DeckImageManifest.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Image manifest must be an object.');
    }
    final map = Map<String, dynamic>.from(decoded);
    final version = map['version'];
    if (version != deckImageManifestVersion) {
      throw FormatException('Unsupported image manifest version: $version');
    }
    final images = map['images'];
    if (images is! List) {
      throw const FormatException('Image manifest images must be a list.');
    }
    return DeckImageManifest(
      version: version as int,
      images: images.map(DeckImageManifestEntry.fromJson).toList(),
    );
  }

  final int version;
  final List<DeckImageManifestEntry> images;

  String toJsonString() => const JsonEncoder.withIndent('  ').convert({
    'version': version,
    'images': images.map((image) => image.toJson()).toList(),
  });

  DeckImageManifest replace(DeckImageManifestEntry replacement) {
    var found = false;
    final updated = images.map((image) {
      if (image.assetKey != replacement.assetKey) return image;
      found = true;
      return replacement;
    }).toList();
    if (!found) {
      throw StateError(
        'Image asset is not present in the manifest: ${replacement.assetKey}',
      );
    }
    return DeckImageManifest(version: version, images: updated);
  }
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Image manifest field "$key" must be a string.');
  }
  return value;
}
