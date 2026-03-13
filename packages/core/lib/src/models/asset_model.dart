import 'package:collection/collection.dart';
import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

import '../utils/extensions.dart';
import '../utils/generate_hash.dart';

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

  String toJson() => name;

  static AssetExtension fromJson(Object value) {
    if (value is AssetExtension) return value;
    if (value is! String) {
      throw ArgumentError('Invalid AssetExtension: $value');
    }
    return AssetExtension.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid AssetExtension: $value'),
    );
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

  static final fromMap = GeneratedAssetMapper.fromMap;

  static final schema = Ack.object({
    "name": Ack.string(),
    "extension": AssetExtension.schema,
    "type": Ack.string(),
  });

  static GeneratedAsset parse(Map<String, Object?> map) =>
      fromMap(schema.parse(map)!);

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

@MappableClass()
class GeneratedAssetsReference with GeneratedAssetsReferenceMappable {
  @MappableField(key: 'last_modified')
  final DateTime lastModified;
  final List<String> files;

  GeneratedAssetsReference({
    required this.lastModified,
    required List<String> files,
  }) : files = List.unmodifiable(files);

  static final fromMap = GeneratedAssetsReferenceMapper.fromMap;

  static final schema = Ack.object({
    'last_modified': Ack.string(),
    'files': Ack.list(Ack.string()),
  });

  static GeneratedAssetsReference parse(Map<String, Object?> map) =>
      fromMap(schema.parse(map)!);
}
