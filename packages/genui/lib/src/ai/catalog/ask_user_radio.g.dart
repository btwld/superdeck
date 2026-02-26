// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ask_user_radio.dart';

/// Extension type for InputOption
extension type InputOptionType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static InputOptionType parse(Object? data) {
    return _inputOptionSchema.parseAs(
      data,
      (validated) => InputOptionType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<InputOptionType> safeParse(Object? data) {
    return _inputOptionSchema.safeParseAs(
      data,
      (validated) => InputOptionType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get title => _data['title'] as String;

  String? get description => _data['description'] as String?;

  InputOptionType copyWith({String? title, String? description}) {
    return InputOptionType.parse({
      'title': title ?? this.title,
      'description': description ?? this.description,
    });
  }
}

/// Extension type for AskUserRadio
extension type AskUserRadioType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AskUserRadioType parse(Object? data) {
    return _askUserRadioSchema.parseAs(
      data,
      (validated) => AskUserRadioType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<AskUserRadioType> safeParse(Object? data) {
    return _askUserRadioSchema.safeParseAs(
      data,
      (validated) => AskUserRadioType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get question => _data['question'] as String;

  String? get description => _data['description'] as String?;

  List<InputOptionType> get options => (_data['options'] as List)
      .map((e) => InputOptionType(e as Map<String, Object?>))
      .toList();

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);

  AskUserRadioType copyWith({
    String? question,
    String? description,
    List<InputOptionType>? options,
    Map<String, dynamic>? action,
  }) {
    return AskUserRadioType.parse({
      'question': question ?? this.question,
      'description': description ?? this.description,
      'options': options ?? this.options,
      'action': action ?? this.action,
    });
  }
}
