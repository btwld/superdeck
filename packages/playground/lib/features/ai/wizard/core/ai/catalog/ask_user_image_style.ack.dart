// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ask_user_image_style.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

final class _AskUserImageStyleCopyWithUnset {
  const _AskUserImageStyleCopyWithUnset();
}

/// Immutable model generated from `_askUserImageStyleSchema`.
/// An application-owned generated image-style selection step.
@AckInfer.jsonSerializable
final class AskUserImageStyle {
  AskUserImageStyle({
    required this.question,
    this.description,
    required this.action,
  });

  factory AskUserImageStyle.parse(Object? input) {
    return $ack.parse(input);
  }

  factory AskUserImageStyle.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  static const _AskUserImageStyleCopyWithUnset _ackCopyWithUnset =
      _AskUserImageStyleCopyWithUnset();

  /// The question to display to the user
  final String question;

  /// Additional context or instructions
  final String? description;

  final GenUiAction action;

  static final $ack = AckModelAdapter(
    schema: () => _askUserImageStyleSchema,
    fromRuntime: AskUserImageStyle._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<AskUserImageStyle> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  AskUserImageStyle copyWith({
    String? question,
    Object? description = _ackCopyWithUnset,
    GenUiAction? action,
  }) => AskUserImageStyle(
    question: question ?? this.question,
    description: identical(description, _ackCopyWithUnset)
        ? this.description
        : description as String?,
    action: action ?? this.action,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AskUserImageStyle &&
          runtimeType == other.runtimeType &&
          deepEquals(question, other.question) &&
          deepEquals(description, other.description) &&
          deepEquals(action, other.action));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(question),
    deepHashCode(description),
    deepHashCode(action),
  ]);

  @override
  String toString() =>
      'AskUserImageStyle(question: $question, description: $description, action: $action)';

  static AskUserImageStyle _fromAckRuntime(Map<String, Object?> value) =>
      _$AskUserImageStyleFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$AskUserImageStyleToJson(this),
  };

  static String _ackFromRuntimeQuestion(Object? value) => value as String;

  static Object? _ackToRuntimeQuestion(String value) => value;

  static String? _ackFromRuntimeDescription(Object? value) => value as String?;

  static Object? _ackToRuntimeDescription(String? value) => value;

  static GenUiAction _ackFromRuntimeAction(Object? value) =>
      GenUiAction.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimeAction(GenUiAction value) =>
      GenUiAction.$ack.toRuntime(value);
}
