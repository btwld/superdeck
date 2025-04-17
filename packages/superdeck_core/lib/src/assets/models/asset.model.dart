import 'package:ack/ack.dart';
import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';

import '../../common/hash.dart';

part 'asset.model.mapper.dart';

@MappableEnum()
enum AssetType {
  thumbnail,
  mermaid,
  image,
  custom;

  static AssetType fromString(String value) {
    return AssetType.values.firstWhereOrNull(
          (e) => e.name == value,
        ) ??
        AssetType.custom;
  }
}

@MappableEnum()
enum AssetExtension {
  png,
  jpeg,
  gif,
  webp,
  svg;

  static AssetExtension? tryParse(String value) {
    final extension = value.toLowerCase();

    return extension == 'jpg'
        ? AssetExtension.jpeg
        : AssetExtension.values.firstWhereOrNull((e) => e.name == extension);
  }
}

@MappableClass()
class Asset with AssetMappable {
  final String id;
  final AssetExtension extension;
  final AssetType type;

  Asset({
    required this.id,
    required this.extension,
    required this.type,
  });

  static final schema = Ack.object(
    {
      'id': Ack.string,
      'extension': Ack.enumValues(AssetExtension.values),
      'type': Ack.enumValues(AssetType.values),
    },
  );

  String get fileName => '${type.name}_$id.${extension.name}';

  static String buildId(String valueToHash) => generateValueHash(valueToHash);

  static Asset thumbnail(String slideKey) {
    return Asset(
      id: slideKey,
      extension: AssetExtension.png,
      type: AssetType.thumbnail,
    );
  }

  static Asset mermaid(String syntax) {
    return Asset(
      id: buildId(syntax),
      extension: AssetExtension.png,
      type: AssetType.mermaid,
    );
  }

  static Asset image(String url, AssetExtension extension) {
    return Asset(
      id: buildId(url),
      extension: extension,
      type: AssetType.image,
    );
  }
}

@MappableClass()
class AssetReference with AssetReferenceMappable {
  final DateTime lastModified;
  final String assetId;
  final AssetType type;
  final String path;

  AssetReference({
    required this.lastModified,
    required this.assetId,
    required this.type,
    required this.path,
  });
}

@MappableClass()
class AssetManifest with AssetManifestMappable {
  final DateTime lastModified;
  final List<AssetReference> assets;

  AssetManifest({
    required this.lastModified,
    required this.assets,
  });
}
