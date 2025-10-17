import 'dart:io';

import 'package:collection/collection.dart';
import 'package:superdeck_core/superdeck_core.dart';

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

  static AssetExtension fromJson(String value) {
    return AssetExtension.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid AssetExtension: $value'),
    );
  }
}

class GeneratedAsset {
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

  GeneratedAsset copyWith({
    String? name,
    AssetExtension? extension,
    String? type,
  }) {
    return GeneratedAsset(
      name: name ?? this.name,
      extension: extension ?? this.extension,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'extension': extension.name,
      'type': type,
    };
  }

  static GeneratedAsset fromMap(Map<String, dynamic> map) {
    return GeneratedAsset(
      name: map['name'] as String,
      extension: AssetExtension.fromJson(map['extension'] as String),
      type: map['type'] as String,
    );
  }

  static final schema = Ack.object(
    {
      "name": Ack.string(),
      "extension": AssetExtension.schema,
      "type": Ack.string(),
    },
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedAsset &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          extension == other.extension &&
          type == other.type;

  @override
  int get hashCode => Object.hash(name, extension, type);
}

class GeneratedAssetsReference {
  final DateTime lastModified;
  final List<File> files;

  GeneratedAssetsReference({
    required this.lastModified,
    required this.files,
  });

  GeneratedAssetsReference copyWith({
    DateTime? lastModified,
    List<File>? files,
  }) {
    return GeneratedAssetsReference(
      lastModified: lastModified ?? this.lastModified,
      files: files ?? this.files,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'last_modified': lastModified.toIso8601String(),
      'files': files.map((f) => f.path).toList(),
    };
  }

  static GeneratedAssetsReference fromMap(Map<String, dynamic> map) {
    return GeneratedAssetsReference(
      lastModified: DateTime.parse(map['last_modified'] as String),
      files: (map['files'] as List<dynamic>)
          .map((path) => File(path as String))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedAssetsReference &&
          runtimeType == other.runtimeType &&
          lastModified == other.lastModified &&
          const ListEquality().equals(
            files.map((f) => f.path).toList(),
            other.files.map((f) => f.path).toList(),
          );

  @override
  int get hashCode => Object.hash(
        lastModified,
        const ListEquality().hash(files.map((f) => f.path).toList()),
      );
}
