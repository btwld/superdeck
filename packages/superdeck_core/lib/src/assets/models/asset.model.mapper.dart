// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'asset.model.dart';

class AssetTypeMapper extends EnumMapper<AssetType> {
  AssetTypeMapper._();

  static AssetTypeMapper? _instance;
  static AssetTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AssetTypeMapper._());
    }
    return _instance!;
  }

  static AssetType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AssetType decode(dynamic value) {
    switch (value) {
      case 'thumbnail':
        return AssetType.thumbnail;
      case 'mermaid':
        return AssetType.mermaid;
      case 'image':
        return AssetType.image;
      case 'custom':
        return AssetType.custom;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(AssetType self) {
    switch (self) {
      case AssetType.thumbnail:
        return 'thumbnail';
      case AssetType.mermaid:
        return 'mermaid';
      case AssetType.image:
        return 'image';
      case AssetType.custom:
        return 'custom';
    }
  }
}

extension AssetTypeMapperExtension on AssetType {
  String toValue() {
    AssetTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AssetType>(this) as String;
  }
}

class AssetExtensionMapper extends EnumMapper<AssetExtension> {
  AssetExtensionMapper._();

  static AssetExtensionMapper? _instance;
  static AssetExtensionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AssetExtensionMapper._());
    }
    return _instance!;
  }

  static AssetExtension fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AssetExtension decode(dynamic value) {
    switch (value) {
      case 'png':
        return AssetExtension.png;
      case 'jpeg':
        return AssetExtension.jpeg;
      case 'gif':
        return AssetExtension.gif;
      case 'webp':
        return AssetExtension.webp;
      case 'svg':
        return AssetExtension.svg;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(AssetExtension self) {
    switch (self) {
      case AssetExtension.png:
        return 'png';
      case AssetExtension.jpeg:
        return 'jpeg';
      case AssetExtension.gif:
        return 'gif';
      case AssetExtension.webp:
        return 'webp';
      case AssetExtension.svg:
        return 'svg';
    }
  }
}

extension AssetExtensionMapperExtension on AssetExtension {
  String toValue() {
    AssetExtensionMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AssetExtension>(this) as String;
  }
}

class AssetMapper extends ClassMapperBase<Asset> {
  AssetMapper._();

  static AssetMapper? _instance;
  static AssetMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AssetMapper._());
      AssetExtensionMapper.ensureInitialized();
      AssetTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Asset';

  static String _$id(Asset v) => v.id;
  static const Field<Asset, String> _f$id = Field('id', _$id);
  static AssetExtension _$extension(Asset v) => v.extension;
  static const Field<Asset, AssetExtension> _f$extension =
      Field('extension', _$extension);
  static AssetType _$type(Asset v) => v.type;
  static const Field<Asset, AssetType> _f$type = Field('type', _$type);

  @override
  final MappableFields<Asset> fields = const {
    #id: _f$id,
    #extension: _f$extension,
    #type: _f$type,
  };
  @override
  final bool ignoreNull = true;

  static Asset _instantiate(DecodingData data) {
    return Asset(
        id: data.dec(_f$id),
        extension: data.dec(_f$extension),
        type: data.dec(_f$type));
  }

  @override
  final Function instantiate = _instantiate;

  static Asset fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Asset>(map);
  }

  static Asset fromJson(String json) {
    return ensureInitialized().decodeJson<Asset>(json);
  }
}

mixin AssetMappable {
  String toJson() {
    return AssetMapper.ensureInitialized().encodeJson<Asset>(this as Asset);
  }

  Map<String, dynamic> toMap() {
    return AssetMapper.ensureInitialized().encodeMap<Asset>(this as Asset);
  }

  AssetCopyWith<Asset, Asset, Asset> get copyWith =>
      _AssetCopyWithImpl(this as Asset, $identity, $identity);
  @override
  String toString() {
    return AssetMapper.ensureInitialized().stringifyValue(this as Asset);
  }

  @override
  bool operator ==(Object other) {
    return AssetMapper.ensureInitialized().equalsValue(this as Asset, other);
  }

  @override
  int get hashCode {
    return AssetMapper.ensureInitialized().hashValue(this as Asset);
  }
}

extension AssetValueCopy<$R, $Out> on ObjectCopyWith<$R, Asset, $Out> {
  AssetCopyWith<$R, Asset, $Out> get $asAsset =>
      $base.as((v, t, t2) => _AssetCopyWithImpl(v, t, t2));
}

abstract class AssetCopyWith<$R, $In extends Asset, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, AssetExtension? extension, AssetType? type});
  AssetCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AssetCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Asset, $Out>
    implements AssetCopyWith<$R, Asset, $Out> {
  _AssetCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Asset> $mapper = AssetMapper.ensureInitialized();
  @override
  $R call({String? id, AssetExtension? extension, AssetType? type}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (extension != null) #extension: extension,
        if (type != null) #type: type
      }));
  @override
  Asset $make(CopyWithData data) => Asset(
      id: data.get(#id, or: $value.id),
      extension: data.get(#extension, or: $value.extension),
      type: data.get(#type, or: $value.type));

  @override
  AssetCopyWith<$R2, Asset, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _AssetCopyWithImpl($value, $cast, t);
}

class AssetReferenceMapper extends ClassMapperBase<AssetReference> {
  AssetReferenceMapper._();

  static AssetReferenceMapper? _instance;
  static AssetReferenceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AssetReferenceMapper._());
      AssetTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AssetReference';

  static DateTime _$lastModified(AssetReference v) => v.lastModified;
  static const Field<AssetReference, DateTime> _f$lastModified =
      Field('lastModified', _$lastModified, key: r'last_modified');
  static String _$assetId(AssetReference v) => v.assetId;
  static const Field<AssetReference, String> _f$assetId =
      Field('assetId', _$assetId, key: r'asset_id');
  static AssetType _$type(AssetReference v) => v.type;
  static const Field<AssetReference, AssetType> _f$type = Field('type', _$type);
  static String _$path(AssetReference v) => v.path;
  static const Field<AssetReference, String> _f$path = Field('path', _$path);

  @override
  final MappableFields<AssetReference> fields = const {
    #lastModified: _f$lastModified,
    #assetId: _f$assetId,
    #type: _f$type,
    #path: _f$path,
  };
  @override
  final bool ignoreNull = true;

  static AssetReference _instantiate(DecodingData data) {
    return AssetReference(
        lastModified: data.dec(_f$lastModified),
        assetId: data.dec(_f$assetId),
        type: data.dec(_f$type),
        path: data.dec(_f$path));
  }

  @override
  final Function instantiate = _instantiate;

  static AssetReference fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AssetReference>(map);
  }

  static AssetReference fromJson(String json) {
    return ensureInitialized().decodeJson<AssetReference>(json);
  }
}

mixin AssetReferenceMappable {
  String toJson() {
    return AssetReferenceMapper.ensureInitialized()
        .encodeJson<AssetReference>(this as AssetReference);
  }

  Map<String, dynamic> toMap() {
    return AssetReferenceMapper.ensureInitialized()
        .encodeMap<AssetReference>(this as AssetReference);
  }

  AssetReferenceCopyWith<AssetReference, AssetReference, AssetReference>
      get copyWith => _AssetReferenceCopyWithImpl(
          this as AssetReference, $identity, $identity);
  @override
  String toString() {
    return AssetReferenceMapper.ensureInitialized()
        .stringifyValue(this as AssetReference);
  }

  @override
  bool operator ==(Object other) {
    return AssetReferenceMapper.ensureInitialized()
        .equalsValue(this as AssetReference, other);
  }

  @override
  int get hashCode {
    return AssetReferenceMapper.ensureInitialized()
        .hashValue(this as AssetReference);
  }
}

extension AssetReferenceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AssetReference, $Out> {
  AssetReferenceCopyWith<$R, AssetReference, $Out> get $asAssetReference =>
      $base.as((v, t, t2) => _AssetReferenceCopyWithImpl(v, t, t2));
}

abstract class AssetReferenceCopyWith<$R, $In extends AssetReference, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {DateTime? lastModified, String? assetId, AssetType? type, String? path});
  AssetReferenceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _AssetReferenceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AssetReference, $Out>
    implements AssetReferenceCopyWith<$R, AssetReference, $Out> {
  _AssetReferenceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AssetReference> $mapper =
      AssetReferenceMapper.ensureInitialized();
  @override
  $R call(
          {DateTime? lastModified,
          String? assetId,
          AssetType? type,
          String? path}) =>
      $apply(FieldCopyWithData({
        if (lastModified != null) #lastModified: lastModified,
        if (assetId != null) #assetId: assetId,
        if (type != null) #type: type,
        if (path != null) #path: path
      }));
  @override
  AssetReference $make(CopyWithData data) => AssetReference(
      lastModified: data.get(#lastModified, or: $value.lastModified),
      assetId: data.get(#assetId, or: $value.assetId),
      type: data.get(#type, or: $value.type),
      path: data.get(#path, or: $value.path));

  @override
  AssetReferenceCopyWith<$R2, AssetReference, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _AssetReferenceCopyWithImpl($value, $cast, t);
}

class AssetManifestMapper extends ClassMapperBase<AssetManifest> {
  AssetManifestMapper._();

  static AssetManifestMapper? _instance;
  static AssetManifestMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AssetManifestMapper._());
      AssetReferenceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AssetManifest';

  static DateTime _$lastModified(AssetManifest v) => v.lastModified;
  static const Field<AssetManifest, DateTime> _f$lastModified =
      Field('lastModified', _$lastModified, key: r'last_modified');
  static List<AssetReference> _$assets(AssetManifest v) => v.assets;
  static const Field<AssetManifest, List<AssetReference>> _f$assets =
      Field('assets', _$assets);

  @override
  final MappableFields<AssetManifest> fields = const {
    #lastModified: _f$lastModified,
    #assets: _f$assets,
  };
  @override
  final bool ignoreNull = true;

  static AssetManifest _instantiate(DecodingData data) {
    return AssetManifest(
        lastModified: data.dec(_f$lastModified), assets: data.dec(_f$assets));
  }

  @override
  final Function instantiate = _instantiate;

  static AssetManifest fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AssetManifest>(map);
  }

  static AssetManifest fromJson(String json) {
    return ensureInitialized().decodeJson<AssetManifest>(json);
  }
}

mixin AssetManifestMappable {
  String toJson() {
    return AssetManifestMapper.ensureInitialized()
        .encodeJson<AssetManifest>(this as AssetManifest);
  }

  Map<String, dynamic> toMap() {
    return AssetManifestMapper.ensureInitialized()
        .encodeMap<AssetManifest>(this as AssetManifest);
  }

  AssetManifestCopyWith<AssetManifest, AssetManifest, AssetManifest>
      get copyWith => _AssetManifestCopyWithImpl(
          this as AssetManifest, $identity, $identity);
  @override
  String toString() {
    return AssetManifestMapper.ensureInitialized()
        .stringifyValue(this as AssetManifest);
  }

  @override
  bool operator ==(Object other) {
    return AssetManifestMapper.ensureInitialized()
        .equalsValue(this as AssetManifest, other);
  }

  @override
  int get hashCode {
    return AssetManifestMapper.ensureInitialized()
        .hashValue(this as AssetManifest);
  }
}

extension AssetManifestValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AssetManifest, $Out> {
  AssetManifestCopyWith<$R, AssetManifest, $Out> get $asAssetManifest =>
      $base.as((v, t, t2) => _AssetManifestCopyWithImpl(v, t, t2));
}

abstract class AssetManifestCopyWith<$R, $In extends AssetManifest, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, AssetReference,
      AssetReferenceCopyWith<$R, AssetReference, AssetReference>> get assets;
  $R call({DateTime? lastModified, List<AssetReference>? assets});
  AssetManifestCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AssetManifestCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AssetManifest, $Out>
    implements AssetManifestCopyWith<$R, AssetManifest, $Out> {
  _AssetManifestCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AssetManifest> $mapper =
      AssetManifestMapper.ensureInitialized();
  @override
  ListCopyWith<$R, AssetReference,
          AssetReferenceCopyWith<$R, AssetReference, AssetReference>>
      get assets => ListCopyWith($value.assets, (v, t) => v.copyWith.$chain(t),
          (v) => call(assets: v));
  @override
  $R call({DateTime? lastModified, List<AssetReference>? assets}) =>
      $apply(FieldCopyWithData({
        if (lastModified != null) #lastModified: lastModified,
        if (assets != null) #assets: assets
      }));
  @override
  AssetManifest $make(CopyWithData data) => AssetManifest(
      lastModified: data.get(#lastModified, or: $value.lastModified),
      assets: data.get(#assets, or: $value.assets));

  @override
  AssetManifestCopyWith<$R2, AssetManifest, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _AssetManifestCopyWithImpl($value, $cast, t);
}
