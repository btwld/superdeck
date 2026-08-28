// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'block_model.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

final _contentBlockObject = Ack.object({
  'type': Ack.literal('block').optional(),
  'align': Ack.enumValues(ContentAlignment.values).optional().nullable(),
  'flex': positiveFlexSchema().withDefault(1),
  'margin': BlockInsetsSchema.schema.optional().nullable(),
  'padding': BlockInsetsSchema.schema.optional().nullable(),
  'scrollable': Ack.boolean().withDefault(false),
  'content': Ack.string().optional(),
}, additionalProperties: true);

final _contentBlockWireSchema = Ack.preserveBoundary(_contentBlockObject);

final _contentBlockSchema = _contentBlockObject.codec<ContentBlock>(
  decode: _$ContentBlockFromRuntime,
  encode: _$ContentBlockToRuntime,
);

abstract final class ContentBlockSchema {
  static AckSchema<Map<String, Object?>, ContentBlock> get schema =>
      _contentBlockSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _contentBlockWireSchema;

  static ContentBlock parse(Object? value, {String? debugName}) =>
      _contentBlockSchema.parse(value, debugName: debugName)!;

  static SchemaResult<ContentBlock> safeParse(
    Object? value, {
    String? debugName,
  }) => _contentBlockSchema.safeParse(value, debugName: debugName);

  static ContentBlock fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(ContentBlock value, {String? debugName}) =>
      _contentBlockSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    ContentBlock value, {
    String? debugName,
  }) => _contentBlockSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() =>
      _contentBlockSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_contentBlockSchema).toSchemaModel();
}

ContentBlock _$ContentBlockFromRuntime(Map<String, Object?> value) =>
    _$ContentBlockFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$ContentBlockToRuntime(ContentBlock model) {
  final result = <String, Object?>{..._$ContentBlockToJson(model)};
  return <String, Object?>{...result, 'type': 'block'};
}

final class _ContentBlockCopyWithUnset {
  const _ContentBlockCopyWithUnset();
}

mixin _$ContentBlockAck {
  static const _ContentBlockCopyWithUnset _ackCopyWithUnset =
      _ContentBlockCopyWithUnset();

  ContentBlock copyWith({
    Object? content = _ackCopyWithUnset,
    Object? align = _ackCopyWithUnset,
    int? flex,
    Object? margin = _ackCopyWithUnset,
    Object? padding = _ackCopyWithUnset,
    bool? scrollable,
  }) {
    final self = this as ContentBlock;
    return ContentBlock(
      identical(content, _ackCopyWithUnset) ? self.content : content as String?,
      align: identical(align, _ackCopyWithUnset)
          ? self.align
          : align as ContentAlignment?,
      flex: flex ?? self.flex,
      margin: identical(margin, _ackCopyWithUnset)
          ? self.margin
          : margin as BlockInsets?,
      padding: identical(padding, _ackCopyWithUnset)
          ? self.padding
          : padding as BlockInsets?,
      scrollable: scrollable ?? self.scrollable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ContentBlock || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as ContentBlock;
    return deepEquals(self.align, other.align) &&
        deepEquals(self.flex, other.flex) &&
        deepEquals(self.margin, other.margin) &&
        deepEquals(self.padding, other.padding) &&
        deepEquals(self.scrollable, other.scrollable) &&
        deepEquals(self.content, other.content);
  }

  @override
  int get hashCode {
    final self = this as ContentBlock;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.align),
      deepHashCode(self.flex),
      deepHashCode(self.margin),
      deepHashCode(self.padding),
      deepHashCode(self.scrollable),
      deepHashCode(self.content),
    ]);
  }

  @override
  String toString() {
    final self = this as ContentBlock;
    return 'ContentBlock(align: ${self.align}, flex: ${self.flex}, margin: ${self.margin}, padding: ${self.padding}, scrollable: ${self.scrollable}, content: ${self.content})';
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(
    ContentBlockSchema.encode(this as ContentBlock),
  );

  SchemaResult<Map<String, Object?>> safeToJson() =>
      ContentBlockSchema.safeEncode(this as ContentBlock);
}

ContentAlignment? _ackContentBlockFromRuntimeAlign(Object? value) =>
    value as ContentAlignment?;
Object? _ackContentBlockToRuntimeAlign(ContentAlignment? value) => value;
int? _ackContentBlockFromRuntimeFlex(Object? value) => value as int?;
Object? _ackContentBlockToRuntimeFlex(int value) => value;
BlockInsets? _ackContentBlockFromRuntimeMargin(Object? value) =>
    value as BlockInsets?;
Object? _ackContentBlockToRuntimeMargin(BlockInsets? value) => value;
BlockInsets? _ackContentBlockFromRuntimePadding(Object? value) =>
    value as BlockInsets?;
Object? _ackContentBlockToRuntimePadding(BlockInsets? value) => value;
bool? _ackContentBlockFromRuntimeScrollable(Object? value) => value as bool?;
Object? _ackContentBlockToRuntimeScrollable(bool value) => value;
String? _ackContentBlockFromRuntimeContent(Object? value) => value as String?;
Object? _ackContentBlockToRuntimeContent(String value) => value;

final _widgetBlockObject = Ack.object({
  'type': Ack.literal('widget').optional(),
  'align': Ack.enumValues(ContentAlignment.values).optional().nullable(),
  'flex': positiveFlexSchema().withDefault(1),
  'margin': BlockInsetsSchema.schema.optional().nullable(),
  'padding': BlockInsetsSchema.schema.optional().nullable(),
  'scrollable': Ack.boolean().withDefault(false),
  'name': Ack.string(),
}, additionalProperties: true);

final _widgetBlockWireSchema = Ack.preserveBoundary(_widgetBlockObject);

final _widgetBlockSchema = _widgetBlockObject.codec<WidgetBlock>(
  decode: _$WidgetBlockFromRuntime,
  encode: _$WidgetBlockToRuntime,
);

abstract final class WidgetBlockSchema {
  static AckSchema<Map<String, Object?>, WidgetBlock> get schema =>
      _widgetBlockSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _widgetBlockWireSchema;

  static WidgetBlock parse(Object? value, {String? debugName}) =>
      _widgetBlockSchema.parse(value, debugName: debugName)!;

  static SchemaResult<WidgetBlock> safeParse(
    Object? value, {
    String? debugName,
  }) => _widgetBlockSchema.safeParse(value, debugName: debugName);

  static WidgetBlock fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(WidgetBlock value, {String? debugName}) =>
      _widgetBlockSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    WidgetBlock value, {
    String? debugName,
  }) => _widgetBlockSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() =>
      _widgetBlockSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_widgetBlockSchema).toSchemaModel();
}

WidgetBlock _$WidgetBlockFromRuntime(Map<String, Object?> value) {
  const declared = <String>{
    'align',
    'flex',
    'margin',
    'padding',
    'scrollable',
    'name',
    'type',
  };
  return _$WidgetBlockFromJson(<String, dynamic>{
    ...value,
    'args': Map<String, Object?>.fromEntries(
      value.entries.where((entry) => !declared.contains(entry.key)),
    ),
  });
}

Map<String, Object?> _$WidgetBlockToRuntime(WidgetBlock model) {
  const declared = <String>{
    'align',
    'flex',
    'margin',
    'padding',
    'scrollable',
    'name',
    'type',
  };
  final result = <String, Object?>{..._$WidgetBlockToJson(model)};
  result.remove('args');
  return <String, Object?>{
    for (final entry in model.args.entries)
      if (!declared.contains(entry.key)) entry.key: entry.value,
    ...result,
    'type': 'widget',
  };
}

final class _WidgetBlockCopyWithUnset {
  const _WidgetBlockCopyWithUnset();
}

mixin _$WidgetBlockAck {
  static const _WidgetBlockCopyWithUnset _ackCopyWithUnset =
      _WidgetBlockCopyWithUnset();

  WidgetBlock copyWith({
    String? name,
    Map<String, Object?>? args,
    Object? align = _ackCopyWithUnset,
    int? flex,
    Object? margin = _ackCopyWithUnset,
    Object? padding = _ackCopyWithUnset,
    bool? scrollable,
  }) {
    final self = this as WidgetBlock;
    return WidgetBlock(
      name: name ?? self.name,
      args: args ?? self.args,
      align: identical(align, _ackCopyWithUnset)
          ? self.align
          : align as ContentAlignment?,
      flex: flex ?? self.flex,
      margin: identical(margin, _ackCopyWithUnset)
          ? self.margin
          : margin as BlockInsets?,
      padding: identical(padding, _ackCopyWithUnset)
          ? self.padding
          : padding as BlockInsets?,
      scrollable: scrollable ?? self.scrollable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WidgetBlock || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as WidgetBlock;
    return deepEquals(self.align, other.align) &&
        deepEquals(self.flex, other.flex) &&
        deepEquals(self.margin, other.margin) &&
        deepEquals(self.padding, other.padding) &&
        deepEquals(self.scrollable, other.scrollable) &&
        deepEquals(self.name, other.name) &&
        deepEquals(self.args, other.args);
  }

  @override
  int get hashCode {
    final self = this as WidgetBlock;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.align),
      deepHashCode(self.flex),
      deepHashCode(self.margin),
      deepHashCode(self.padding),
      deepHashCode(self.scrollable),
      deepHashCode(self.name),
      deepHashCode(self.args),
    ]);
  }

  @override
  String toString() {
    final self = this as WidgetBlock;
    return 'WidgetBlock(align: ${self.align}, flex: ${self.flex}, margin: ${self.margin}, padding: ${self.padding}, scrollable: ${self.scrollable}, name: ${self.name}, args: ${self.args})';
  }

  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(WidgetBlockSchema.encode(this as WidgetBlock));

  SchemaResult<Map<String, Object?>> safeToJson() =>
      WidgetBlockSchema.safeEncode(this as WidgetBlock);
}

ContentAlignment? _ackWidgetBlockFromRuntimeAlign(Object? value) =>
    value as ContentAlignment?;
Object? _ackWidgetBlockToRuntimeAlign(ContentAlignment? value) => value;
int? _ackWidgetBlockFromRuntimeFlex(Object? value) => value as int?;
Object? _ackWidgetBlockToRuntimeFlex(int value) => value;
BlockInsets? _ackWidgetBlockFromRuntimeMargin(Object? value) =>
    value as BlockInsets?;
Object? _ackWidgetBlockToRuntimeMargin(BlockInsets? value) => value;
BlockInsets? _ackWidgetBlockFromRuntimePadding(Object? value) =>
    value as BlockInsets?;
Object? _ackWidgetBlockToRuntimePadding(BlockInsets? value) => value;
bool? _ackWidgetBlockFromRuntimeScrollable(Object? value) => value as bool?;
Object? _ackWidgetBlockToRuntimeScrollable(bool value) => value;
String _ackWidgetBlockFromRuntimeName(Object? value) => value as String;
Object? _ackWidgetBlockToRuntimeName(String value) => value;
Map<String, Object?>? _ackWidgetBlockFromRuntimeArgs(Object? value) =>
    value == null
    ? null
    : _ackClassImmutableCopyMap(value as Map<String, Object?>);
Object? _ackWidgetBlockToRuntimeArgs(Map<String, Object?> value) => value;

final _blockObject = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {'block': _contentBlockObject, 'widget': _widgetBlockObject},
);

final _blockWireSchema = Ack.preserveBoundary(_blockObject);

final _blockSchema = _blockObject.codec<Block>(
  decode: (value) => switch (value['type']) {
    'block' => _$ContentBlockFromRuntime(value),
    'widget' => _$WidgetBlockFromRuntime(value),
    final unknown => throw StateError('Unknown type: $unknown'),
  },
  encode: (model) => switch (model) {
    ContentBlock() => _$ContentBlockToRuntime(model),
    WidgetBlock() => _$WidgetBlockToRuntime(model),
  },
);

abstract final class BlockSchema {
  static AckSchema<Map<String, Object?>, Block> get schema => _blockSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _blockWireSchema;

  static Block parse(Object? value, {String? debugName}) =>
      _blockSchema.parse(value, debugName: debugName)!;

  static SchemaResult<Block> safeParse(Object? value, {String? debugName}) =>
      _blockSchema.safeParse(value, debugName: debugName);

  static Block fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(Block value, {String? debugName}) =>
      _blockSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    Block value, {
    String? debugName,
  }) => _blockSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() => _blockSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_blockSchema).toSchemaModel();
}

mixin _$BlockAck {
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(BlockSchema.encode(this as Block));

  SchemaResult<Map<String, Object?>> safeToJson() =>
      BlockSchema.safeEncode(this as Block);
}

final _sectionBlockObject = Ack.object({
  'blocks': Ack.list(BlockSchema.schema).optional(),
  'align': Ack.enumValues(ContentAlignment.values).optional().nullable(),
  'flex': positiveFlexSchema().withDefault(1),
  'spacing': nonNegativeSpacingSchema().withDefault(0),
  'type': _sectionTypeSchema().withDefault('section'),
});

final _sectionBlockWireSchema = Ack.preserveBoundary(_sectionBlockObject);

final _sectionBlockSchema = _sectionBlockObject.codec<SectionBlock>(
  decode: _$SectionBlockFromRuntime,
  encode: _$SectionBlockToRuntime,
);

abstract final class SectionBlockSchema {
  static AckSchema<Map<String, Object?>, SectionBlock> get schema =>
      _sectionBlockSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _sectionBlockWireSchema;

  static SectionBlock parse(Object? value, {String? debugName}) =>
      _sectionBlockSchema.parse(value, debugName: debugName)!;

  static SchemaResult<SectionBlock> safeParse(
    Object? value, {
    String? debugName,
  }) => _sectionBlockSchema.safeParse(value, debugName: debugName);

  static SectionBlock fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(SectionBlock value, {String? debugName}) =>
      _sectionBlockSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    SectionBlock value, {
    String? debugName,
  }) => _sectionBlockSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() =>
      _sectionBlockSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_sectionBlockSchema).toSchemaModel();
}

SectionBlock _$SectionBlockFromRuntime(Map<String, Object?> value) =>
    _$SectionBlockFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$SectionBlockToRuntime(SectionBlock model) =>
    <String, Object?>{..._$SectionBlockToJson(model)};

final class _SectionBlockCopyWithUnset {
  const _SectionBlockCopyWithUnset();
}

mixin _$SectionBlockAck {
  static const _SectionBlockCopyWithUnset _ackCopyWithUnset =
      _SectionBlockCopyWithUnset();

  SectionBlock copyWith({
    Object? blocks = _ackCopyWithUnset,
    Object? align = _ackCopyWithUnset,
    int? flex,
    double? spacing,
    String? type,
  }) {
    final self = this as SectionBlock;
    return SectionBlock(
      identical(blocks, _ackCopyWithUnset)
          ? self.blocks
          : blocks as List<Block>?,
      align: identical(align, _ackCopyWithUnset)
          ? self.align
          : align as ContentAlignment?,
      flex: flex ?? self.flex,
      spacing: spacing ?? self.spacing,
      type: type ?? self.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SectionBlock || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as SectionBlock;
    return deepEquals(self.blocks, other.blocks) &&
        deepEquals(self.align, other.align) &&
        deepEquals(self.flex, other.flex) &&
        deepEquals(self.spacing, other.spacing) &&
        deepEquals(self.type, other.type);
  }

  @override
  int get hashCode {
    final self = this as SectionBlock;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.blocks),
      deepHashCode(self.align),
      deepHashCode(self.flex),
      deepHashCode(self.spacing),
      deepHashCode(self.type),
    ]);
  }

  @override
  String toString() {
    final self = this as SectionBlock;
    return 'SectionBlock(blocks: ${self.blocks}, align: ${self.align}, flex: ${self.flex}, spacing: ${self.spacing}, type: ${self.type})';
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(
    SectionBlockSchema.encode(this as SectionBlock),
  );

  SchemaResult<Map<String, Object?>> safeToJson() =>
      SectionBlockSchema.safeEncode(this as SectionBlock);
}

List<Block>? _ackSectionBlockFromRuntimeBlocks(Object? value) => value == null
    ? null
    : List<Block>.unmodifiable((value as List).map((item) => item as Block));
Object? _ackSectionBlockToRuntimeBlocks(List<Block> value) =>
    value.map((item) => item).toList(growable: false);
ContentAlignment? _ackSectionBlockFromRuntimeAlign(Object? value) =>
    value as ContentAlignment?;
Object? _ackSectionBlockToRuntimeAlign(ContentAlignment? value) => value;
int? _ackSectionBlockFromRuntimeFlex(Object? value) => value as int?;
Object? _ackSectionBlockToRuntimeFlex(int value) => value;
double? _ackSectionBlockFromRuntimeSpacing(Object? value) => value as double?;
Object? _ackSectionBlockToRuntimeSpacing(double value) => value;
String? _ackSectionBlockFromRuntimeType(Object? value) => value as String?;
Object? _ackSectionBlockToRuntimeType(String value) => value;

Object? _ackClassImmutableCopyValue(Object? value) => switch (value) {
  List() => List.unmodifiable(value.map(_ackClassImmutableCopyValue)),
  Set() => Set.unmodifiable(value.map(_ackClassImmutableCopyValue)),
  Map() => Map.unmodifiable(
    value.map((key, item) => MapEntry(key, _ackClassImmutableCopyValue(item))),
  ),
  _ => value,
};

Map<String, Object?> _ackClassImmutableCopyMap(Map<String, Object?> value) =>
    Map<String, Object?>.unmodifiable(
      value.map(
        (key, item) => MapEntry(key, _ackClassImmutableCopyValue(item)),
      ),
    );
