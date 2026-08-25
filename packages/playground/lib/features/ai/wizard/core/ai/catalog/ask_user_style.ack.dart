// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ask_user_style.dart';

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

/// Immutable model generated from `_askUserStyleSchema`.
/// A question with exact catalog-backed presentation theme options.
@AckType.jsonSerializable
final class AskUserStyle {
  AskUserStyle({
    required this.question,
    this.description,
    required List<String> themeIds,
    required this.action,
  }) : themeIds = List<String>.unmodifiable(themeIds.map((item) => item));

  factory AskUserStyle.parse(Object? input) {
    return $ack.parse(input);
  }

  factory AskUserStyle.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// The question to display to the user
  final String question;

  /// Additional context or instructions
  final String? description;

  /// Exactly three registered theme IDs to offer in catalog order
  final List<String> themeIds;

  final GenUiAction action;

  static final $ack = AckModelAdapter(
    schema: () => _askUserStyleSchema,
    fromRuntime: AskUserStyle._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<AskUserStyle> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  AskUserStyle copyWith({
    String? question,
    String? description,
    List<String>? themeIds,
    GenUiAction? action,
  }) => AskUserStyle(
    question: question ?? this.question,
    description: description ?? this.description,
    themeIds: themeIds ?? this.themeIds,
    action: action ?? this.action,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AskUserStyle &&
          runtimeType == other.runtimeType &&
          deepEquals(question, other.question) &&
          deepEquals(description, other.description) &&
          deepEquals(themeIds, other.themeIds) &&
          deepEquals(action, other.action));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(question),
    deepHashCode(description),
    deepHashCode(themeIds),
    deepHashCode(action),
  ]);

  @override
  String toString() =>
      'AskUserStyle(question: $question, description: $description, themeIds: $themeIds, action: $action)';

  static AskUserStyle _fromAckRuntime(Map<String, Object?> value) =>
      _$AskUserStyleFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$AskUserStyleToJson(this),
  };

  static String _ackFromRuntimeQuestion(Object? value) => value as String;

  static Object? _ackToRuntimeQuestion(String value) => value;

  static String? _ackFromRuntimeDescription(Object? value) => value as String?;

  static Object? _ackToRuntimeDescription(String? value) => value;

  static List<String> _ackFromRuntimeThemeIds(Object? value) =>
      (value as List).map((item) => item as String).toList();

  static Object? _ackToRuntimeThemeIds(List<String> value) =>
      value.map((item) => item).toList(growable: false);

  static GenUiAction _ackFromRuntimeAction(Object? value) =>
      GenUiAction.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimeAction(GenUiAction value) =>
      GenUiAction.$ack.toRuntime(value);
}
