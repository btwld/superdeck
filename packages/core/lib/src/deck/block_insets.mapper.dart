// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'block_insets.dart';

class BlockInsetsMapper extends ClassMapperBase<BlockInsets> {
  BlockInsetsMapper._();

  static BlockInsetsMapper? _instance;
  static BlockInsetsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BlockInsetsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'BlockInsets';

  static double _$top(BlockInsets v) => v.top;
  static const Field<BlockInsets, double> _f$top = Field(
    'top',
    _$top,
    opt: true,
    def: 0,
  );
  static double _$right(BlockInsets v) => v.right;
  static const Field<BlockInsets, double> _f$right = Field(
    'right',
    _$right,
    opt: true,
    def: 0,
  );
  static double _$bottom(BlockInsets v) => v.bottom;
  static const Field<BlockInsets, double> _f$bottom = Field(
    'bottom',
    _$bottom,
    opt: true,
    def: 0,
  );
  static double _$left(BlockInsets v) => v.left;
  static const Field<BlockInsets, double> _f$left = Field(
    'left',
    _$left,
    opt: true,
    def: 0,
  );

  @override
  final MappableFields<BlockInsets> fields = const {
    #top: _f$top,
    #right: _f$right,
    #bottom: _f$bottom,
    #left: _f$left,
  };

  static BlockInsets _instantiate(DecodingData data) {
    return BlockInsets(
      top: data.dec(_f$top),
      right: data.dec(_f$right),
      bottom: data.dec(_f$bottom),
      left: data.dec(_f$left),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static BlockInsets fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BlockInsets>(map);
  }

  static BlockInsets fromJson(String json) {
    return ensureInitialized().decodeJson<BlockInsets>(json);
  }
}

mixin BlockInsetsMappable {
  String toJson() {
    return BlockInsetsMapper.ensureInitialized().encodeJson<BlockInsets>(
      this as BlockInsets,
    );
  }

  Map<String, dynamic> toMap() {
    return BlockInsetsMapper.ensureInitialized().encodeMap<BlockInsets>(
      this as BlockInsets,
    );
  }

  BlockInsetsCopyWith<BlockInsets, BlockInsets, BlockInsets> get copyWith =>
      _BlockInsetsCopyWithImpl<BlockInsets, BlockInsets>(
        this as BlockInsets,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return BlockInsetsMapper.ensureInitialized().stringifyValue(
      this as BlockInsets,
    );
  }

  @override
  bool operator ==(Object other) {
    return BlockInsetsMapper.ensureInitialized().equalsValue(
      this as BlockInsets,
      other,
    );
  }

  @override
  int get hashCode {
    return BlockInsetsMapper.ensureInitialized().hashValue(this as BlockInsets);
  }
}

extension BlockInsetsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, BlockInsets, $Out> {
  BlockInsetsCopyWith<$R, BlockInsets, $Out> get $asBlockInsets =>
      $base.as((v, t, t2) => _BlockInsetsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class BlockInsetsCopyWith<$R, $In extends BlockInsets, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({double? top, double? right, double? bottom, double? left});
  BlockInsetsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _BlockInsetsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BlockInsets, $Out>
    implements BlockInsetsCopyWith<$R, BlockInsets, $Out> {
  _BlockInsetsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BlockInsets> $mapper =
      BlockInsetsMapper.ensureInitialized();
  @override
  $R call({double? top, double? right, double? bottom, double? left}) => $apply(
    FieldCopyWithData({
      if (top != null) #top: top,
      if (right != null) #right: right,
      if (bottom != null) #bottom: bottom,
      if (left != null) #left: left,
    }),
  );
  @override
  BlockInsets $make(CopyWithData data) => BlockInsets(
    top: data.get(#top, or: $value.top),
    right: data.get(#right, or: $value.right),
    bottom: data.get(#bottom, or: $value.bottom),
    left: data.get(#left, or: $value.left),
  );

  @override
  BlockInsetsCopyWith<$R2, BlockInsets, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _BlockInsetsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
