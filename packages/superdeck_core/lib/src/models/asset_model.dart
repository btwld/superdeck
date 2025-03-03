import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../helpers/mappers.dart';

part 'asset_model.mapper.dart';

@MappableEnum()
enum AssetExtension {
  png,
  jpeg,
  gif,
  webp,
  svg;

  static final schema = ackEnum(values);

  static AssetExtension? tryParse(String value) {
    final extension = value.toLowerCase();

    return extension == 'jpg'
        ? AssetExtension.jpeg
        : AssetExtension.values.firstWhereOrNull((e) => e.name == extension);
  }
}

@MappableClass()
class GeneratedAsset with GeneratedAssetMappable {
  final String name;
  final AssetExtension extension;
  final String type;

  GeneratedAsset({
    required this.name,
    required this.extension,
    required this.type,
  });

  String get fileName => '${type}_$name.${extension.name}';

  static String buildKey(String valueToHash) => generateValueHash(valueToHash);

  static final schema = Ack.object(
    {
      "name": Ack.string,
      "extension": AssetExtension.schema,
      "type": Ack.string,
    },
    required: [
      "name",
      "extension",
      "type",
    ],
  );

  static GeneratedAsset thumbnail(String slideKey) {
    return GeneratedAsset(
      name: slideKey,
      extension: AssetExtension.png,
      type: 'thumbnail',
    );
  }

  static GeneratedAsset mermaid(String syntax) {
    return GeneratedAsset(
      name: GeneratedAsset.buildKey(syntax),
      extension: AssetExtension.png,
      type: 'mermaid',
    );
  }

  static GeneratedAsset image(String url, AssetExtension extension) {
    return GeneratedAsset(
      name: GeneratedAsset.buildKey(url),
      extension: extension,
      type: 'image',
    );
  }
}

@MappableClass(includeCustomMappers: [
  DateTimeMapper(),
  FileMapper(),
])
class GeneratedAssetsReference with GeneratedAssetsReferenceMappable {
  final DateTime lastModified;
  final List<File> files;

  GeneratedAssetsReference({
    required this.lastModified,
    required this.files,
  });
}
