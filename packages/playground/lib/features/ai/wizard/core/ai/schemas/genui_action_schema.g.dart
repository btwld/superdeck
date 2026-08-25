// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genui_action_schema.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

ActionContextValue _$ActionContextValueFromJson(Map<String, dynamic> json) =>
    ActionContextValue(
      path: ActionContextValue._ackFromRuntimePath(json['path']),
      literalString: ActionContextValue._ackFromRuntimeLiteralString(
        json['literalString'],
      ),
      literalNumber: ActionContextValue._ackFromRuntimeLiteralNumber(
        json['literalNumber'],
      ),
      literalBoolean: ActionContextValue._ackFromRuntimeLiteralBoolean(
        json['literalBoolean'],
      ),
    );

Map<String, dynamic> _$ActionContextValueToJson(ActionContextValue instance) =>
    <String, dynamic>{
      'path': ?ActionContextValue._ackToRuntimePath(instance.path),
      'literalString': ?ActionContextValue._ackToRuntimeLiteralString(
        instance.literalString,
      ),
      'literalNumber': ?ActionContextValue._ackToRuntimeLiteralNumber(
        instance.literalNumber,
      ),
      'literalBoolean': ?ActionContextValue._ackToRuntimeLiteralBoolean(
        instance.literalBoolean,
      ),
    };

ActionContextEntry _$ActionContextEntryFromJson(Map<String, dynamic> json) =>
    ActionContextEntry(
      key: ActionContextEntry._ackFromRuntimeKey(json['key']),
      value: ActionContextEntry._ackFromRuntimeValue(json['value']),
    );

Map<String, dynamic> _$ActionContextEntryToJson(ActionContextEntry instance) =>
    <String, dynamic>{
      'key': ActionContextEntry._ackToRuntimeKey(instance.key),
      'value': ActionContextEntry._ackToRuntimeValue(instance.value),
    };

GenUiAction _$GenUiActionFromJson(Map<String, dynamic> json) => GenUiAction(
  name: GenUiAction._ackFromRuntimeName(json['name']),
  context: GenUiAction._ackFromRuntimeContext(json['context']),
);

Map<String, dynamic> _$GenUiActionToJson(GenUiAction instance) =>
    <String, dynamic>{
      'name': GenUiAction._ackToRuntimeName(instance.name),
      'context': ?GenUiAction._ackToRuntimeContext(instance.context),
    };
