// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'block_insets.dart';

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

final _blockInsetsObject = Ack.object({
  'top': _normalizedInsetValueSchema(),
  'right': _normalizedInsetValueSchema(),
  'bottom': _normalizedInsetValueSchema(),
  'left': _normalizedInsetValueSchema(),
});

final _blockInsetsSchema = _blockInsetsObject.codec<BlockInsets>(
  decode: _$BlockInsetsFromRuntime,
  encode: _$BlockInsetsToRuntime,
);

abstract final class BlockInsetsSchema {
  static AckSchema<Map<String, Object?>, BlockInsets> get schema =>
      _blockInsetsSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _blockInsetsObject;

  static BlockInsets parse(Object? value, {String? debugName}) =>
      _blockInsetsSchema.parse(value, debugName: debugName)!;

  static SchemaResult<BlockInsets> safeParse(
    Object? value, {
    String? debugName,
  }) => _blockInsetsSchema.safeParse(value, debugName: debugName);

  static BlockInsets fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(BlockInsets value, {String? debugName}) =>
      _blockInsetsSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    BlockInsets value, {
    String? debugName,
  }) => _blockInsetsSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() =>
      _blockInsetsSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_blockInsetsSchema).toSchemaModel();
}

BlockInsets _$BlockInsetsFromRuntime(Map<String, Object?> value) =>
    _$BlockInsetsFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$BlockInsetsToRuntime(BlockInsets model) =>
    <String, Object?>{..._$BlockInsetsToJson(model)};

mixin _$BlockInsetsAck {
  BlockInsets copyWith({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) {
    final self = this as BlockInsets;
    return BlockInsets(
      top: top ?? self.top,
      right: right ?? self.right,
      bottom: bottom ?? self.bottom,
      left: left ?? self.left,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BlockInsets || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as BlockInsets;
    return deepEquals(self.top, other.top) &&
        deepEquals(self.right, other.right) &&
        deepEquals(self.bottom, other.bottom) &&
        deepEquals(self.left, other.left);
  }

  @override
  int get hashCode {
    final self = this as BlockInsets;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.top),
      deepHashCode(self.right),
      deepHashCode(self.bottom),
      deepHashCode(self.left),
    ]);
  }

  @override
  String toString() {
    final self = this as BlockInsets;
    return 'BlockInsets(top: ${self.top}, right: ${self.right}, bottom: ${self.bottom}, left: ${self.left})';
  }

  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(BlockInsetsSchema.encode(this as BlockInsets));

  SchemaResult<Map<String, Object?>> safeToJson() =>
      BlockInsetsSchema.safeEncode(this as BlockInsets);
}

double? _ackBlockInsetsFromRuntimeTop(Object? value) => value as double?;
Object? _ackBlockInsetsToRuntimeTop(double value) => value;
double? _ackBlockInsetsFromRuntimeRight(Object? value) => value as double?;
Object? _ackBlockInsetsToRuntimeRight(double value) => value;
double? _ackBlockInsetsFromRuntimeBottom(Object? value) => value as double?;
Object? _ackBlockInsetsToRuntimeBottom(double value) => value;
double? _ackBlockInsetsFromRuntimeLeft(Object? value) => value as double?;
Object? _ackBlockInsetsToRuntimeLeft(double value) => value;
