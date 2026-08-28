// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ask_user_slider.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

final class _AskUserSliderCopyWithUnset {
  const _AskUserSliderCopyWithUnset();
}

/// Immutable model generated from `_askUserSliderSchema`.
/// A question with a counter and quick choices between min and max.
@AckInfer.jsonSerializable
final class AskUserSlider {
  AskUserSlider({
    required this.question,
    this.description,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    this.unit,
    required this.action,
  });

  factory AskUserSlider.parse(Object? input) {
    return $ack.parse(input);
  }

  factory AskUserSlider.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  static const _AskUserSliderCopyWithUnset _ackCopyWithUnset =
      _AskUserSliderCopyWithUnset();

  /// The question to display to the user
  final String question;

  /// Additional context or instructions
  final String? description;

  /// Minimum value
  final int minValue;

  /// Maximum value
  final int maxValue;

  /// Default/initial value
  final int defaultValue;

  /// Unit label e.g. "slides", "minutes"
  final String? unit;

  final GenUiAction action;

  static final $ack = AckModelAdapter(
    schema: () => _askUserSliderSchema,
    fromRuntime: AskUserSlider._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<AskUserSlider> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  AskUserSlider copyWith({
    String? question,
    Object? description = _ackCopyWithUnset,
    int? minValue,
    int? maxValue,
    int? defaultValue,
    Object? unit = _ackCopyWithUnset,
    GenUiAction? action,
  }) => AskUserSlider(
    question: question ?? this.question,
    description: identical(description, _ackCopyWithUnset)
        ? this.description
        : description as String?,
    minValue: minValue ?? this.minValue,
    maxValue: maxValue ?? this.maxValue,
    defaultValue: defaultValue ?? this.defaultValue,
    unit: identical(unit, _ackCopyWithUnset) ? this.unit : unit as String?,
    action: action ?? this.action,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AskUserSlider &&
          runtimeType == other.runtimeType &&
          deepEquals(question, other.question) &&
          deepEquals(description, other.description) &&
          deepEquals(minValue, other.minValue) &&
          deepEquals(maxValue, other.maxValue) &&
          deepEquals(defaultValue, other.defaultValue) &&
          deepEquals(unit, other.unit) &&
          deepEquals(action, other.action));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(question),
    deepHashCode(description),
    deepHashCode(minValue),
    deepHashCode(maxValue),
    deepHashCode(defaultValue),
    deepHashCode(unit),
    deepHashCode(action),
  ]);

  @override
  String toString() =>
      'AskUserSlider(question: $question, description: $description, minValue: $minValue, maxValue: $maxValue, defaultValue: $defaultValue, unit: $unit, action: $action)';

  static AskUserSlider _fromAckRuntime(Map<String, Object?> value) =>
      _$AskUserSliderFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$AskUserSliderToJson(this),
  };

  static String _ackFromRuntimeQuestion(Object? value) => value as String;

  static Object? _ackToRuntimeQuestion(String value) => value;

  static String? _ackFromRuntimeDescription(Object? value) => value as String?;

  static Object? _ackToRuntimeDescription(String? value) => value;

  static int _ackFromRuntimeMinValue(Object? value) => value as int;

  static Object? _ackToRuntimeMinValue(int value) => value;

  static int _ackFromRuntimeMaxValue(Object? value) => value as int;

  static Object? _ackToRuntimeMaxValue(int value) => value;

  static int _ackFromRuntimeDefaultValue(Object? value) => value as int;

  static Object? _ackToRuntimeDefaultValue(int value) => value;

  static String? _ackFromRuntimeUnit(Object? value) => value as String?;

  static Object? _ackToRuntimeUnit(String? value) => value;

  static GenUiAction _ackFromRuntimeAction(Object? value) =>
      GenUiAction.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimeAction(GenUiAction value) =>
      GenUiAction.$ack.toRuntime(value);
}
