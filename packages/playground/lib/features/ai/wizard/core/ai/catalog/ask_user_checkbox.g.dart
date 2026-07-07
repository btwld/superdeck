// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ask_user_checkbox.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for AskUserCheckbox
extension type AskUserCheckboxType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AskUserCheckboxType parse(Object? data) {
    return _askUserCheckboxSchema.parseAs(
      data,
      (validated) => AskUserCheckboxType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<AskUserCheckboxType> safeParse(Object? data) {
    return _askUserCheckboxSchema.safeParseAs(
      data,
      (validated) => AskUserCheckboxType(validated as Map<String, Object?>),
    );
  }

  String get question => _data['question'] as String;

  String? get description => _data['description'] as String?;

  List<String> get items => _$ackListCast<String>(_data['items']);

  List<String>? get selectedItems => _data['selectedItems'] != null
      ? _$ackListCast<String>(_data['selectedItems'])
      : null;

  int? get minSelections => _data['minSelections'] as int?;

  int? get maxSelections => _data['maxSelections'] as int?;

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);
}
