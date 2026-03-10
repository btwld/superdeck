// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'asset_model.dart';

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
      case r'png':
        return AssetExtension.png;
      case r'jpeg':
        return AssetExtension.jpeg;
      case r'gif':
        return AssetExtension.gif;
      case r'webp':
        return AssetExtension.webp;
      case r'svg':
        return AssetExtension.svg;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(AssetExtension self) {
    switch (self) {
      case AssetExtension.png:
        return r'png';
      case AssetExtension.jpeg:
        return r'jpeg';
      case AssetExtension.gif:
        return r'gif';
      case AssetExtension.webp:
        return r'webp';
      case AssetExtension.svg:
        return r'svg';
    }
  }
}

extension AssetExtensionMapperExtension on AssetExtension {
  String toValue() {
    AssetExtensionMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AssetExtension>(this) as String;
  }
}

class GeneratedAssetMapper extends ClassMapperBase<GeneratedAsset> {
  GeneratedAssetMapper._();

  static GeneratedAssetMapper? _instance;
  static GeneratedAssetMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GeneratedAssetMapper._());
      AssetExtensionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GeneratedAsset';

  static String _$name(GeneratedAsset v) => v.name;
  static const Field<GeneratedAsset, String> _f$name = Field('name', _$name);
  static AssetExtension _$extension(GeneratedAsset v) => v.extension;
  static const Field<GeneratedAsset, AssetExtension> _f$extension = Field(
    'extension',
    _$extension,
  );
  static String _$type(GeneratedAsset v) => v.type;
  static const Field<GeneratedAsset, String> _f$type = Field('type', _$type);

  @override
  final MappableFields<GeneratedAsset> fields = const {
    #name: _f$name,
    #extension: _f$extension,
    #type: _f$type,
  };

  static GeneratedAsset _instantiate(DecodingData data) {
    return GeneratedAsset(
      name: data.dec(_f$name),
      extension: data.dec(_f$extension),
      type: data.dec(_f$type),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GeneratedAsset fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GeneratedAsset>(map);
  }

  static GeneratedAsset fromJson(String json) {
    return ensureInitialized().decodeJson<GeneratedAsset>(json);
  }
}

mixin GeneratedAssetMappable {
  GeneratedAssetCopyWith<GeneratedAsset, GeneratedAsset, GeneratedAsset>
  get copyWith => _GeneratedAssetCopyWithImpl<GeneratedAsset, GeneratedAsset>(
    this as GeneratedAsset,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return GeneratedAssetMapper.ensureInitialized().stringifyValue(
      this as GeneratedAsset,
    );
  }

  @override
  bool operator ==(Object other) {
    return GeneratedAssetMapper.ensureInitialized().equalsValue(
      this as GeneratedAsset,
      other,
    );
  }

  @override
  int get hashCode {
    return GeneratedAssetMapper.ensureInitialized().hashValue(
      this as GeneratedAsset,
    );
  }
}

extension GeneratedAssetValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GeneratedAsset, $Out> {
  GeneratedAssetCopyWith<$R, GeneratedAsset, $Out> get $asGeneratedAsset =>
      $base.as((v, t, t2) => _GeneratedAssetCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GeneratedAssetCopyWith<$R, $In extends GeneratedAsset, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, AssetExtension? extension, String? type});
  GeneratedAssetCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GeneratedAssetCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GeneratedAsset, $Out>
    implements GeneratedAssetCopyWith<$R, GeneratedAsset, $Out> {
  _GeneratedAssetCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GeneratedAsset> $mapper =
      GeneratedAssetMapper.ensureInitialized();
  @override
  $R call({String? name, AssetExtension? extension, String? type}) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (extension != null) #extension: extension,
      if (type != null) #type: type,
    }),
  );
  @override
  GeneratedAsset $make(CopyWithData data) => GeneratedAsset(
    name: data.get(#name, or: $value.name),
    extension: data.get(#extension, or: $value.extension),
    type: data.get(#type, or: $value.type),
  );

  @override
  GeneratedAssetCopyWith<$R2, GeneratedAsset, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _GeneratedAssetCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GeneratedAssetsReferenceMapper
    extends ClassMapperBase<GeneratedAssetsReference> {
  GeneratedAssetsReferenceMapper._();

  static GeneratedAssetsReferenceMapper? _instance;
  static GeneratedAssetsReferenceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = GeneratedAssetsReferenceMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'GeneratedAssetsReference';

  static DateTime _$lastModified(GeneratedAssetsReference v) => v.lastModified;
  static const Field<GeneratedAssetsReference, DateTime> _f$lastModified =
      Field('lastModified', _$lastModified, key: r'last_modified');
  static List<String> _$files(GeneratedAssetsReference v) => v.files;
  static const Field<GeneratedAssetsReference, List<String>> _f$files = Field(
    'files',
    _$files,
  );

  @override
  final MappableFields<GeneratedAssetsReference> fields = const {
    #lastModified: _f$lastModified,
    #files: _f$files,
  };

  static GeneratedAssetsReference _instantiate(DecodingData data) {
    return GeneratedAssetsReference(
      lastModified: data.dec(_f$lastModified),
      files: data.dec(_f$files),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GeneratedAssetsReference fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GeneratedAssetsReference>(map);
  }

  static GeneratedAssetsReference fromJson(String json) {
    return ensureInitialized().decodeJson<GeneratedAssetsReference>(json);
  }
}

mixin GeneratedAssetsReferenceMappable {
  GeneratedAssetsReferenceCopyWith<
    GeneratedAssetsReference,
    GeneratedAssetsReference,
    GeneratedAssetsReference
  >
  get copyWith =>
      _GeneratedAssetsReferenceCopyWithImpl<
        GeneratedAssetsReference,
        GeneratedAssetsReference
      >(this as GeneratedAssetsReference, $identity, $identity);
  @override
  String toString() {
    return GeneratedAssetsReferenceMapper.ensureInitialized().stringifyValue(
      this as GeneratedAssetsReference,
    );
  }

  @override
  bool operator ==(Object other) {
    return GeneratedAssetsReferenceMapper.ensureInitialized().equalsValue(
      this as GeneratedAssetsReference,
      other,
    );
  }

  @override
  int get hashCode {
    return GeneratedAssetsReferenceMapper.ensureInitialized().hashValue(
      this as GeneratedAssetsReference,
    );
  }
}

extension GeneratedAssetsReferenceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GeneratedAssetsReference, $Out> {
  GeneratedAssetsReferenceCopyWith<$R, GeneratedAssetsReference, $Out>
  get $asGeneratedAssetsReference => $base.as(
    (v, t, t2) => _GeneratedAssetsReferenceCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class GeneratedAssetsReferenceCopyWith<
  $R,
  $In extends GeneratedAssetsReference,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get files;
  $R call({DateTime? lastModified, List<String>? files});
  GeneratedAssetsReferenceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GeneratedAssetsReferenceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GeneratedAssetsReference, $Out>
    implements
        GeneratedAssetsReferenceCopyWith<$R, GeneratedAssetsReference, $Out> {
  _GeneratedAssetsReferenceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GeneratedAssetsReference> $mapper =
      GeneratedAssetsReferenceMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get files =>
      ListCopyWith(
        $value.files,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(files: v),
      );
  @override
  $R call({DateTime? lastModified, List<String>? files}) => $apply(
    FieldCopyWithData({
      if (lastModified != null) #lastModified: lastModified,
      if (files != null) #files: files,
    }),
  );
  @override
  GeneratedAssetsReference $make(CopyWithData data) => GeneratedAssetsReference(
    lastModified: data.get(#lastModified, or: $value.lastModified),
    files: data.get(#files, or: $value.files),
  );

  @override
  GeneratedAssetsReferenceCopyWith<$R2, GeneratedAssetsReference, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _GeneratedAssetsReferenceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

