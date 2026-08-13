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

  String get title => _data['title'] as String;

  String? get description => _data['description'] as String?;

  WizardOptionIcon? get icon => _data['icon'] as WizardOptionIcon?;
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

  String get question => _data['question'] as String;

  String? get description => _data['description'] as String?;

  List<InputOptionType> get options => (_data['options'] as List)
      .map((e) => InputOptionType(e as Map<String, Object?>))
      .toList();

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);
}
