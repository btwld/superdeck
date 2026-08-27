// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'slide_model.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

final _slideObject = Ack.object({
  'key': Ack.string(),
  'options': SlideOptionsSchema.schema.optional().nullable(),
  'sections': Ack.list(SectionBlockSchema.schema).withDefault(const []),
  'comments': Ack.list(Ack.string()).withDefault(const []),
}, additionalProperties: true);

final _slideSchema = _slideObject.codec<Slide>(
  decode: _$SlideFromRuntime,
  encode: _$SlideToRuntime,
);

abstract final class SlideSchema {
  static AckSchema<Map<String, Object?>, Slide> get schema => _slideSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _slideObject;

  static Slide parse(Object? value, {String? debugName}) =>
      _slideSchema.parse(value, debugName: debugName)!;

  static SchemaResult<Slide> safeParse(Object? value, {String? debugName}) =>
      _slideSchema.safeParse(value, debugName: debugName);

  static Slide fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(Slide value, {String? debugName}) =>
      _slideSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    Slide value, {
    String? debugName,
  }) => _slideSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() => _slideSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_slideSchema).toSchemaModel();
}

Slide _$SlideFromRuntime(Map<String, Object?> value) =>
    _$SlideFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$SlideToRuntime(Slide model) => <String, Object?>{
  ..._$SlideToJson(model),
};

mixin _$SlideAck {
  Slide copyWith({
    String? key,
    SlideOptions? options,
    List<SectionBlock>? sections,
    List<String>? comments,
  }) {
    final self = this as Slide;
    return Slide(
      key: key ?? self.key,
      options: options ?? self.options,
      sections: sections ?? self.sections,
      comments: comments ?? self.comments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Slide || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as Slide;
    return deepEquals(self.key, other.key) &&
        deepEquals(self.options, other.options) &&
        deepEquals(self.sections, other.sections) &&
        deepEquals(self.comments, other.comments);
  }

  @override
  int get hashCode {
    final self = this as Slide;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.key),
      deepHashCode(self.options),
      deepHashCode(self.sections),
      deepHashCode(self.comments),
    ]);
  }

  @override
  String toString() {
    final self = this as Slide;
    return 'Slide(key: ${self.key}, options: ${self.options}, sections: ${self.sections}, comments: ${self.comments})';
  }

  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(SlideSchema.encode(this as Slide));

  SchemaResult<Map<String, Object?>> safeToJson() =>
      SlideSchema.safeEncode(this as Slide);
}

String _ackSlideFromRuntimeKey(Object? value) => value as String;
Object? _ackSlideToRuntimeKey(String value) => value;
SlideOptions? _ackSlideFromRuntimeOptions(Object? value) =>
    value as SlideOptions?;
Object? _ackSlideToRuntimeOptions(SlideOptions? value) => value;
List<SectionBlock>? _ackSlideFromRuntimeSections(Object? value) => value == null
    ? null
    : (value as List).map((item) => item as SectionBlock).toList();
Object? _ackSlideToRuntimeSections(List<SectionBlock> value) =>
    value.map((item) => item).toList(growable: false);
List<String>? _ackSlideFromRuntimeComments(Object? value) => value == null
    ? null
    : (value as List).map((item) => item as String).toList();
Object? _ackSlideToRuntimeComments(List<String> value) =>
    value.map((item) => item).toList(growable: false);

final _slideOptionsObject = Ack.object({
  'title': Ack.string().optional().nullable(),
  'style': Ack.string().optional().nullable(),
  'layout': Ack.enumValues(SlideLayout.values).optional().nullable(),
  'template': Ack.string().optional().nullable(),
}, additionalProperties: true);

final _slideOptionsSchema = _slideOptionsObject.codec<SlideOptions>(
  decode: _$SlideOptionsFromRuntime,
  encode: _$SlideOptionsToRuntime,
);

abstract final class SlideOptionsSchema {
  static AckSchema<Map<String, Object?>, SlideOptions> get schema =>
      _slideOptionsSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _slideOptionsObject;

  static SlideOptions parse(Object? value, {String? debugName}) =>
      _slideOptionsSchema.parse(value, debugName: debugName)!;

  static SchemaResult<SlideOptions> safeParse(
    Object? value, {
    String? debugName,
  }) => _slideOptionsSchema.safeParse(value, debugName: debugName);

  static SlideOptions fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(SlideOptions value, {String? debugName}) =>
      _slideOptionsSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    SlideOptions value, {
    String? debugName,
  }) => _slideOptionsSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() =>
      _slideOptionsSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_slideOptionsSchema).toSchemaModel();
}

SlideOptions _$SlideOptionsFromRuntime(Map<String, Object?> value) {
  const declared = <String>{'title', 'style', 'layout', 'template'};
  return _$SlideOptionsFromJson(<String, dynamic>{
    ...value,
    'args': Map<String, Object?>.fromEntries(
      value.entries.where((entry) => !declared.contains(entry.key)),
    ),
  });
}

Map<String, Object?> _$SlideOptionsToRuntime(SlideOptions model) {
  const declared = <String>{'title', 'style', 'layout', 'template'};
  final result = <String, Object?>{..._$SlideOptionsToJson(model)};
  result.remove('args');
  return <String, Object?>{
    for (final entry in model.args.entries)
      if (!declared.contains(entry.key)) entry.key: entry.value,
    ...result,
  };
}

mixin _$SlideOptionsAck {
  SlideOptions copyWith({
    String? title,
    String? style,
    SlideLayout? layout,
    String? template,
    Map<String, Object?>? args,
  }) {
    final self = this as SlideOptions;
    return SlideOptions(
      title: title ?? self.title,
      style: style ?? self.style,
      layout: layout ?? self.layout,
      template: template ?? self.template,
      args: args ?? self.args,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SlideOptions || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as SlideOptions;
    return deepEquals(self.title, other.title) &&
        deepEquals(self.style, other.style) &&
        deepEquals(self.layout, other.layout) &&
        deepEquals(self.template, other.template) &&
        deepEquals(self.args, other.args);
  }

  @override
  int get hashCode {
    final self = this as SlideOptions;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.title),
      deepHashCode(self.style),
      deepHashCode(self.layout),
      deepHashCode(self.template),
      deepHashCode(self.args),
    ]);
  }

  @override
  String toString() {
    final self = this as SlideOptions;
    return 'SlideOptions(title: ${self.title}, style: ${self.style}, layout: ${self.layout}, template: ${self.template}, args: ${self.args})';
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(
    SlideOptionsSchema.encode(this as SlideOptions),
  );

  SchemaResult<Map<String, Object?>> safeToJson() =>
      SlideOptionsSchema.safeEncode(this as SlideOptions);
}

String? _ackSlideOptionsFromRuntimeTitle(Object? value) => value as String?;
Object? _ackSlideOptionsToRuntimeTitle(String? value) => value;
String? _ackSlideOptionsFromRuntimeStyle(Object? value) => value as String?;
Object? _ackSlideOptionsToRuntimeStyle(String? value) => value;
SlideLayout? _ackSlideOptionsFromRuntimeLayout(Object? value) =>
    value as SlideLayout?;
Object? _ackSlideOptionsToRuntimeLayout(SlideLayout? value) => value;
String? _ackSlideOptionsFromRuntimeTemplate(Object? value) => value as String?;
Object? _ackSlideOptionsToRuntimeTemplate(String? value) => value;
Map<String, Object?>? _ackSlideOptionsFromRuntimeArgs(Object? value) =>
    value as Map<String, Object?>?;
Object? _ackSlideOptionsToRuntimeArgs(Map<String, Object?> value) => value;
