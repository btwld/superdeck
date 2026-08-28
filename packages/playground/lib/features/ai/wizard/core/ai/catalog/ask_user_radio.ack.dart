// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ask_user_radio.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

final class _InputOptionCopyWithUnset {
  const _InputOptionCopyWithUnset();
}

/// Immutable model generated from `_inputOptionSchema`.
/// Option with title and optional description
@AckInfer.jsonSerializable
final class InputOption {
  InputOption({required this.title, this.description, this.icon});

  factory InputOption.parse(Object? input) {
    return $ack.parse(input);
  }

  factory InputOption.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  static const _InputOptionCopyWithUnset _ackCopyWithUnset =
      _InputOptionCopyWithUnset();

  /// Option title displayed to user
  final String title;

  /// Optional description text
  final String? description;

  /// Semantic icon for this option card
  final WizardOptionIcon? icon;

  static final $ack = AckModelAdapter(
    schema: () => _inputOptionSchema,
    fromRuntime: InputOption._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<InputOption> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  InputOption copyWith({
    String? title,
    Object? description = _ackCopyWithUnset,
    Object? icon = _ackCopyWithUnset,
  }) => InputOption(
    title: title ?? this.title,
    description: identical(description, _ackCopyWithUnset)
        ? this.description
        : description as String?,
    icon: identical(icon, _ackCopyWithUnset)
        ? this.icon
        : icon as WizardOptionIcon?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InputOption &&
          runtimeType == other.runtimeType &&
          deepEquals(title, other.title) &&
          deepEquals(description, other.description) &&
          deepEquals(icon, other.icon));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(title),
    deepHashCode(description),
    deepHashCode(icon),
  ]);

  @override
  String toString() =>
      'InputOption(title: $title, description: $description, icon: $icon)';

  static InputOption _fromAckRuntime(Map<String, Object?> value) =>
      _$InputOptionFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$InputOptionToJson(this),
  };

  static String _ackFromRuntimeTitle(Object? value) => value as String;

  static Object? _ackToRuntimeTitle(String value) => value;

  static String? _ackFromRuntimeDescription(Object? value) => value as String?;

  static Object? _ackToRuntimeDescription(String? value) => value;

  static WizardOptionIcon? _ackFromRuntimeIcon(Object? value) =>
      value as WizardOptionIcon?;

  static Object? _ackToRuntimeIcon(WizardOptionIcon? value) => value;
}

final class _AskUserRadioCopyWithUnset {
  const _AskUserRadioCopyWithUnset();
}

/// Immutable model generated from `_askUserRadioSchema`.
/// A question with radio button options. User selects one option.
@AckInfer.jsonSerializable
final class AskUserRadio {
  AskUserRadio({
    required this.question,
    this.description,
    required List<InputOption> options,
    required this.action,
  }) : options = List<InputOption>.unmodifiable(options.map((item) => item));

  factory AskUserRadio.parse(Object? input) {
    return $ack.parse(input);
  }

  factory AskUserRadio.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  static const _AskUserRadioCopyWithUnset _ackCopyWithUnset =
      _AskUserRadioCopyWithUnset();

  /// The question to display to the user
  final String question;

  /// Additional context or instructions
  final String? description;

  /// Radio options with title and description for single selection
  final List<InputOption> options;

  final GenUiAction action;

  static final $ack = AckModelAdapter(
    schema: () => _askUserRadioSchema,
    fromRuntime: AskUserRadio._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<AskUserRadio> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  AskUserRadio copyWith({
    String? question,
    Object? description = _ackCopyWithUnset,
    List<InputOption>? options,
    GenUiAction? action,
  }) => AskUserRadio(
    question: question ?? this.question,
    description: identical(description, _ackCopyWithUnset)
        ? this.description
        : description as String?,
    options: options ?? this.options,
    action: action ?? this.action,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AskUserRadio &&
          runtimeType == other.runtimeType &&
          deepEquals(question, other.question) &&
          deepEquals(description, other.description) &&
          deepEquals(options, other.options) &&
          deepEquals(action, other.action));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(question),
    deepHashCode(description),
    deepHashCode(options),
    deepHashCode(action),
  ]);

  @override
  String toString() =>
      'AskUserRadio(question: $question, description: $description, options: $options, action: $action)';

  static AskUserRadio _fromAckRuntime(Map<String, Object?> value) =>
      _$AskUserRadioFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$AskUserRadioToJson(this),
  };

  static String _ackFromRuntimeQuestion(Object? value) => value as String;

  static Object? _ackToRuntimeQuestion(String value) => value;

  static String? _ackFromRuntimeDescription(Object? value) => value as String?;

  static Object? _ackToRuntimeDescription(String? value) => value;

  static List<InputOption> _ackFromRuntimeOptions(Object? value) =>
      (value as List)
          .map(
            (item) =>
                InputOption.$ack.fromRuntime(item as Map<String, Object?>),
          )
          .toList();

  static Object? _ackToRuntimeOptions(List<InputOption> value) => value
      .map((item) => InputOption.$ack.toRuntime(item))
      .toList(growable: false);

  static GenUiAction _ackFromRuntimeAction(Object? value) =>
      GenUiAction.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimeAction(GenUiAction value) =>
      GenUiAction.$ack.toRuntime(value);
}
