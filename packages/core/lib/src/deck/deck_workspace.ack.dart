// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'deck_workspace.dart';

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

final _deckWorkspaceObject = Ack.object({
  'projectDir': Ack.string().optional(),
  'slidesPath': _safeWorkspacePathSchema().optional(),
  'outputDir': _safeWorkspacePathSchema().optional(),
}, additionalProperties: true);

final _deckWorkspaceSchema = _deckWorkspaceObject.codec<DeckWorkspace>(
  decode: _$DeckWorkspaceFromRuntime,
  encode: _$DeckWorkspaceToRuntime,
);

abstract final class DeckWorkspaceSchema {
  static AckSchema<Map<String, Object?>, DeckWorkspace> get schema =>
      _deckWorkspaceSchema;

  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _deckWorkspaceObject;

  static DeckWorkspace parse(Object? value, {String? debugName}) =>
      _deckWorkspaceSchema.parse(value, debugName: debugName)!;

  static SchemaResult<DeckWorkspace> safeParse(
    Object? value, {
    String? debugName,
  }) => _deckWorkspaceSchema.safeParse(value, debugName: debugName);

  static DeckWorkspace fromJson(Map<String, dynamic> json) => parse(json);

  static Map<String, Object?> encode(
    DeckWorkspace value, {
    String? debugName,
  }) => _deckWorkspaceSchema.encode(value, debugName: debugName)!;

  static SchemaResult<Map<String, Object?>> safeEncode(
    DeckWorkspace value, {
    String? debugName,
  }) => _deckWorkspaceSchema.safeEncode(value, debugName: debugName);

  static Map<String, Object?> toJsonSchema() =>
      _deckWorkspaceSchema.toJsonSchema();

  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_deckWorkspaceSchema).toSchemaModel();
}

DeckWorkspace _$DeckWorkspaceFromRuntime(Map<String, Object?> value) =>
    _$DeckWorkspaceFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$DeckWorkspaceToRuntime(DeckWorkspace model) =>
    <String, Object?>{..._$DeckWorkspaceToJson(model)};

mixin _$DeckWorkspaceAck {
  DeckWorkspace copyWith({
    String? projectDir,
    String? slidesPath,
    String? outputDir,
  }) {
    final self = this as DeckWorkspace;
    return DeckWorkspace(
      projectDir: projectDir ?? self.projectDir,
      slidesPath: slidesPath ?? self.slidesPath,
      outputDir: outputDir ?? self.outputDir,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeckWorkspace || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as DeckWorkspace;
    return deepEquals(self.projectDir, other.projectDir) &&
        deepEquals(self.slidesPath, other.slidesPath) &&
        deepEquals(self.outputDir, other.outputDir);
  }

  @override
  int get hashCode {
    final self = this as DeckWorkspace;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.projectDir),
      deepHashCode(self.slidesPath),
      deepHashCode(self.outputDir),
    ]);
  }

  @override
  String toString() {
    final self = this as DeckWorkspace;
    return 'DeckWorkspace(projectDir: ${self.projectDir}, slidesPath: ${self.slidesPath}, outputDir: ${self.outputDir})';
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(
    DeckWorkspaceSchema.encode(this as DeckWorkspace),
  );

  SchemaResult<Map<String, Object?>> safeToJson() =>
      DeckWorkspaceSchema.safeEncode(this as DeckWorkspace);
}

String? _ackDeckWorkspaceFromRuntimeProjectDir(Object? value) =>
    value as String?;
Object? _ackDeckWorkspaceToRuntimeProjectDir(String value) => value;
String? _ackDeckWorkspaceFromRuntimeSlidesPath(Object? value) =>
    value as String?;
Object? _ackDeckWorkspaceToRuntimeSlidesPath(String value) => value;
String? _ackDeckWorkspaceFromRuntimeOutputDir(Object? value) =>
    value as String?;
Object? _ackDeckWorkspaceToRuntimeOutputDir(String value) => value;
